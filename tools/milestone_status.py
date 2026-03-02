#!/usr/bin/env python3
"""milestone_status.py — Fast replacement for milestone_status.sh.

Usage: python tools/milestone_status.py [--brief] [M#|T#]
  --brief  Only show OPEN/IN_PROGRESS tickets; collapse DONE into a count.
           Use this for the milestone-summary skill to minimise output tokens.
Accepts "M5", "5", "m5" for game milestones; "T1", "t1" for tooling milestones.
Defaults to auto-detecting the active milestone (first non-Complete row in
milestones.md; M-series rows are listed before T-series rows, so M-series
Active milestones are returned first when both series have active milestones).
Scans only active ticket dirs (skips _archive/ entirely).
"""

import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
TICKETS_DIR = REPO_ROOT / "tickets"
MILESTONES_FILE = REPO_ROOT / "docs" / "studio" / "milestones.md"
STATE_JSON = REPO_ROOT / "orchestrator" / "state.json"


def normalize_milestone(raw: str) -> str:
    """Normalize '5', 'M5', 'm5' → 'M5'; 'T1', 't1' → 'T1'."""
    raw = raw.strip()
    if raw.upper().startswith("T"):
        return f"T{raw[1:]}"
    raw = raw.lstrip("Mm")
    return f"M{raw}"


def auto_detect_milestone() -> str:
    text = MILESTONES_FILE.read_text(encoding="utf-8")
    for line in text.splitlines():
        m = re.match(r"^\|\s*([MT]\d+)\s*\|", line)
        if not m:
            continue
        ms_id = m.group(1)
        # Check status column — skip Complete rows
        if "Complete" not in line:
            return ms_id
    print("ERROR: Could not auto-detect active milestone from milestones.md", file=sys.stderr)
    sys.exit(1)


def parse_frontmatter(path: Path) -> dict:
    """Read lines until the second '---', extract key: value pairs."""
    fields = {}
    dashes = 0
    try:
        with path.open(encoding="utf-8") as f:
            for raw in f:
                line = raw.rstrip("\r\n")
                if line == "---":
                    dashes += 1
                    if dashes == 2:
                        break
                    continue
                if dashes < 1:
                    continue
                if ":" not in line:
                    continue
                key, _, val = line.partition(":")
                fields[key.strip()] = val.strip()
    except (OSError, UnicodeDecodeError):
        pass
    return fields


def parse_depends(raw: str) -> list[str]:
    """Parse '[TICKET-0001, TICKET-0002]' or '[]' → list of ticket IDs."""
    raw = raw.strip().strip("[]")
    if not raw:
        return []
    return [t.strip() for t in raw.split(",") if t.strip()]


def load_active_tickets() -> set:
    """Return set of ticket IDs currently dispatched per orchestrator/state.json.

    Reads the gitignored runtime state file written by the conductor. Returns an
    empty set if the file is absent or unparseable (e.g., orchestrator not running).
    """
    try:
        data = json.loads(STATE_JSON.read_text(encoding="utf-8"))
        return {w["ticket"] for w in data.get("active_workers", []) if "ticket" in w}
    except (OSError, ValueError, KeyError):
        return set()


