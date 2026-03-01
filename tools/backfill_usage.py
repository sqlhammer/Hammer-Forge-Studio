#!/usr/bin/env python3
"""backfill_usage.py — Backfill usage records from existing orchestrator logs.

Usage:
    python tools/backfill_usage.py [--dry-run] [--verbose]

Scans orchestrator/logs/*.log for Claude CLI result entries, infers ticket /
milestone / phase context, and writes backfilled JSONL records to
orchestrator/usage.jsonl in the same format as the live recording added by
TICKET-0208.

Each backfilled record includes "backfilled": true for easy identification.
Running the script twice produces zero duplicate entries (idempotent on the
key tuple (timestamp, agent, ticket_id)).
"""

import argparse
import json
import os
import re
import sys
from pathlib import Path

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

REPO_ROOT = Path(__file__).resolve().parent.parent
LOGS_DIR = REPO_ROOT / "orchestrator" / "logs"
USAGE_LOG = REPO_ROOT / "orchestrator" / "usage.jsonl"
TICKETS_DIR = REPO_ROOT / "tickets"

# ---------------------------------------------------------------------------
# Pricing constants — USD per million tokens (same as conductor.py)
# ---------------------------------------------------------------------------

MODEL_PRICING = {
    "opus":   {"input": 15.0,  "output": 75.0},
    "sonnet": {"input":  3.0,  "output": 15.0},
    "haiku":  {"input":  0.80, "output":  4.0},
}


def calc_cost_usd(model: str, input_tokens: int, output_tokens: int) -> float:
    """Calculate cost in USD from token counts using MODEL_PRICING."""
    model_lower = (model or "").lower()
    rates = MODEL_PRICING.get("sonnet")  # default if no match
    for key in MODEL_PRICING:
        if key in model_lower:
            rates = MODEL_PRICING[key]
            break
    return (input_tokens * rates["input"] + output_tokens * rates["output"]) / 1_000_000


# ---------------------------------------------------------------------------
# Log filename parsing
# ---------------------------------------------------------------------------

def parse_log_filename(name: str):
    """Parse a log filename into (agent, ticket_id, timestamp_str) or None.

    Supported patterns:
      Producer: producer-wave{N}-{YYYY-MM-DDTHHMMSS}.log
      Worker:   {agent-slug}-TICKET-{NNNN}-{YYYY-MM-DDTHHMMSS}.log

    Returns None for filenames that don't match either pattern.
    """
    stem = name[:-4] if name.endswith(".log") else name

    # Producer planning call: producer-wave{N}-{timestamp}
    m = re.match(r"^producer-wave(\d+)-(\d{4}-\d{2}-\d{2}T\d{6})$", stem)
    if m:
        wave_num = m.group(1)
        ts = m.group(2)
        return "producer", f"PLAN_WAVE_{wave_num}", ts

    # Worker call: {agent}-TICKET-{NNNN}-{timestamp}
    # Agent slugs may contain hyphens; split on the literal "-TICKET-" marker.
    m = re.match(r"^(.+)-TICKET-(\d+)-(\d{4}-\d{2}-\d{2}T\d{6})$", stem)
    if m:
        agent = m.group(1)
        ticket_num = m.group(2)
        ts = m.group(3)
        return agent, f"TICKET-{ticket_num}", ts

    return None


def parse_timestamp(ts_str: str) -> str:
    """Convert compact timestamp '2026-03-01T160557' to ISO '2026-03-01T16:05:57'."""
    m = re.match(r"^(\d{4}-\d{2}-\d{2})T(\d{2})(\d{2})(\d{2})$", ts_str)
    if m:
        date, hh, mm, ss = m.group(1), m.group(2), m.group(3), m.group(4)
        return f"{date}T{hh}:{mm}:{ss}"
    return ts_str  # already formatted or unrecognised — return as-is


# ---------------------------------------------------------------------------
# Log file content parsing
# ---------------------------------------------------------------------------

