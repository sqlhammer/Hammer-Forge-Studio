---
id: TICKET-0076
title: "QA testing — M5 full loop"
type: TASK
status: OPEN
priority: P1
owner: qa-engineer
created_by: producer
created_at: 2026-02-24
updated_at: 2026-02-24
milestone: "M5"
milestone_gate: "M4"
phase: "QA"
depends_on: [TICKET-0075]
blocks: []
tags: [qa, testing, full-loop]
---

## Summary
QA Engineer runs the full M5 loop end-to-end, writes unit tests for all new M5 systems, and verifies the complete test suite passes with zero failures. This is the hard gate on M5 milestone close — QA sign-off is required before the Studio Head approves closure.

## Acceptance Criteria
- [ ] Unit tests written for: TechTree data layer, FabricatorModule, SpareBattery item, HeadLamp item, AutomationHubModule, DroneProgram, DroneAgent state machine
- [ ] Unit tests written for: minigame yield calculation, third-person scanner/mining input routing
- [ ] All new unit tests pass
- [ ] Full test suite passes with zero failures (all prior tests preserved — M1–M4 baseline of 284 must hold)
- [ ] Full loop verified end-to-end:
  - [ ] Mine Scrap Metal → Recycle → accumulate 100 Metal
  - [ ] Unlock Fabricator node in tech tree (resources deducted, node unlocks)
  - [ ] Install Fabricator in ship interior
  - [ ] Craft Spare Battery at Fabricator
  - [ ] Craft Head Lamp at Fabricator
  - [ ] Use Spare Battery in field (suit battery restores to 100%)
  - [ ] Toggle Head Lamp on and off (light activates, battery drains, toggles off)
  - [ ] Unlock Automation Hub node in tech tree
  - [ ] Install Automation Hub in ship interior
  - [ ] Configure and run a drone program against an analyzed deposit
  - [ ] Drone travels to deposit, extracts base yield, returns to ship
  - [ ] Mining minigame appears after Phase 2 analysis — successful trace awards +50% bonus
  - [ ] All scan/mine interactions work in third-person camera mode
- [ ] No regressions against M1–M4 systems
- [ ] QA sign-off posted in Activity Log with final test count

## Implementation Notes
- Run tests via `res://addons/hammer_forge_tests/test_runner.tscn` in editor, or headless for CI
- Unit tests live in `game/tests/` — one file per system, extending `TestSuite`
- Reference `game/addons/hammer_forge_tests/` for test framework
- If any acceptance criteria cannot be met, open a P1 BLOCKER ticket and page the Producer before marking this ticket DONE

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-24 [producer] Created ticket
