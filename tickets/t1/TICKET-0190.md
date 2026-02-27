---
id: TICKET-0190
title: "Dashboard data parser — Python script to read tickets and milestones into JSON"
type: FEATURE
status: OPEN
priority: P1
owner: systems-programmer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "T1"
phase: "Foundation"
depends_on: []
blocks: [TICKET-0191, TICKET-0192]
tags: [tooling, dashboard, parser, python, data]
---

## Summary

Build a Python data parser that reads all ticket markdown files and `docs/studio/milestones.md`, extracts structured data, computes aggregates, and writes pre-baked JSON data files for consumption by the static dashboard site.

## Acceptance Criteria

### Script Location and Interface
- [ ] Script at `dashboard/build.py`
- [ ] Runs via `python dashboard/build.py` from repo root
- [ ] Outputs JSON data files to `dashboard/dist/data/`
- [ ] Exit code 0 on success, non-zero on fatal errors
- [ ] Graceful handling of malformed ticket files (log warning, skip file, continue)

### Ticket Parsing
- [ ] Reads all `tickets/*/TICKET-*.md` files (supports both M-series `m8/` and T-series `t1/` directories)
- [ ] Skips `tickets/_archive/` and `tickets/_test/` directories
- [ ] Parses YAML frontmatter fields: id, title, type, status, priority, owner, milestone, phase, depends_on, blocks, tags
- [ ] Handles edge cases: missing fields default to empty/null, quoted strings stripped

### Milestone Parsing
- [ ] Reads `docs/studio/milestones.md` and parses the milestone tables (both M-series and Tooling Milestones)
- [ ] Extracts: milestone ID, name, target date, status, total/open/done counts, QA sign-off date

### JSON Output Files
- [ ] `milestones.json`: Array of milestone objects with aggregated ticket counts (total, open, in_progress, done, completion percentage) computed from actual ticket files — not from the static counts in milestones.md
- [ ] `tickets.json`: Array of all ticket objects with full parsed frontmatter
- [ ] `phases.json`: Per-milestone phase breakdown — each phase lists its tickets, status counts, and whether the phase gate has passed
- [ ] `dependencies.json`: Dependency graph as an edge list `[{source, target}]` derived from `depends_on` fields

### Diagram Generation
- [ ] Generates Mermaid diagram definitions for per-milestone dependency graphs
- [ ] Writes to `dashboard/dist/data/diagrams/` as `.mmd` files (one per milestone)
- [ ] Nodes color-coded by status: green (DONE), yellow (IN_PROGRESS), grey (OPEN)
- [ ] Diagram renders correctly for milestones with 5–30 tickets

## Implementation Notes

- Use only Python standard library + `pyyaml` (or parse YAML frontmatter manually as the existing `milestone_status.py` does — see `parse_frontmatter()` in `tools/milestone_status.py` for the pattern)
- The existing `parse_frontmatter()` function in `tools/milestone_status.py` is a good reference but does not handle all YAML types (lists, nested objects). For `depends_on` and `blocks` fields, parse the `[TICKET-XXXX, TICKET-YYYY]` format
- Milestone counts in `milestones.md` are documentation — the build script should compute actual counts from ticket files for accuracy
- Keep the script simple — no web framework dependencies

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created ticket — data parser for dashboard build pipeline