def parse_log_file(log_path: Path):
    """Extract usage metadata from a single log file.

    The file format is:
        === STDOUT ===
        <single-line JSON array from Claude CLI --output-format json>

        === STDERR ===
        ...
        === EXIT CODE: N ===

    Returns a dict with extracted fields, or None if parsing fails.
    Fields:
        input_tokens   (int or None)
        output_tokens  (int or None)
        model          (str or None)
        duration_seconds (float or None)
        cost_usd       (float or None)
    """
    try:
        content = log_path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return None

    # Pull out the STDOUT section
    m = re.search(r"=== STDOUT ===\n(.*?)(?:\n=== STDERR ===|\Z)", content, re.DOTALL)
    if not m:
        return None

    stdout_text = m.group(1).strip()
    if not stdout_text:
        return None

    # Parse JSON
    try:
        parsed = json.loads(stdout_text)
    except (json.JSONDecodeError, ValueError):
        return None

    if not isinstance(parsed, list):
        return None

    # Find the result entry and the system init entry
    result_entry = None
    system_model = None
    for item in parsed:
        if not isinstance(item, dict):
            continue
        if item.get("type") == "system" and item.get("subtype") == "init":
            system_model = item.get("model")
        if item.get("type") == "result":
            result_entry = item

    if result_entry is None:
        return None

    # Token counts
    raw_usage = result_entry.get("usage") or {}
    input_tokens = raw_usage.get("input_tokens")
    output_tokens = raw_usage.get("output_tokens")

    # Model — try result directly, then modelUsage keys, then system init
    model = result_entry.get("model")
    if not model:
        model_usage = result_entry.get("modelUsage") or {}
        if model_usage:
            model = next(iter(model_usage.keys()), None)
    if not model:
        model = system_model

    # Duration in seconds
    duration_ms = result_entry.get("duration_ms")
    duration_seconds = duration_ms / 1000.0 if duration_ms is not None else None

    # Cost — prefer total_cost_usd from result (most accurate, includes cache).
    # Fall back to computing from token counts if available.
    cost_usd = result_entry.get("total_cost_usd")
    if cost_usd is None and input_tokens is not None and output_tokens is not None:
        cost_usd = calc_cost_usd(model or "", input_tokens, output_tokens)

    return {
        "input_tokens": input_tokens,
        "output_tokens": output_tokens,
        "model": model,
        "duration_seconds": duration_seconds,
        "cost_usd": cost_usd,
    }


# ---------------------------------------------------------------------------
# Ticket metadata lookup
# ---------------------------------------------------------------------------

_ticket_cache: dict = {}


def load_ticket_metadata(ticket_id: str) -> dict:
    """Return {"milestone": ..., "phase": ...} for a ticket ID.

    Searches tickets/**/{ticket_id}.md and parses YAML frontmatter.
    Returns None values for fields that cannot be determined.
    """
    if ticket_id in _ticket_cache:
        return _ticket_cache[ticket_id]

    result = {"milestone": None, "phase": None}

    for ticket_file in TICKETS_DIR.rglob(f"{ticket_id}.md"):
        try:
            text = ticket_file.read_text(encoding="utf-8", errors="replace")
            for line in text.splitlines()[:30]:
                m = re.match(r'^milestone:\s*["\']?(.+?)["\']?\s*$', line)
                if m:
                    result["milestone"] = m.group(1).strip()
                m = re.match(r'^phase:\s*["\']?(.+?)["\']?\s*$', line)
                if m:
                    result["phase"] = m.group(1).strip()
        except OSError:
            continue
        break  # use first match

    _ticket_cache[ticket_id] = result
    return result


# ---------------------------------------------------------------------------
# Ledger helpers
# ---------------------------------------------------------------------------

def load_existing_keys(ledger_path: Path) -> set:
    """Load (timestamp, agent, ticket_id) tuples from an existing ledger.

    Used for idempotency — records with matching keys are skipped.
    """
    keys = set()
    if not ledger_path.exists():
        return keys

    try:
        for line in ledger_path.read_text(encoding="utf-8", errors="replace").splitlines():
            line = line.strip()
            if not line:
                continue
            try:
                record = json.loads(line)
                ts = record.get("timestamp", "")
                agent = record.get("agent", "")
                ticket = record.get("ticket_id", "")
                if ts and agent and ticket:
                    keys.add((ts, agent, ticket))
            except (json.JSONDecodeError, ValueError):
                continue
    except OSError:
        pass

    return keys


