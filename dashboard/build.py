#!/usr/bin/env python3
"""dashboard/build.py — Build pre-baked JSON data files for the project dashboard.

Reads all ticket markdown files and docs/studio/milestones.md, extracts
structured data, computes aggregates, and writes JSON + Mermaid diagram files
to dashboard/dist/data/.

Usage: python dashboard/build.py
"""

import json
import os
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
TICKETS_DIR = REPO_ROOT / "tickets"
MILESTONES_FILE = REPO_ROOT / "docs" / "studio" / "milestones.md"
OUTPUT_DIR = REPO_ROOT / "dashboard" / "dist" / "data"
DIAGRAMS_DIR = OUTPUT_DIR / "diagrams"
HAND_CURATED_SRC = REPO_ROOT / "dashboard" / "diagrams"
HAND_CURATED_DST = OUTPUT_DIR / "architecture"


# ── Frontmatter Parsing ─────────────────────────────────────────────────────


def parse_frontmatter(path: Path) -> dict:
    """Read YAML frontmatter between --- delimiters and return key-value dict.

    Handles scalar values, quoted strings, and bracket-delimited lists.
    Modelled after tools/milestone_status.py parse_frontmatter() but extended
    for list fields (depends_on, blocks, tags).
    """
    fields: dict = {}
    dashes: int = 0
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
                key = key.strip()
                val = val.strip()
                fields[key] = val
    except (OSError, UnicodeDecodeError) as exc:
        print(f"WARNING: Could not read {path}: {exc}", file=sys.stderr)
    return fields


def parse_list_field(raw: str) -> list:
    """Parse '[TICKET-0001, TICKET-0002]' or '["TICKET-0001"]' → list of strings."""
    raw = raw.strip().strip("[]")
    if not raw:
        return []
    return [strip_quotes(item.strip()) for item in raw.split(",") if item.strip()]


def strip_quotes(val: str) -> str:
    """Remove surrounding double or single quotes from a string value."""
    if len(val) >= 2 and val[0] == val[-1] and val[0] in ('"', "'"):
        return val[1:-1]
    return val


# ── Ticket Parsing ───────────────────────────────────────────────────────────


def load_tickets() -> list:
    """Scan all ticket directories (skip _archive, _test) and parse tickets."""
    tickets: list = []

    # Collect active ticket directories
    active_dirs: list = []
    if TICKETS_DIR.is_dir():
        for entry in TICKETS_DIR.iterdir():
            if entry.is_dir() and entry.name not in ("_archive", "_test"):
                active_dirs.append(entry)

    # Gather ticket files from subdirectories and root
    ticket_files: list = list(TICKETS_DIR.glob("TICKET-*.md"))
    for d in active_dirs:
        ticket_files.extend(d.glob("TICKET-*.md"))

    for path in ticket_files:
        fm = parse_frontmatter(path)
        ticket_id = fm.get("id", "")
        if not ticket_id:
            print(f"WARNING: Skipping {path} — no 'id' in frontmatter", file=sys.stderr)
            continue

        ticket = {
            "id": ticket_id,
            "title": strip_quotes(fm.get("title", "")),
            "type": fm.get("type", ""),
            "status": fm.get("status", "OPEN"),
            "priority": fm.get("priority", ""),
            "owner": fm.get("owner", ""),
            "milestone": strip_quotes(fm.get("milestone", "")),
            "phase": strip_quotes(fm.get("phase", "")),
            "depends_on": parse_list_field(fm.get("depends_on", "[]")),
            "blocks": parse_list_field(fm.get("blocks", "[]")),
            "tags": parse_list_field(fm.get("tags", "[]")),
        }
        tickets.append(ticket)

    # Sort by ticket ID for deterministic output
    tickets.sort(key=lambda t: t["id"])
    return tickets


# ── Milestone Parsing ────────────────────────────────────────────────────────


