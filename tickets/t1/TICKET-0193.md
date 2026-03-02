---
id: TICKET-0193
title: "Milestone overview page — progress bars, ticket counts, phase gate status"
type: FEATURE
status: IN_PROGRESS
priority: P1
owner: systems-programmer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
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
- [ ] All milestones displayed (both M-series and T-series)
- [ ] Each milestone shows: ID, name, status badge (Complete/Active/Planning), total tickets, done tickets, completion percentage
- [ ] Visual progress bar for each milestone (filled proportional to completion %)
- [ ] Milestones grouped by status: Active first, then Planning, then Complete (collapsed by default)

### Phase Gate Status
- [ ] Each milestone card shows its phases with status indicators
- [ ] Phase status: passed (green check), in-progress (yellow dot), pending (grey dot)
- [ ] A phase is "passed" when all its tickets are DONE
- [ ] A phase is "in-progress" when at least one ticket is IN_PROGRESS or DONE but not all are DONE
- [ ] A phase is "pending" when no tickets have started

### Interaction
- [ ] Clicking a milestone card navigates to the per-milestone detail view (TICKET-0194)
- [ ] Active milestones are visually prominent (highlighted border or background)

### Data Accuracy
- [ ] Ticket counts computed from actual ticket data (not hardcoded from milestones.md)
- [ ] Completion percentage = (done / total) * 100, displayed as integer

## Implementation Notes

- Build on the scaffold from TICKET-0192 — add a rendering function to `app.js` that reads `milestones.json` and populates the overview section.
- Keep the layout card-based for quick scanning — avoid large tables for the overview.
- The phase gate computation can be done client-side from `phases.json` data.

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created ticket — milestone overview dashboard page
- 2026-03-01 [systems-programmer] Starting work — implementing milestone overview with progress bars, phase gate status, and grouped cards
