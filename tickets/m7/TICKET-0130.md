---
id: TICKET-0130
title: "QA testing — M7 full loop"
type: TASK
status: TODO
priority: P0
owner: qa-engineer
created_by: producer
created_at: 2026-02-26
updated_at: 2026-02-26
milestone: "M7"
phase: "QA"
depends_on: [TICKET-0129]
blocks: []
tags: [qa, testing, full-loop, milestone-close]
---

## Summary

Final QA pass for M7. Run the full test suite and perform manual testing of all M7 deliverables. This is the QA gate for milestone close — must pass before Studio Head final sign-off.

## Test Scope

### Automated Tests
- Run full test suite via `res://addons/hammer_forge_tests/test_runner.tscn`
- All tests from M1–M7 must pass with zero failures
- Document total test count and pass rate

### Manual Testing — Ship Interior
- [ ] Player can enter the ship from exterior (fade transition works)
- [ ] Player spawns in the entry vestibule facing into the ship
- [ ] Player can walk through vestibule → machine room → corridor → cockpit without collision issues
- [ ] Walking clearance is comfortable — no tight squeezes or stuck points
- [ ] Player can exit the ship from the vestibule (fade transition works)
- [ ] Ship globals HUD activates on entry, deactivates on exit

### Manual Testing — Machine Room
- [ ] All 4 module zones visible with floor markings
- [ ] Recycler, Fabricator, Automation Hub placed in their zones and interactable
- [ ] Spare zone shows empty zone marking and install prompt
- [ ] Module catalog/install mechanic works on the spare zone
- [ ] All machine interaction panels open and function correctly

### Manual Testing — Cockpit
- [ ] Navigation console is placed and visible (non-functional is expected)
- [ ] Diegetic status displays show all 4 ship globals (Power, Integrity, Heat, O2)
- [ ] Status displays update in real-time when ship globals change
- [ ] Viewport/window is visible and reads as showing the exterior
- [ ] Player can comfortably navigate the cockpit space

### Manual Testing — Refactored Scenes
- [ ] Ship exterior loads correctly as instanced scene in the test world
- [ ] Resource deposits spawn and function correctly (scan, mine)
- [ ] All machine panels and HUD elements render correctly
- [ ] Tools (Hand Drill, Scanner) function correctly
- [ ] Carriable items (Spare Battery, Head Lamp) function correctly
- [ ] Mining drones function correctly

### Manual Testing — New Features
- [ ] Interaction prompt HUD appears when aiming at interactable objects
- [ ] Prompt hides when not aiming at interactable objects
- [ ] Hold actions show thicker key badge border
- [ ] Persistent controls panel visible in bottom-right (Q Ping, I Inventory)
- [ ] Battery bar shows amber warning tier at intermediate battery levels

## Acceptance Criteria

- [ ] Full automated test suite passes with zero failures
- [ ] All manual test items above verified
- [ ] Any failures documented as BUGFIX tickets
- [ ] QA report posted in this ticket's Activity Log
- [ ] Studio Head sign-off obtained (hard gate)

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-26 [producer] Created ticket — M7 full loop QA