def parse_milestone_table(lines: list, start_idx: int) -> list:
    """Parse a markdown table starting at the header row index.

    Returns list of milestone dicts extracted from the table rows.
    """
    milestones: list = []

    # Skip header and separator rows
    i = start_idx + 2
    while i < len(lines):
        line = lines[i].strip()
        if not line.startswith("|"):
            break

        cells = [c.strip() for c in line.split("|")]
        # Split produces empty strings at boundaries: ['', '#', 'Milestone', ...]
        cells = [c for c in cells if c != ""]
        if len(cells) < 4:
            i += 1
            continue

        ms_id = cells[0].strip()
        name = cells[1].strip()
        target_date = cells[2].strip() if len(cells) > 2 else ""
        status = cells[3].strip() if len(cells) > 3 else ""

        # Parse counts — they may be "—" for milestones without tickets
        total_str = cells[4].strip() if len(cells) > 4 else "—"
        open_str = cells[5].strip() if len(cells) > 5 else "—"
        done_str = cells[6].strip() if len(cells) > 6 else "—"
        qa_signoff = cells[7].strip() if len(cells) > 7 else ""

        def safe_int(s: str) -> int:
            try:
                return int(s)
            except (ValueError, TypeError):
                return 0

        milestones.append({
            "id": ms_id,
            "name": name,
            "target_date": target_date if target_date != "—" else None,
            "status": status,
            "doc_total": safe_int(total_str),
            "doc_open": safe_int(open_str),
            "doc_done": safe_int(done_str),
            "qa_signoff": qa_signoff if qa_signoff and qa_signoff != "—" else None,
        })
        i += 1

    return milestones


def load_milestones_from_doc() -> list:
    """Read docs/studio/milestones.md and parse both milestone tables."""
    if not MILESTONES_FILE.is_file():
        print(f"WARNING: Milestones file not found: {MILESTONES_FILE}", file=sys.stderr)
        return []

    lines = MILESTONES_FILE.read_text(encoding="utf-8").splitlines()
    all_milestones: list = []

    for idx, line in enumerate(lines):
        # Detect table header rows: "| # | Milestone | ..."
        if re.match(r"^\|\s*#\s*\|\s*Milestone\s*\|", line):
            all_milestones.extend(parse_milestone_table(lines, idx))

    return all_milestones


# ── Aggregate Computation ────────────────────────────────────────────────────


def compute_milestone_aggregates(milestones: list, tickets: list) -> list:
    """Enrich milestone objects with actual ticket counts computed from ticket files."""
    # Group tickets by milestone
    by_milestone: dict = {}
    for t in tickets:
        ms = t["milestone"]
        if ms:
            by_milestone.setdefault(ms, []).append(t)

    enriched: list = []
    for ms in milestones:
        ms_tickets = by_milestone.get(ms["id"], [])
        total = len(ms_tickets)
        done = sum(1 for t in ms_tickets if t["status"] == "DONE")
        in_progress = sum(1 for t in ms_tickets if t["status"] == "IN_PROGRESS")
        open_count = total - done - in_progress
        pct = round((done / total) * 100, 1) if total > 0 else 0.0

        enriched.append({
            "id": ms["id"],
            "name": ms["name"],
            "target_date": ms["target_date"],
            "status": ms["status"],
            "qa_signoff": ms["qa_signoff"],
            "total": total,
            "open": open_count,
            "in_progress": in_progress,
            "done": done,
            "completion_pct": pct,
        })

    return enriched


def compute_phases(tickets: list) -> list:
    """Build per-milestone phase breakdown with ticket lists and status counts."""
    # Group by (milestone, phase)
    phase_map: dict = {}
    for t in tickets:
        ms = t["milestone"]
        phase = t["phase"]
        if not ms or not phase:
            continue
        key = (ms, phase)
        phase_map.setdefault(key, []).append(t)

    phases: list = []
    for (ms, phase), phase_tickets in sorted(phase_map.items()):
        total = len(phase_tickets)
        done = sum(1 for t in phase_tickets if t["status"] == "DONE")
        in_progress = sum(1 for t in phase_tickets if t["status"] == "IN_PROGRESS")
        open_count = total - done - in_progress
        gate_passed = (done == total and total > 0)

        phases.append({
            "milestone": ms,
            "phase": phase,
            "tickets": [t["id"] for t in phase_tickets],
            "total": total,
            "open": open_count,
            "in_progress": in_progress,
            "done": done,
            "gate_passed": gate_passed,
        })

    return phases


