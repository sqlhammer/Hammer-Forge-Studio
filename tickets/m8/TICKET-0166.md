---
id: TICKET-0166
title: "Foundation phase gate — regression test suite"
type: TASK
status: PENDING
priority: P1
owner: qa-engineer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "M8"
phase: "Foundation"
depends_on: [TICKET-0157, TICKET-0158, TICKET-0159, TICKET-0160, TICKET-0161, TICKET-0162, TICKET-0163, TICKET-0164, TICKET-0165, TICKET-0179]
blocks: []
tags: [testing, phase-gate, regression, m8-foundation]
---

## Summary

Run and certify the full regression test suite at the close of the M8 Foundation phase. All Foundation tickets must be DONE, all new unit tests passing, and all prior milestone tests still green before the Gameplay phase opens.

## Acceptance Criteria

- [ ] All Foundation tickets (TICKET-0157 through TICKET-0166, TICKET-0179) are DONE
- [ ] All new unit tests introduced in Foundation pass (Cryonite, Fuel system, Navigation system, Deep node, Respawn system, World boundary)
- [ ] Full test suite passes with zero failures (M7 baseline of 480 tests + all new M8 Foundation tests)
- [ ] No cross-milestone regressions (M7 and earlier test suites unaffected)
- [ ] Test count and results documented in ticket activity log
- [ ] UI/UX designs reviewed and confirmed complete (TICKET-0165)

## Implementation Notes

- Run headlessly: `godot --headless --path game res://addons/hammer_forge_tests/test_runner.tscn`
- Document total test count and breakdown per suite in the activity log
- Gate PASS required before any Gameplay phase ticket moves to IN_PROGRESS

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created — M8 Foundation phase gate
