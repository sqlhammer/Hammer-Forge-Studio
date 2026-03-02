---
id: TICKET-0193
title: "Milestone overview page — progress bars, ticket counts, phase gate status"
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
tags: [tooling, dashboard, milestone-overview, visualization]
---

## Summary

Build the main dashboard landing page that shows all milestones at a glance with progress bars, ticket counts, and phase gate status indicators.

## Acceptance Criteria

### Milestone Cards
- [x] All milestones displayed (both M-series and T-series)
- [x] Each milestone shows: ID, name, status badge (Complete/Active/Planning), total tickets, done tickets, completion percentage
- [x] Visual progress bar for each milestone (filled proportional to completion %)
- [x] Milestones grouped by status: Active first, then Planning, then Complete (collapsed by default)

### Phase Gate Status
- [x] Each milestone card shows its phases with status indicators
- [x] Phase status: passed (green check), in-progress (yellow dot), pending (grey dot)
- [x] A phase is "passed" when all its tickets are DONE
- [x] A phase is "in-progress" when at least one ticket is IN_PROGRESS or DONE but not all are DONE
- [x] A phase is "pending" when no tickets have started

### Interaction
- [x] Clicking a milestone card navigates to the per-milestone detail view (TICKET-0194)
- [x] Active milestones are visually prominent (highlighted border or background)

### Data Accuracy
- [x] Ticket counts computed from actual ticket data (not hardcoded from milestones.md)
- [x] Completion percentage = (done / total) * 100, displayed as integer

## Implementation Notes

- Build on the scaffold from TICKET-0192 — add a rendering function to `app.js` that reads `milestones.json` and populates the overview section.
- Keep the layout card-based for quick scanning — avoid large tables for the overview.
- The phase gate computation can be done client-side from `phases.json` data.

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created ticket — milestone overview dashboard page
- 2026-03-01 [systems-programmer] Starting work — implementing milestone overview with progress bars, phase gate status, and grouped cards
- 2026-03-01 [systems-programmer] Completed — commit b67e285, PR https://github.com/sqlhammer/Hammer-Forge-Studio/pull/242 (merged)