def compute_dependencies(tickets: list) -> list:
    """Build dependency edge list from depends_on fields."""
    edges: list = []
    for t in tickets:
        for dep in t["depends_on"]:
            edges.append({"source": dep, "target": t["id"]})
    return edges


# ── Mermaid Diagram Generation ───────────────────────────────────────────────


STATUS_COLORS = {
    "DONE": "#28a745",       # green
    "IN_PROGRESS": "#ffc107",  # yellow
    "OPEN": "#6c757d",       # grey
}


def detect_circular_deps(tickets: list) -> set:
    """Detect tickets involved in circular dependencies via DFS cycle detection.

    Returns a set of ticket IDs that participate in at least one cycle.
    """
    ticket_ids: set = {t["id"] for t in tickets}
    # Build adjacency: dependency -> dependent (follows depends_on edges)
    adj: dict = {t["id"]: [] for t in tickets}
    for t in tickets:
        for dep in t["depends_on"]:
            if dep in ticket_ids:
                adj[dep].append(t["id"])

    WHITE, GRAY, BLACK = 0, 1, 2
    color: dict = {tid: WHITE for tid in ticket_ids}
    cycle_members: set = set()

    def dfs(node: str, path: list) -> None:
        color[node] = GRAY
        path.append(node)
        for neighbor in adj.get(node, []):
            if color[neighbor] == GRAY:
                # Found a cycle — collect all nodes on the cycle
                cycle_start = path.index(neighbor)
                cycle_members.update(path[cycle_start:])
            elif color[neighbor] == WHITE:
                dfs(neighbor, path)
        path.pop()
        color[node] = BLACK

    for tid in ticket_ids:
        if color[tid] == WHITE:
            dfs(tid, [])

    return cycle_members


def generate_mermaid_diagram(milestone_id: str, tickets: list) -> str:
    """Generate a Mermaid flowchart definition for a milestone's dependency graph.

    Handles orphan nodes (separate subgraph), cross-milestone dependencies
    (dashed edges labeled with source milestone), and circular dependency
    detection (red node borders).
    """
    ms_tickets = [t for t in tickets if t["milestone"] == milestone_id]
    if not ms_tickets:
        return ""

    # Build lookups
    all_ticket_map: dict = {t["id"]: t for t in tickets}
    ms_ticket_ids: set = {t["id"] for t in ms_tickets}

    # Identify which nodes have edges (connected vs orphans)
    connected: set = set()
    for t in ms_tickets:
        for dep in t["depends_on"]:
            connected.add(t["id"])
            connected.add(dep)
        # Also check if this ticket is depended on by another in the milestone
        for other in ms_tickets:
            if t["id"] in other["depends_on"]:
                connected.add(t["id"])

    orphans = [t for t in ms_tickets if t["id"] not in connected]
    non_orphans = [t for t in ms_tickets if t["id"] in connected]

    # Detect circular dependencies
    circular_ids: set = detect_circular_deps(ms_tickets)

    lines: list = ["flowchart LR"]

    # Orphan tickets in a separate subgraph at the top
    if orphans:
        lines.append('    subgraph orphans ["No Dependencies"]')
        for t in orphans:
            tid = t["id"]
            title = t["title"][:40].replace('"', "'")
            label = f"{tid}\\n{title}"
            lines.append(f'        {tid}["{label}"]')
        lines.append("    end")

    # Connected ticket nodes
    for t in non_orphans:
        tid = t["id"]
        title = t["title"][:40].replace('"', "'")
        label = f"{tid}\\n{title}"
        lines.append(f'    {tid}["{label}"]')

    # Cross-milestone dependency nodes (external tickets referenced by depends_on)
    cross_ms_deps: dict = {}
    for t in ms_tickets:
        for dep in t["depends_on"]:
            if dep not in ms_ticket_ids and dep in all_ticket_map:
                ext = all_ticket_map[dep]
                cross_ms_deps[dep] = ext

    for dep_id, ext in cross_ms_deps.items():
        title = ext["title"][:30].replace('"', "'")
        ms_label = ext["milestone"] or "?"
        label = f"{dep_id}\\n({ms_label}) {title}"
        lines.append(f'    {dep_id}["{label}"]:::crossMs')

    # Edges: intra-milestone (solid)
    for t in ms_tickets:
        for dep in t["depends_on"]:
            if dep in ms_ticket_ids:
                lines.append(f"    {dep} --> {t['id']}")

    # Edges: cross-milestone (dashed)
    for t in ms_tickets:
        for dep in t["depends_on"]:
            if dep not in ms_ticket_ids and dep in all_ticket_map:
                lines.append(f"    {dep} -.-> {t['id']}")

    # Style nodes by status
    for status, color in STATUS_COLORS.items():
        styled = [t["id"] for t in ms_tickets if t["status"] == status]
        if styled:
            node_list = ",".join(styled)
            lines.append(f"    style {node_list} fill:{color},color:#fff")

    # Style cross-milestone nodes (dimmed)
    if cross_ms_deps:
        cross_list = ",".join(cross_ms_deps.keys())
        lines.append(f"    style {cross_list} fill:#3a3a5a,color:#a0a0b0,stroke-dasharray:5 5")

    # Style circular dependency nodes with red border
    circular_in_ms = circular_ids & ms_ticket_ids
    if circular_in_ms:
        circ_list = ",".join(circular_in_ms)
        lines.append(f"    style {circ_list} stroke:#ff4444,stroke-width:3px")

    return "\n".join(lines) + "\n"


