---
id: TICKET-0176
title: "Gameplay phase gate — regression test suite"
type: TASK
status: PENDING
priority: P1
owner: qa-engineer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "M8"
phase: "Gameplay"
depends_on: [TICKET-0153, TICKET-0167, TICKET-0168, TICKET-0169, TICKET-0170, TICKET-0171, TICKET-0172, TICKET-0173, TICKET-0174, TICKET-0175, TICKET-0180]
blocks: []
tags: [testing, phase-gate, regression, m8-gameplay]
---

## Summary

Run and certify the full regression test suite at the close of the M8 Gameplay phase. All Gameplay tickets must be DONE, all new unit tests passing, and all prior milestone tests still green before the QA phase opens.

## Acceptance Criteria

- [ ] All Gameplay tickets (TICKET-0153, TICKET-0167–0175, TICKET-0180) are DONE
- [ ] All new unit tests introduced in Gameplay pass
- [ ] Full test suite passes with zero failures (Foundation baseline + all new Gameplay tests)
- [ ] No cross-milestone regressions
- [ ] Full loop playtest completed: player can travel between all three biomes, mine resources, craft Fuel Cells, refuel, and travel again
- [ ] Test count and results documented in ticket activity log

## Implementation Notes

- Run headlessly: `godot --headless --path game res://addons/hammer_forge_tests/test_runner.tscn`
- Full loop playtest is manual — document pass/fail in activity log
- Gate PASS required before any QA phase ticket moves to IN_PROGRESS

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created — M8 Gameplay phase gate
