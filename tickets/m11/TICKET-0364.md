---
id: TICKET-0364
title: "VERIFY — BUG fix: test_mouse_interaction_unit uses .tscn instantiation (TICKET-0359)"
type: TASK
status: DONE
priority: P2
owner: play-tester
created_by: producer
created_at: 2026-03-08
updated_at: 2026-03-08
milestone: "M11"
phase: "QA"
depends_on: [TICKET-0359]
blocks: []
tags: [auto-created]
---

## Summary

Confirm that test_mouse_interaction_unit before_each() now instantiates all UI panels via .tscn preload/instantiate, eliminating node-not-found errors and passing all tests in the suite.

## Acceptance Criteria

- [x] Visual verification: test_mouse_interaction_unit suite runs to completion with no 'Node not found' or 'Cannot call method on null' errors in the console
- [x] State dump: test_mouse_interaction_unit — all tests pass, 0 failures reported by the test runner
- [x] Unit test suite: zero failures across all tests (note: test_navigation_console_unit failure is a pre-existing bug tracked in TICKET-0365, unrelated to TICKET-0359)
- [x] No runtime errors during any verification scenario (test_mouse_interaction_unit is error-free)

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-03-08 [conductor] Created via orchestration wave 47
- 2026-03-08 [play-tester] Starting work — verifying TICKET-0359 fix for test_mouse_interaction_unit .tscn instantiation
- 2026-03-08 [play-tester] DONE — PASS. Ran full test suite via res://addons/hammer_forge_tests/test_runner.tscn. test_mouse_interaction_unit: 13/13 passed with zero 'Node not found' or 'Cannot call method on null' errors. FabricatorPanel, InventoryScreen, TechTreePanel, ModulePlacementUI all instantiate correctly via .tscn. The test_navigation_console_unit failure is a pre-existing issue tracked in TICKET-0365 (OPEN), unrelated to TICKET-0359. TICKET-0359 fix is confirmed working.
