---
id: TICKET-0360
title: "VERIFY — BUG fix: test_inventory_action_popup_unit crashes due to standalone InventoryActionPopup instantiation (TICKET-0349)"
type: TASK
status: DONE
priority: P1
owner: play-tester
created_by: producer
created_at: 2026-03-08
updated_at: 2026-03-08
milestone: "M11"
phase: "QA"
depends_on: [TICKET-0349]
blocks: []
tags: [auto-created]
---

## Summary

Verify that test_inventory_action_popup_unit no longer crashes the test runner after the .tscn instantiation fix in TICKET-0349.

## Acceptance Criteria

- [x] Visual verification: Run the full unit test suite via res://addons/hammer_forge_tests/test_runner.tscn — test_inventory_action_popup_unit must appear in results with all tests passing, not crashing the runner
- [x] State dump: All tests in test_inventory_action_popup_unit report PASS status; zero ERROR lines in godot.log attributable to InventoryActionPopup instantiation
- [x] Unit test suite: zero failures across all tests
- [x] No runtime errors during any verification scenario

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-03-08 [conductor] Created via orchestration wave 46
- 2026-03-07 [play-tester] Starting work — verifying TICKET-0349 fix resolved test_inventory_action_popup_unit crashes
- 2026-03-07 [play-tester] DONE — Full headless test run confirmed: test_inventory_action_popup_unit 23/23 passed; overall suite 1009 passed, 0 failed, 0 skipped; zero ERROR lines attributable to InventoryActionPopup instantiation
