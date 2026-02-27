---
id: TICKET-0198
title: "QA testing — dashboard validation and sign-off"
type: TASK
status: OPEN
priority: P1
owner: qa-engineer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "T1"
phase: "QA"
depends_on: [TICKET-0197]
blocks: []
tags: [tooling, dashboard, qa, testing, sign-off]
---

## Summary

Validate the deployed dashboard against the project's actual data. Verify all milestone counts, ticket statuses, diagrams, and auto-update behavior. Provide QA sign-off for T1 milestone close.

## Acceptance Criteria

### Data Accuracy
- [ ] Dashboard milestone counts match actual ticket file counts in the repo (spot-check at least M8, M9, T1)
- [ ] Ticket statuses on the dashboard match the `status` field in each ticket's frontmatter
- [ ] Phase gate status indicators are correct (compare against manual phase review)
- [ ] Completion percentages are mathematically correct

### Diagram Validation
- [ ] All auto-generated dependency graphs render without Mermaid errors
- [ ] Dependency edges match the `depends_on` fields in ticket frontmatter (spot-check 5+ tickets)
- [ ] Architecture and game loop diagrams render correctly and are factually accurate
- [ ] No broken or unreadable diagrams

### Auto-Update Verification
- [ ] Push a test change to `main` (e.g., update a ticket status)
- [ ] Verify the GitHub Actions workflow triggers and completes successfully
- [ ] Verify the dashboard reflects the change after deployment (within 5 minutes of push)

### Cross-Browser
- [ ] Dashboard loads and renders correctly in Chrome (latest)
- [ ] Dashboard loads and renders correctly in Firefox (latest)
- [ ] No JavaScript console errors on page load in either browser

### Edge Cases
- [ ] Dashboard handles milestones with 0 tickets (M10–M15 have no ticket files yet)
- [ ] Dashboard handles completed milestones with archived tickets (M1–M7 tickets are in `_archive/`)
- [ ] Long ticket titles display correctly (no overflow or layout breakage)

## Implementation Notes

- QA sign-off is the final gate for T1 milestone close. All acceptance criteria must pass.
- Since T1 is a tooling milestone (not game code), the "full test suite passes" gate condition from the Phase Gate Checklist refers to dashboard-specific validation, not the Godot game test suite.
- Cross-browser testing can be done manually — no automated browser testing framework is required for T1.

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created ticket — QA testing and sign-off for T1