def append_records(ledger_path: Path, records: list):
    """Append a list of record dicts to the JSONL ledger (one JSON per line)."""
    with open(ledger_path, "a", encoding="utf-8") as f:
        for record in records:
            f.write(json.dumps(record) + "\n")
        f.flush()


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Backfill orchestrator usage records from existing log files."
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print what would be written without modifying the ledger.",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Show per-record details during processing.",
    )
    args = parser.parse_args()

    if not LOGS_DIR.exists():
        print(f"ERROR: Logs directory not found: {LOGS_DIR}", file=sys.stderr)
        sys.exit(1)

    # Load existing ledger keys for idempotency checking
    existing_keys = load_existing_keys(USAGE_LOG)
    if args.verbose:
        print(f"Loaded {len(existing_keys)} existing ledger key(s) for idempotency check.")

    # Enumerate log files sorted by name (chronological by filename timestamp)
    log_files = sorted(LOGS_DIR.glob("*.log"))
    if not log_files:
        print("No log files found in orchestrator/logs/.")
        sys.exit(0)

    if args.verbose:
        print(f"Found {len(log_files)} log file(s) to scan.")

    new_records = []
    seen_keys = set(existing_keys)  # track keys added this run too
    skipped_count = 0
    parse_error_count = 0

    for log_path in log_files:
        filename = log_path.name

        # --- Filename parsing ---
        parsed = parse_log_filename(filename)
        if parsed is None:
            if args.verbose:
                print(f"  SKIP (unrecognised filename): {filename}")
            continue

        agent, ticket_id, ts_str = parsed
        timestamp = parse_timestamp(ts_str)

        # --- Idempotency check ---
        key = (timestamp, agent, ticket_id)
        if key in seen_keys:
            skipped_count += 1
            if args.verbose:
                print(f"  SKIP (already in ledger): {filename}")
            continue

        # --- Content parsing ---
        usage_data = parse_log_file(log_path)
        if usage_data is None:
            if args.verbose:
                print(f"  SKIP (parse failed): {filename}")
            parse_error_count += 1
            continue

        # --- call_type and ticket metadata ---
        call_type = "planning" if agent == "producer" else "worker"
        if call_type == "worker":
            meta = load_ticket_metadata(ticket_id)
            milestone = meta["milestone"]
            phase = meta["phase"]
        else:
            milestone = None
            phase = None

        # --- Build the record (matches live ledger schema from TICKET-0208) ---
        record = {
            "timestamp": timestamp,
            "agent": agent,
            "ticket_id": ticket_id,
            "milestone": milestone,
            "phase": phase,
            "model": usage_data["model"],
            "input_tokens": usage_data["input_tokens"],
            "output_tokens": usage_data["output_tokens"],
            "cost_usd": usage_data["cost_usd"],
            "duration_seconds": usage_data["duration_seconds"],
            "call_type": call_type,
            "backfilled": True,
        }

        new_records.append(record)
        seen_keys.add(key)

        if args.verbose:
            cost_str = (
                f"${record['cost_usd']:.6f}"
                if record["cost_usd"] is not None
                else "null"
            )
            print(f"  NEW : {filename}")
            print(
                f"        agent={agent}, ticket={ticket_id}, "
                f"model={record['model']}, cost={cost_str}"
            )
            if milestone:
                print(f"        milestone={milestone}, phase={phase}")

    # --- Write new records ---
    if not args.dry_run and new_records:
        try:
            append_records(USAGE_LOG, new_records)
        except OSError as exc:
            print(f"ERROR: Failed to write to ledger: {exc}", file=sys.stderr)
            sys.exit(1)

    # --- Summary ---
    mode_prefix = "[DRY RUN] " if args.dry_run else ""
    print(f"\n{mode_prefix}Backfill complete:")
    print(f"  Log files scanned : {len(log_files)}")
    print(f"  New records       : {len(new_records)}")
    print(f"  Skipped (dup.)    : {skipped_count}")
    print(f"  Parse errors      : {parse_error_count}")

    if args.dry_run and new_records and args.verbose:
        print(f"\nWould write {len(new_records)} record(s):")
        for r in new_records:
            print(f"  {json.dumps(r)}")
    elif args.dry_run and new_records:
        print(f"\nWould write {len(new_records)} record(s) to: {USAGE_LOG}")
        print("Re-run with --verbose to see individual records.")


if __name__ == "__main__":
    main()