def main():
    # Parse flags and positional args
    args = sys.argv[1:]
    brief = "--brief" in args
    args = [a for a in args if a != "--brief"]

    # Determine target milestone
    if args:
        target = normalize_milestone(args[0])
    else:
        target = auto_detect_milestone()

    # Collect active ticket dirs (skip _archive/)
    active_dirs = [
        d for d in TICKETS_DIR.iterdir()
        if d.is_dir() and d.name not in ("_archive", "_test")
    ]
    # Also include root-level tickets (TICKET-*.md directly in tickets/)
    ticket_files = list(TICKETS_DIR.glob("TICKET-*.md"))
    for d in active_dirs:
        ticket_files.extend(d.glob("TICKET-*.md"))

    # Parse all tickets
    status_map: dict[str, str] = {}  # ticket_id → status (all active)
    rows = []  # (id, title, status, owner, phase, depends_str, godot_mcp) for target milestone

    for path in ticket_files:
        fm = parse_frontmatter(path)
        ticket_id = fm.get("id", "")
        if not ticket_id:
            continue

        status = fm.get("status", "OPEN")
        status_map[ticket_id] = status

        milestone = fm.get("milestone", "").strip('"')
        if milestone != target:
            continue

        title = fm.get("title", "").strip('"')
        owner = fm.get("owner", "")
        phase = fm.get("phase", "").strip('"')
        depends_raw = fm.get("depends_on", "[]")
        deps = parse_depends(depends_raw)
        depends_str = ", ".join(deps) if deps else ""
        godot_mcp = fm.get("godot_mcp", "false").strip().lower() == "true"

        rows.append((ticket_id, title, status, owner, phase, depends_str, godot_mcp))

    # Apply real-time overlay: tickets in state.json active_workers show as IN_PROGRESS
    # even before the worker has committed the status change to git.
    active_tickets = load_active_tickets()
    if active_tickets:
        rows = [
            (t_id, t_title,
             "IN_PROGRESS" if t_id in active_tickets and t_status not in ("DONE", "IN_PROGRESS") else t_status,
             t_owner, t_phase, t_deps, t_mcp)
            for t_id, t_title, t_status, t_owner, t_phase, t_deps, t_mcp in rows
        ]
        for t_id in active_tickets:
            if t_id in status_map and status_map[t_id] not in ("DONE", "IN_PROGRESS"):
                status_map[t_id] = "IN_PROGRESS"

    # Count from effective statuses
    done_count = sum(1 for _, _, s, _, _, _, _ in rows if s == "DONE")
    in_progress_count = sum(1 for _, _, s, _, _, _, _ in rows if s == "IN_PROGRESS")
    open_count = sum(1 for _, _, s, _, _, _, _ in rows if s not in ("DONE", "IN_PROGRESS"))

    total = len(rows)
    if total == 0:
        print(f"No tickets found for milestone {target}")
        sys.exit(0)

    # Sort by ticket ID
    rows.sort(key=lambda r: r[0])

    # Output table
    print(f"## {target} Milestone Status")
    print()
    print(f"**Stats:** {done_count}/{total} DONE, {in_progress_count} IN_PROGRESS, {open_count} OPEN")

    # Check if any ticket in this milestone uses godot_mcp
    any_mcp = any(t_mcp for _, _, _, _, _, _, t_mcp in rows)

    if brief and done_count == total:
        print()
        print(f"All {total} tickets DONE. No open or in-progress work.")
    else:
        # In brief mode, only show non-DONE rows
        display_rows = [r for r in rows if r[2] != "DONE"] if brief else rows
        if brief and display_rows:
            print(f"({done_count} DONE tickets omitted — showing {len(display_rows)} actionable)")
        print()
        if any_mcp:
            print("| Ticket | Title | Status | Owner | Phase | Dependencies | MCP |")
            print("|--------|-------|--------|-------|-------|--------------|-----|")
            for t_id, t_title, t_status, t_owner, t_phase, t_deps, t_mcp in display_rows:
                if len(t_title) > 50:
                    t_title = t_title[:47] + "..."
                deps_col = t_deps if t_deps else "-"
                mcp_col = "Y" if t_mcp else "-"
                print(f"| {t_id} | {t_title} | {t_status} | {t_owner} | {t_phase} | {deps_col} | {mcp_col} |")
        else:
            print("| Ticket | Title | Status | Owner | Phase | Dependencies |")
            print("|--------|-------|--------|-------|-------|--------------|")
            for t_id, t_title, t_status, t_owner, t_phase, t_deps, _t_mcp in display_rows:
                if len(t_title) > 50:
                    t_title = t_title[:47] + "..."
                deps_col = t_deps if t_deps else "-"
                print(f"| {t_id} | {t_title} | {t_status} | {t_owner} | {t_phase} | {deps_col} |")

    # Check dependency violations
    # Archive invariant: any dep not in status_map is archived → treat as DONE
    violations = []
    for t_id, _, t_status, _, _, t_deps, _ in rows:
        if t_status not in ("IN_PROGRESS", "DONE"):
            continue
        if not t_deps:
            continue
        for dep in t_deps.split(", "):
            dep = dep.strip()
            if not dep:
                continue
            dep_status = status_map.get(dep, "DONE")  # not found → archived → DONE
            if dep_status != "DONE":
                violations.append(f"{t_id} depends on {dep} ({dep_status})")

    if violations:
        print()
        print("**Dependency Violations:**")
        for v in violations:
            print(f"- {v}")


if __name__ == "__main__":
    main()
