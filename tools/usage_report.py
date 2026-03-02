#!/usr/bin/env python3
"""usage_report.py — Usage summary and capacity gauges for Hammer Forge Studio orchestrator.

Usage:
    python tools/usage_report.py [options]

Options:
    --by-agent          Per-agent breakdown (cost, tokens, call count)
    --by-ticket         Per-ticket breakdown (cost, tokens, duration)
    --by-phase          Per-phase breakdown within each milestone (cost, tokens, ticket count)
    --capacity          Capacity utilization gauges (5hr rolling, per-session, weekly)
    --window-reset STR  Time remaining in the current 5-hour capacity window, e.g.
                        "Resets in 1 hr 4 min". When provided, the 5-hour window start
                        is calculated as (now + time_remaining - 5h) rather than
                        (latest_record_ts - 5h), giving a more accurate capacity reading.
    --json              Output entire report as a single JSON object to stdout
    --no-color          Disable ANSI color output
    --help              Show this help message

Reads orchestrator/usage.jsonl and orchestrator/config.json from the repo root.
Uses only Python standard library — no external dependencies.
"""

import argparse
import json
import re
import sys
from collections import defaultdict
from datetime import datetime, timedelta, timezone
from pathlib import Path

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

REPO_ROOT = Path(__file__).resolve().parent.parent
USAGE_LOG = REPO_ROOT / "orchestrator" / "usage.jsonl"
CONFIG_JSON = REPO_ROOT / "orchestrator" / "config.json"

# ---------------------------------------------------------------------------
# Default plan limits (used if config section is missing)
# ---------------------------------------------------------------------------

DEFAULT_PLAN_LIMITS = {
    "plan_tier": "Unknown",
    "five_hour_output_token_limit": 220000,
    "weekly_output_token_limit": 3080000,
}

# Opus output token weighting multiplier for capacity calculations
OPUS_CAPACITY_WEIGHT = 1.0

# Session gap threshold: records more than this many minutes apart start a new session
SESSION_GAP_MINUTES = 30

# ---------------------------------------------------------------------------
# ANSI color codes
# ---------------------------------------------------------------------------

ANSI_RESET = "\033[0m"
ANSI_GREEN = "\033[32m"
ANSI_YELLOW = "\033[33m"
ANSI_RED = "\033[31m"
ANSI_BOLD = "\033[1m"
ANSI_DIM = "\033[2m"


def colorize(text: str, code: str, use_color: bool) -> str:
    if not use_color:
        return text
    return f"{code}{text}{ANSI_RESET}"


# ---------------------------------------------------------------------------
# Data loading
# ---------------------------------------------------------------------------

