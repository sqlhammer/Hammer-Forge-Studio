---
id: TICKET-0354
title: "BUG — test_inventory_screen_popup_unit crashes test runner (InventoryScreen.new() leaves @onready vars null)"
type: BUG
status: DONE
priority: P2
owner: qa-engineer
created_by: play-tester
created_at: 2026-03-07
updated_at: 2026-03-07
milestone: "M11"
phase: "QA"
depends_on: []
blocks: []
tags: [bug, test, inventory-screen, scene-first, regression]
---

## Summary

`test_inventory_screen_popup_unit` crashes the test runner with an unhandled runtime
exception in `before_each`. This aborts all subsequent test suites, preventing
`test_mouse_interaction_unit`, `test_tech_tree_unit`, and all following suites from running.

---

## Reproduction Steps

1. Launch `res://addons/hammer_forge_tests/test_runner.tscn`
2. Wait for the test runner to reach `test_inventory_screen_popup_unit`
3. Observe runtime errors from `inventory_screen.gd:52` onward:
   `Node not found: "%DimRect"` (and many others for @onready vars)
4. Observe fatal runtime error at `inventory_screen.gd:335 @ _connect_signals`:
   `Invalid access to property or key 'mouse_entered' on a base object of type 'null instance'`
5. Test runner aborts — all suites after `test_inventory_screen_popup_unit` do not run

---

## Root Cause

`test_inventory_screen_popup_unit.gd:18` calls `InventoryScreen.new()` + `add_child()` in
`before_each`. After the scene-first remediation of `inventory_screen.gd`, all UI nodes are
sourced from `inventory_screen.tscn` via `@onready` vars. Standalone instantiation via
`.new()` leaves all `@onready` vars null. When `_connect_signals()` is called from `_ready()`,
it tries to call `.mouse_entered.connect()` on null slot panel nodes — crashing the runner.

This is the same pattern fixed for `InventoryActionPopup` in TICKET-0352.

---

## Fix Recommendation

Update `test_inventory_screen_popup_unit.gd` — replace:
```gdscript
_inventory_screen = InventoryScreen.new()
add_child(_inventory_screen)
```
with:
```gdscript
_inventory_screen = load("res://scenes/ui/inventory_screen.tscn").instantiate()
add_child(_inventory_screen)
```
Apply the same fix to `InventoryActionPopup` instantiation within the same test file if any
exist. This matches the fix applied in TICKET-0352 for `test_inventory_action_popup_unit`.

---

## Expected Behavior

`test_inventory_screen_popup_unit` should complete without crashing the test runner, allowing
all subsequent test suites (test_mouse_interaction_unit, test_tech_tree_unit, etc.) to run.

---

## Actual Behavior

Test runner crashes at `test_inventory_screen_popup_unit:18` (before_each), aborting the run.
All suites alphabetically after this file do not execute.

---

## Evidence

Stack trace from TICKET-0324 verification run (2026-03-07):
```
0 - res://scripts/ui/inventory_screen.gd:335 - at function: _connect_signals
1 - res://scripts/ui/inventory_screen.gd:76 - at function: _ready
2 - res://tests/test_inventory_screen_popup_unit.gd:18 - at function: before_each
3 - res://addons/hammer_forge_tests/test_suite.gd:186 - at function: _run_single_test
4 - res://addons/hammer_forge_tests/test_suite.gd:74 - at function: run_all_tests
5 - res://addons/hammer_forge_tests/test_runner.gd:96 - at function: _run_suite_from_path
6 - res://addons/hammer_forge_tests/test_runner.gd:43 - at function: run_all_suites
7 - res://addons/hammer_forge_tests/test_runner.gd:27 - at function: _ready
```

Suites confirmed passing before abort (2026-03-07):
- test_game_world_unit: 14/14 ✓
- test_head_lamp_unit: 17/17 ✓
- test_input_manager_unit: 11/11 ✓
- test_interaction_prompt_hud_unit: 7/7 ✓
- test_inventory_action_popup_unit: 23/23 ✓
- test_inventory_screen_popup_unit: CRASH (this ticket)

Suites NOT run due to abort: test_inventory_screen_unit, test_module_manager_unit,
test_mouse_interaction_unit, test_tech_tree_unit, and all subsequent suites.

---

## Handoff Notes

(Leave blank until handoff occurs.)

---

## Activity Log

- 2026-03-07 [play-tester] Created during TICKET-0324 verification. Same root cause and fix
  pattern as TICKET-0349/TICKET-0352 (InventoryActionPopup). InventoryScreen.new() leaves
  @onready vars null after scene-first remediation — _connect_signals crashes on null slot
  panel nodes. Fix: instantiate from inventory_screen.tscn instead of .new().
- 2026-03-07 [qa-engineer] Starting work — replacing InventoryScreen.new() with load().instantiate() in test_inventory_screen_popup_unit.gd before_each, matching fix from TICKET-0352.
- 2026-03-07 [qa-engineer] Fix applied: replaced `InventoryScreen.new()` with `load("res://scenes/ui/inventory_screen.tscn").instantiate()` in before_each. Full test suite run headless: 1009/1009 passed, 0 failed (test_report_2026-03-08 01-17-07.json). test_inventory_screen_popup_unit: 14/14 passed without crash. All subsequent suites (test_inventory_unit, test_module_manager_unit, test_mouse_interaction_unit, test_tech_tree_unit, test_travel_sequence_unit, test_world_boundary_unit) confirmed running and passing. Ticket DONE.