# ── Output ───────────────────────────────────────────────────────────────────


def write_json(filepath: Path, data) -> None:
    """Write data as formatted JSON to filepath, creating dirs as needed."""
    filepath.parent.mkdir(parents=True, exist_ok=True)
    with filepath.open("w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    print(f"  wrote {filepath.relative_to(REPO_ROOT)}")


def write_text(filepath: Path, content: str) -> None:
    """Write text content to filepath, creating dirs as needed."""
    filepath.parent.mkdir(parents=True, exist_ok=True)
    with filepath.open("w", encoding="utf-8") as f:
        f.write(content)
    print(f"  wrote {filepath.relative_to(REPO_ROOT)}")


# ── Main ─────────────────────────────────────────────────────────────────────


def main() -> int:
    print("dashboard/build.py — building JSON data files...")

    # Load raw data
    tickets = load_tickets()
    print(f"  parsed {len(tickets)} tickets")

    milestones_doc = load_milestones_from_doc()
    print(f"  parsed {len(milestones_doc)} milestones from docs")

    # Compute aggregates
    milestones = compute_milestone_aggregates(milestones_doc, tickets)
    phases = compute_phases(tickets)
    dependencies = compute_dependencies(tickets)

    # Write JSON output files
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    DIAGRAMS_DIR.mkdir(parents=True, exist_ok=True)

    write_json(OUTPUT_DIR / "milestones.json", milestones)
    write_json(OUTPUT_DIR / "tickets.json", tickets)
    write_json(OUTPUT_DIR / "phases.json", phases)
    write_json(OUTPUT_DIR / "dependencies.json", dependencies)

    # Generate Mermaid diagrams — one per milestone
    diagram_count = 0
    for ms in milestones:
        ms_id = ms["id"]
        mmd = generate_mermaid_diagram(ms_id, tickets)
        if mmd:
            write_text(DIAGRAMS_DIR / f"{ms_id}.mmd", mmd)
            diagram_count += 1

    print(f"  generated {diagram_count} Mermaid diagrams")

    # Copy hand-curated architecture diagrams from dashboard/diagrams/ to dist
    # (TICKET-0196: game-core-loop, system-architecture, agent-orchestration-flow)
    curated_count = 0
    if HAND_CURATED_SRC.is_dir():
        HAND_CURATED_DST.mkdir(parents=True, exist_ok=True)
        for mmd_file in sorted(HAND_CURATED_SRC.glob("*.mmd")):
            dst = HAND_CURATED_DST / mmd_file.name
            dst.write_bytes(mmd_file.read_bytes())
            print(f"  copied {mmd_file.name} -> {dst.relative_to(REPO_ROOT)}")
            curated_count += 1
    print(f"  copied {curated_count} hand-curated architecture diagrams")

    print("done.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
