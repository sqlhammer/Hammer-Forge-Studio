#!/usr/bin/env python3
"""milestone_status.py — Fast replacement for milestone_status.sh.

Usage: python tools/milestone_status.py [M#]
Accepts "M5", "5", "m5". Defaults to auto-detecting the active milestone.
Scans only active ticket dirs (skips _archive/ entirely).
"""

import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
TICKETS_DIR = REPO_ROOT / "tickets"
MILESTONES_FILE = REPO_ROOT / "docs" / "studio" / "milestones.md"


def normalize_milestone(raw: str) -> str:
    """Normalize '5', 'M5', 'm5' → 'M5'."""
    raw = raw.strip().lstrip("Mm")
    return f"M{raw}"


def auto_detect_milestone() -> str:
    text = MILESTONES_FILE.read_text(encoding="utf-8")
    for line in text.splitlines():
        m = re.match(r"^\|\s*(M\d+)\s*\|", line)
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


def main():
    # Determine target milestone
    if len(sys.argv) >= 2:
        target = normalize_milestone(sys.argv[1])
    else:
        target = auto_detect_milestone()

    # Collect active ticket dirs (skip _archive/)
    active_dirs = [
        d for d in TICKETS_DIR.iterdir()
        if d.is_dir() and d.name != "_archive"
    ]
    # Also include root-level tickets (TICKET-*.md directly in tickets/)
    ticket_files = list(TICKETS_DIR.glob("TICKET-*.md"))
    for d in active_dirs:
        ticket_files.extend(d.glob("TICKET-*.md"))

    # Parse all tickets
    status_map: dict[str, str] = {}  # ticket_id → status (all active)
    rows = []  # (id, title, status, owner, phase, depends_str) for target milestone
    done_count = 0
    in_progress_count = 0
    open_count = 0

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

        rows.append((ticket_id, title, status, owner, phase, depends_str))

        if status == "DONE":
            done_count += 1
        elif status == "IN_PROGRESS":
            in_progress_count += 1
        else:
            open_count += 1

    total = len(rows)
    if total == 0:
        print(f"No tickets found for milestone {target}")
        sys.exit(0)

    # Sort by ticket ID
    rows.sort(key=lambda r: r[0])

    # Output table
    print(f"## {target} Milestone Status")
    print()
    print("| Ticket | Title | Status | Owner | Phase | Dependencies |")
    print("|--------|-------|--------|-------|-------|--------------|")

    for t_id, t_title, t_status, t_owner, t_phase, t_deps in rows:
        if len(t_title) > 50:
            t_title = t_title[:47] + "..."
        deps_col = t_deps if t_deps else "-"
        print(f"| {t_id} | {t_title} | {t_status} | {t_owner} | {t_phase} | {deps_col} |")

    print()
    print(f"**Stats:** {done_count}/{total} DONE, {in_progress_count} IN_PROGRESS, {open_count} OPEN")

    # Check dependency violations
    # Archive invariant: any dep not in status_map is archived → treat as DONE
    violations = []
    for t_id, _, t_status, _, _, t_deps in rows:
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
