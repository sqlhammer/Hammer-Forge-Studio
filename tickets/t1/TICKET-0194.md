---
id: TICKET-0194
title: "Ticket detail views — per-milestone tables with status, owner, dependencies"
type: FEATURE
status: DONE
priority: P1
owner: systems-programmer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-03-01
milestone: "T1"
phase: "Dashboard"
depends_on: [TICKET-0192]
blocks: []
tags: [tooling, dashboard, ticket-details, tables]
---

## Summary

Build per-milestone detail views that display all tickets in a structured table with status badges, owner, phase grouping, and dependency links.

## Acceptance Criteria

### Ticket Table
- [x] Per-milestone section accessible from the milestone overview (TICKET-0193)
- [x] Table columns: Ticket ID, Title, Status, Owner, Phase, Dependencies
- [x] Status badges color-coded: green (DONE), yellow (IN_PROGRESS), grey (OPEN)
- [x] Rows grouped by phase (phase name as a section header above its tickets)
- [x] Tickets sorted by ID within each phase group

### Summary Header
- [x] Milestone name, status, and description at top of detail view
- [x] Ticket counts: total, done, in-progress, open
- [x] Completion progress bar matching the overview card

### Dependency Links
- [x] Dependency column shows ticket IDs from the `depends_on` field
- [x] Dependency ticket IDs are clickable — scroll to / highlight the referenced ticket row
- [x] Dependencies from other milestones shown with milestone prefix (e.g., "M8: TICKET-0162")

### Edge Cases
- [x] Milestones with 0 tickets show "No tickets found" message
- [x] Long ticket titles truncated with ellipsis (hover shows full title)
- [x] Archived milestones (Complete status) render correctly with all-DONE tickets

## Implementation Notes

- Build on the scaffold from TICKET-0192 — add a rendering function to `app.js` that reads `tickets.json` and `phases.json`.
- Cross-milestone dependency display: if a ticket depends on a ticket from another milestone, show the milestone ID prefix for context.
- Consider using HTML `<details>` elements for phase groups so users can collapse completed phases.

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created ticket — per-milestone ticket detail views
- 2026-03-01 [systems-programmer] Starting work — implementing per-milestone ticket detail views with phase grouping, status badges, and dependency links
- 2026-03-01 [systems-programmer] Completed — commit 215f4b5, PR https://github.com/sqlhammer/Hammer-Forge-Studio/pull/247 (merged)