def load_records() -> list[dict]:
    """Load and return all records from the JSONL ledger.

    Returns an empty list if the file does not exist or is empty.
    """
    if not USAGE_LOG.exists():
        return []

    records = []
    try:
        with USAGE_LOG.open(encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    record = json.loads(line)
                    records.append(record)
                except (json.JSONDecodeError, ValueError):
                    continue
    except OSError:
        return []

    return records


def load_plan_limits() -> tuple[dict, bool]:
    """Load plan_limits from config.json.

    Returns (limits_dict, used_defaults). If the section is missing or the
    file cannot be read, returns (DEFAULT_PLAN_LIMITS, True) and prints a
    warning to stderr.
    """
    try:
        config = json.loads(CONFIG_JSON.read_text(encoding="utf-8"))
        if "plan_limits" in config:
            limits = config["plan_limits"]
            # Strip _docs keys
            return {k: v for k, v in limits.items() if not k.startswith("_")}, False
    except (OSError, json.JSONDecodeError):
        pass

    print(
        "WARNING: Could not read plan_limits from orchestrator/config.json — using hardcoded defaults.",
        file=sys.stderr,
    )
    return dict(DEFAULT_PLAN_LIMITS), True


# ---------------------------------------------------------------------------
# Timestamp parsing
# ---------------------------------------------------------------------------

def parse_ts(ts_str: str | None) -> datetime | None:
    """Parse an ISO 8601 timestamp string to a timezone-aware datetime (UTC)."""
    if not ts_str:
        return None
    for fmt in (
        "%Y-%m-%dT%H:%M:%S%z",
        "%Y-%m-%dT%H:%M:%S",
        "%Y-%m-%dT%H:%M:%S.%f%z",
        "%Y-%m-%dT%H:%M:%S.%f",
    ):
        try:
            dt = datetime.strptime(ts_str, fmt)
            if dt.tzinfo is None:
                dt = dt.replace(tzinfo=timezone.utc)
            return dt
        except ValueError:
            continue
    return None


# ---------------------------------------------------------------------------
# Window-reset parsing
# ---------------------------------------------------------------------------

def parse_window_reset(text: str) -> int | None:
    """Parse a 'Resets in ...' string and return total minutes remaining.

    Accepted formats (case-insensitive):
      "Resets in 1 hr 4 min"   → 64
      "Resets in 2 hr"         → 120
      "Resets in 45 min"       → 45

    Returns None if the string cannot be parsed.
    """
    text = text.strip()
    m = re.search(r"(\d+)\s*hr\s+(\d+)\s*min", text, re.IGNORECASE)
    if m:
        return int(m.group(1)) * 60 + int(m.group(2))
    m = re.search(r"(\d+)\s*hr", text, re.IGNORECASE)
    if m:
        return int(m.group(1)) * 60
    m = re.search(r"(\d+)\s*min", text, re.IGNORECASE)
    if m:
        return int(m.group(1))
    return None


# ---------------------------------------------------------------------------
# Safe getters
# ---------------------------------------------------------------------------

def safe_float(v, default: float = 0.0) -> float:
    try:
        return float(v) if v is not None else default
    except (TypeError, ValueError):
        return default


def safe_int(v, default: int = 0) -> int:
    try:
        return int(v) if v is not None else default
    except (TypeError, ValueError):
        return default


# ---------------------------------------------------------------------------
# Capacity weighting
# ---------------------------------------------------------------------------

def weighted_output_tokens(record: dict) -> float:
    """Return output tokens with Opus 1.7x weighting applied for capacity calcs."""
    output = safe_float(record.get("output_tokens"))
    model = (record.get("model") or "").lower()
    if "opus" in model:
        return output * OPUS_CAPACITY_WEIGHT
    return output


# ---------------------------------------------------------------------------
# ASCII progress bar
# ---------------------------------------------------------------------------

def progress_bar(value: float, limit: float, width: int = 20, use_color: bool = True) -> str:
    """Render an ASCII progress bar with color thresholds.

    Color thresholds: green <50%, yellow 50-80%, red >80%.
    Returns a string like '[########----------] 40% of 5hr limit'.
    """
    pct = (value / limit * 100) if limit > 0 else 0.0
    filled = int(min(width, round(pct / 100 * width)))
    bar_chars = "#" * filled + "-" * (width - filled)

    if pct < 50:
        color = ANSI_GREEN
    elif pct <= 80:
        color = ANSI_YELLOW
    else:
        color = ANSI_RED

    bar_str = f"[{colorize(bar_chars, color, use_color)}]"
    return f"{bar_str} {pct:.1f}%"


# ---------------------------------------------------------------------------
# Formatting helpers
# ---------------------------------------------------------------------------

def fmt_cost(usd: float) -> str:
    return f"${usd:.4f}"


def fmt_tokens(n: int) -> str:
    return f"{n:,}"


def fmt_duration(seconds: float) -> str:
    if seconds < 60:
        return f"{seconds:.1f}s"
    m = int(seconds // 60)
    s = seconds % 60
    return f"{m}m {s:.0f}s"


def section_header(title: str, use_color: bool) -> str:
    return colorize(f"\n{'='*60}\n  {title}\n{'='*60}", ANSI_BOLD, use_color)


# ---------------------------------------------------------------------------
# Summary computation
# ---------------------------------------------------------------------------

def compute_summary(records: list[dict]) -> dict:
    """Compute the milestone-level summary aggregates."""
    total_cost = 0.0
    producer_cost = 0.0
    worker_cost = 0.0
    total_input = 0
    total_output = 0
    total_duration = 0.0
    wave_ids: set[str] = set()

    for r in records:
        cost = safe_float(r.get("cost_usd"))
        total_cost += cost
        call_type = r.get("call_type", "worker")
        if call_type == "planning":
            producer_cost += cost
            ticket_id = r.get("ticket_id", "")
            if ticket_id.startswith("PLAN_WAVE_"):
                wave_ids.add(ticket_id)
        else:
            worker_cost += cost
        total_input += safe_int(r.get("input_tokens"))
        total_output += safe_int(r.get("output_tokens"))
        total_duration += safe_float(r.get("duration_seconds"))

    return {
        "total_cost_usd": total_cost,
        "producer_cost_usd": producer_cost,
        "worker_cost_usd": worker_cost,
        "total_input_tokens": total_input,
        "total_output_tokens": total_output,
        "total_duration_seconds": total_duration,
        "wave_count": len(wave_ids),
        "record_count": len(records),
    }


# ---------------------------------------------------------------------------
# Breakdown computations
# ---------------------------------------------------------------------------

def compute_by_agent(records: list[dict]) -> dict:
    """Per-agent: cost, input_tokens, output_tokens, call_count."""
    agents: dict[str, dict] = defaultdict(lambda: {
        "cost_usd": 0.0, "input_tokens": 0, "output_tokens": 0, "call_count": 0
    })
    for r in records:
        agent = r.get("agent", "unknown")
        agents[agent]["cost_usd"] += safe_float(r.get("cost_usd"))
        agents[agent]["input_tokens"] += safe_int(r.get("input_tokens"))
        agents[agent]["output_tokens"] += safe_int(r.get("output_tokens"))
        agents[agent]["call_count"] += 1
    return dict(sorted(agents.items(), key=lambda x: x[1]["cost_usd"], reverse=True))


def compute_by_ticket(records: list[dict]) -> dict:
    """Per-ticket: cost, input_tokens, output_tokens, duration_seconds."""
    tickets: dict[str, dict] = defaultdict(lambda: {
        "cost_usd": 0.0, "input_tokens": 0, "output_tokens": 0, "duration_seconds": 0.0
    })
    for r in records:
        tid = r.get("ticket_id", "unknown")
        tickets[tid]["cost_usd"] += safe_float(r.get("cost_usd"))
        tickets[tid]["input_tokens"] += safe_int(r.get("input_tokens"))
        tickets[tid]["output_tokens"] += safe_int(r.get("output_tokens"))
        tickets[tid]["duration_seconds"] += safe_float(r.get("duration_seconds"))
    return dict(sorted(tickets.items(), key=lambda x: x[1]["cost_usd"], reverse=True))


def compute_by_phase(records: list[dict]) -> dict:
    """Per-milestone, per-phase: cost, tokens, ticket count (unique tickets)."""
    # Structure: {milestone: {phase: {cost, input, output, tickets: set}}}
    milestones: dict[str, dict] = defaultdict(lambda: defaultdict(lambda: {
        "cost_usd": 0.0, "input_tokens": 0, "output_tokens": 0, "tickets": set()
    }))
    for r in records:
        ms = r.get("milestone") or "Unknown"
        phase = r.get("phase") or "Unknown"
        milestones[ms][phase]["cost_usd"] += safe_float(r.get("cost_usd"))
        milestones[ms][phase]["input_tokens"] += safe_int(r.get("input_tokens"))
        milestones[ms][phase]["output_tokens"] += safe_int(r.get("output_tokens"))
        tid = r.get("ticket_id")
        if tid and not tid.startswith("PLAN_WAVE_"):
            milestones[ms][phase]["tickets"].add(tid)

    # Convert sets to counts
    result = {}
    for ms, phases in sorted(milestones.items()):
        result[ms] = {}
        for phase, data in sorted(phases.items()):
            result[ms][phase] = {
                "cost_usd": data["cost_usd"],
                "input_tokens": data["input_tokens"],
                "output_tokens": data["output_tokens"],
                "ticket_count": len(data["tickets"]),
            }
    return result


# ---------------------------------------------------------------------------
# Capacity computations
# ---------------------------------------------------------------------------

def compute_capacity(records: list[dict], plan_limits: dict, window_reset_minutes: int | None = None) -> dict:
    """Compute capacity utilization metrics.

    If *window_reset_minutes* is provided (parsed from --window-reset), the
    5-hour window start is anchored to the real reset time:
        window_start = now + window_reset_minutes - 5h
    Otherwise the window is computed as latest_record_ts - 5h.
    """
    five_hour_limit = safe_int(plan_limits.get("five_hour_output_token_limit", DEFAULT_PLAN_LIMITS["five_hour_output_token_limit"]))
    weekly_limit = safe_int(plan_limits.get("weekly_output_token_limit", DEFAULT_PLAN_LIMITS["weekly_output_token_limit"]))

    # Parse timestamps and sort records
    timed_records = []
    for r in records:
        dt = parse_ts(r.get("timestamp"))
        if dt is not None:
            timed_records.append((dt, r))

    timed_records.sort(key=lambda x: x[0])

    if not timed_records:
        return {
            "five_hour_window": {"used_weighted": 0, "limit": five_hour_limit, "pct": 0.0},
            "weekly_window": {"used_weighted": 0, "limit": weekly_limit, "pct": 0.0},
            "sessions": [],
        }

    latest_ts = timed_records[-1][0]

    # --- Rolling 5-hour window ---
    if window_reset_minutes is not None:
        # Anchor to the real reset clock: now + time_remaining - 5h
        now = datetime.now(timezone.utc)
        window_reset_ts = now + timedelta(minutes=window_reset_minutes)
        cutoff_5h = window_reset_ts - timedelta(hours=5)
    else:
        cutoff_5h = latest_ts - timedelta(hours=5)
    used_5h = sum(
        weighted_output_tokens(r)
        for dt, r in timed_records
        if dt >= cutoff_5h
    )

    # --- Weekly rolling window ---
    cutoff_7d = latest_ts - timedelta(days=7)
    used_7d = sum(
        weighted_output_tokens(r)
        for dt, r in timed_records
        if dt >= cutoff_7d
    )

    # --- Per-conductor-session grouping ---
    # Contiguous timestamps with <SESSION_GAP_MINUTES gap = same session
    sessions = []
    if timed_records:
        current_session_records = [timed_records[0]]
        for i in range(1, len(timed_records)):
            prev_dt = timed_records[i - 1][0]
            curr_dt = timed_records[i][0]
            gap = (curr_dt - prev_dt).total_seconds() / 60.0
            if gap > SESSION_GAP_MINUTES:
                sessions.append(current_session_records)
                current_session_records = [timed_records[i]]
            else:
                current_session_records.append(timed_records[i])
        sessions.append(current_session_records)

    session_data = []
    for idx, sess_records in enumerate(sessions, 1):
        sess_start = sess_records[0][0]
        sess_end = sess_records[-1][0]
        raw_output = sum(safe_int(r.get("output_tokens")) for _, r in sess_records)
        weighted = sum(weighted_output_tokens(r) for _, r in sess_records)
        session_data.append({
            "session_num": idx,
            "start": sess_start.isoformat(),
            "end": sess_end.isoformat(),
            "record_count": len(sess_records),
            "output_tokens_raw": raw_output,
            "output_tokens_weighted": int(weighted),
        })

    return {
        "five_hour_window": {
            "used_weighted": int(used_5h),
            "limit": five_hour_limit,
            "pct": (used_5h / five_hour_limit * 100) if five_hour_limit > 0 else 0.0,
            "window_start": cutoff_5h.isoformat(),
            "window_end": latest_ts.isoformat(),
        },
        "weekly_window": {
            "used_weighted": int(used_7d),
            "limit": weekly_limit,
            "pct": (used_7d / weekly_limit * 100) if weekly_limit > 0 else 0.0,
            "window_start": cutoff_7d.isoformat(),
            "window_end": latest_ts.isoformat(),
        },
        "sessions": session_data,
    }


# ---------------------------------------------------------------------------
# Human-readable output
# ---------------------------------------------------------------------------

def print_summary(summary: dict, use_color: bool):
    print(section_header("USAGE SUMMARY", use_color))
    print(f"  Total cost      : {colorize(fmt_cost(summary['total_cost_usd']), ANSI_BOLD, use_color)}")
    print(f"  Producer cost   : {fmt_cost(summary['producer_cost_usd'])}")
    print(f"  Worker cost     : {fmt_cost(summary['worker_cost_usd'])}")
    print(f"  Input tokens    : {fmt_tokens(summary['total_input_tokens'])}")
    print(f"  Output tokens   : {fmt_tokens(summary['total_output_tokens'])}")
    print(f"  Total duration  : {fmt_duration(summary['total_duration_seconds'])}")
    print(f"  Planning waves  : {summary['wave_count']}")
    print(f"  Total records   : {summary['record_count']}")


def print_by_agent(by_agent: dict, use_color: bool):
    print(section_header("BREAKDOWN: BY AGENT", use_color))
    if not by_agent:
        print("  (no data)")
        return
    col_w = max((len(a) for a in by_agent), default=20)
    header = f"  {'Agent':<{col_w}}  {'Cost':>12}  {'Input':>12}  {'Output':>12}  {'Calls':>6}"
    print(colorize(header, ANSI_DIM, use_color))
    print("  " + "-" * (col_w + 50))
    for agent, data in by_agent.items():
        print(
            f"  {agent:<{col_w}}  "
            f"{fmt_cost(data['cost_usd']):>12}  "
            f"{fmt_tokens(data['input_tokens']):>12}  "
            f"{fmt_tokens(data['output_tokens']):>12}  "
            f"{data['call_count']:>6}"
        )


def print_by_ticket(by_ticket: dict, use_color: bool):
    print(section_header("BREAKDOWN: BY TICKET", use_color))
    if not by_ticket:
        print("  (no data)")
        return
    col_w = max((len(t) for t in by_ticket), default=20)
    header = f"  {'Ticket':<{col_w}}  {'Cost':>12}  {'Input':>12}  {'Output':>12}  {'Duration':>10}"
    print(colorize(header, ANSI_DIM, use_color))
    print("  " + "-" * (col_w + 52))
    for tid, data in by_ticket.items():
        print(
            f"  {tid:<{col_w}}  "
            f"{fmt_cost(data['cost_usd']):>12}  "
            f"{fmt_tokens(data['input_tokens']):>12}  "
            f"{fmt_tokens(data['output_tokens']):>12}  "
            f"{fmt_duration(data['duration_seconds']):>10}"
        )


def print_by_phase(by_phase: dict, use_color: bool):
    print(section_header("BREAKDOWN: BY PHASE", use_color))
    if not by_phase:
        print("  (no data)")
        return
    for milestone, phases in by_phase.items():
        print(f"\n  {colorize(f'Milestone: {milestone}', ANSI_BOLD, use_color)}")
        col_w = max((len(p) for p in phases), default=20)
        header = f"    {'Phase':<{col_w}}  {'Cost':>12}  {'Input':>12}  {'Output':>12}  {'Tickets':>8}"
        print(colorize(header, ANSI_DIM, use_color))
        print("    " + "-" * (col_w + 50))
        for phase, data in phases.items():
            print(
                f"    {phase:<{col_w}}  "
                f"{fmt_cost(data['cost_usd']):>12}  "
                f"{fmt_tokens(data['input_tokens']):>12}  "
                f"{fmt_tokens(data['output_tokens']):>12}  "
                f"{data['ticket_count']:>8}"
            )


def print_capacity(capacity: dict, plan_limits: dict, use_color: bool):
    print(section_header("CAPACITY GAUGES", use_color))
    tier = plan_limits.get("plan_tier", "Unknown")
    print(f"  Plan tier: {colorize(tier, ANSI_BOLD, use_color)}")
    print(f"  (Opus output tokens weighted at {OPUS_CAPACITY_WEIGHT}x for capacity)\n")

    # 5-hour rolling window
    five = capacity["five_hour_window"]
    bar_5h = progress_bar(five["used_weighted"], five["limit"], use_color=use_color)
    print(f"  5-Hour Rolling Window")
    print(f"    {bar_5h} of {fmt_tokens(five['limit'])} limit")
    print(f"    Used (weighted): {fmt_tokens(five['used_weighted'])} tokens")
    print(f"    Window: {five.get('window_start', 'N/A')} -> {five.get('window_end', 'N/A')}")

    # Weekly rolling window
    print()
    weekly = capacity["weekly_window"]
    bar_7d = progress_bar(weekly["used_weighted"], weekly["limit"], use_color=use_color)
    print(f"  Weekly Rolling Window (7 days)")
    print(f"    {bar_7d} of {fmt_tokens(weekly['limit'])} limit")
    print(f"    Used (weighted): {fmt_tokens(weekly['used_weighted'])} tokens")
    print(f"    Window: {weekly.get('window_start', 'N/A')} -> {weekly.get('window_end', 'N/A')}")

    # Per-session breakdown
    print()
    sessions = capacity.get("sessions", [])
    print(f"  Conductor Sessions ({len(sessions)} detected, gap threshold: {SESSION_GAP_MINUTES}min)")
    if not sessions:
        print("    (no sessions)")
    else:
        for sess in sessions:
            print(
                f"    Session {sess['session_num']:>2}: "
                f"{sess['start'][:19]} -> {sess['end'][:19]}  "
                f"records={sess['record_count']}  "
                f"output={fmt_tokens(sess['output_tokens_raw'])}  "
                f"weighted={fmt_tokens(sess['output_tokens_weighted'])}"
            )


# ---------------------------------------------------------------------------
# JSON output assembly
# ---------------------------------------------------------------------------

def build_json_report(
    summary: dict,
    breakdowns: dict,
    capacity: dict | None,
    plan_limits: dict,
) -> dict:
    report: dict = {
        "summary": summary,
        "breakdowns": breakdowns,
    }
    if capacity is not None:
        report["capacity"] = {
            "plan_limits": {k: v for k, v in plan_limits.items() if not k.startswith("_")},
            "opus_weighting": OPUS_CAPACITY_WEIGHT,
            **capacity,
        }
    return report


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Usage report and capacity gauges for Hammer Forge Studio orchestrator.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("--by-agent", action="store_true", help="Show per-agent cost/token breakdown")
    parser.add_argument("--by-ticket", action="store_true", help="Show per-ticket cost/token breakdown")
    parser.add_argument("--by-phase", action="store_true", help="Show per-phase breakdown within each milestone")
    parser.add_argument("--capacity", action="store_true", help="Show capacity utilization gauges")
    parser.add_argument(
        "--window-reset",
        metavar="STR",
        default=None,
        help='Time remaining in the current 5-hour window, e.g. "Resets in 1 hr 4 min"',
    )
    parser.add_argument("--json", action="store_true", dest="json_out", help="Output report as JSON")
    parser.add_argument(
        "--no-color",
        action="store_true",
        help="Disable ANSI color output",
    )
    args = parser.parse_args()

    # Color detection: disable if --no-color or stdout is not a TTY
    use_color = not args.no_color and sys.stdout.isatty() and not args.json_out

    # Load records
    records = load_records()
    if not records:
        if args.json_out:
            print(json.dumps({"error": "No usage data found"}))
        else:
            print("No usage data found.")
        sys.exit(0)

    # Load plan limits (for capacity)
    plan_limits, _used_defaults = load_plan_limits()

    # Parse optional window-reset string
    window_reset_minutes: int | None = None
    if args.window_reset:
        window_reset_minutes = parse_window_reset(args.window_reset)
        if window_reset_minutes is None:
            print(
                f"WARNING: Could not parse --window-reset value: {args.window_reset!r}\n"
                "  Expected format: \"Resets in 1 hr 4 min\", \"Resets in 45 min\", etc.\n"
                "  Falling back to latest-record-based 5-hour window.",
                file=sys.stderr,
            )

    # Compute all sections
    summary = compute_summary(records)

    breakdowns: dict = {}
    if args.by_agent:
        breakdowns["by_agent"] = compute_by_agent(records)
    if args.by_ticket:
        breakdowns["by_ticket"] = compute_by_ticket(records)
    if args.by_phase:
        breakdowns["by_phase"] = compute_by_phase(records)

    capacity = compute_capacity(records, plan_limits, window_reset_minutes) if args.capacity else None

    # JSON output path
    if args.json_out:
        report = build_json_report(summary, breakdowns, capacity, plan_limits)
        print(json.dumps(report, indent=2, default=str))
        sys.exit(0)

    # Human-readable output
    print_summary(summary, use_color)

    if args.by_agent:
        print_by_agent(breakdowns["by_agent"], use_color)

    if args.by_ticket:
        print_by_ticket(breakdowns["by_ticket"], use_color)

    if args.by_phase:
        print_by_phase(breakdowns["by_phase"], use_color)

    if args.capacity:
        print_capacity(capacity, plan_limits, use_color)

    print()
    sys.exit(0)


if __name__ == "__main__":
    main()
