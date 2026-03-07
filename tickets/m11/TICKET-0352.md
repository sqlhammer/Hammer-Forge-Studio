---
id: TICKET-0352
title: "BUG — InventoryActionPopup test suite crashes test_runner: _update_focus_visual null instance error"
type: BUG
status: DONE
priority: P2
owner: gameplay-programmer
created_by: play-tester
created_at: 2026-03-07
updated_at: 2026-03-07
milestone: "M11"
phase: "QA"
depends_on: []
blocks: []
tags: [inventory, test-suite, regression, m11]
---

## Summary

`test_inventory_action_popup_unit` causes a fatal runtime error when the test runner
executes `_test_show_for_slot_makes_visible`, crashing the test runner and preventing
all subsequent test suites (including `test_tech_tree_unit`) from running.

---

## Severity

**P2 — Test suite cannot complete**: The crash blocks QA milestone sign-off because
the full test suite cannot run to completion. Suites running before
`test_inventory_action_popup_unit` (alphabetically) complete normally; all suites after
it are skipped.

---

## Regression Source

**TICKET-0308** attempted to fix 13 test failures in `test_inventory_action_popup_unit`
and was marked DONE, but the fix is incomplete. The test still crashes at
`_test_show_for_slot_makes_visible` with a null instance error.

---

## Reproduction Steps

1. Launch the Godot editor with the Hammer Forge project open
2. Open and play `res://addons/hammer_forge_tests/test_runner.tscn`
3. Observe: test suites run in alphabetical order — fabricator, fuel_gauge, fuel_system,
   game_startup, game_world, head_lamp, input_manager, interaction_prompt_hud all pass
4. Observe: `test_inventory_action_popup_unit` suite starts running
5. Observe: a fatal runtime error fires at `_test_show_for_slot_makes_visible`
6. Observe: test runner hangs/crashes — no further test suites complete

---

## Expected Behavior

`test_inventory_action_popup_unit` should run all its tests and report pass/fail counts.
The test runner should continue to the next suite.

---

## Actual Behavior

Runtime error fires:
```
InventoryActionPopup._update_focus_visual: Invalid assignment of property or key 'text'
with value of type 'String' on a base object of type 'null instance'.
```

Stack trace:
```
0 - res://scripts/ui/inventory_action_popup.gd:232 - _update_focus_visual
1 - res://scripts/ui/inventory_action_popup.gd:152 - show_for_slot
2 - res://tests/test_inventory_action_popup_unit.gd:81 - _test_show_for_slot_makes_visible
3 - res://addons/hammer_forge_tests/test_suite.gd:187 - _run_single_test
4 - res://addons/hammer_forge_tests/test_suite.gd:74 - run_all_tests
5 - res://addons/hammer_forge_tests/test_runner.gd:96 - _run_suite_from_path
6 - res://addons/hammer_forge_tests/test_runner.gd:43 - run_all_suites
7 - res://addons/hammer_forge_tests/test_runner.gd:27 - _ready
```

The error is in `_update_focus_visual` (line 232) trying to set `.text` on a null
label node. This null label is the result of `InventoryActionPopup` being instantiated
without its scene tree (node not found errors at lines 50-61 also appear), causing
`@onready` vars to remain null.

---

## Files Involved

- `game/scripts/ui/inventory_action_popup.gd` — line 232 (`_update_focus_visual`)
- `game/tests/test_inventory_action_popup_unit.gd` — line 81 (`_test_show_for_slot_makes_visible`)

---

## Activity Log

- 2026-03-07 [play-tester] Filed — discovered during TICKET-0334 verification run. TICKET-0308 fix was marked DONE but the crash persists. Test runner cannot complete the full suite, blocking QA sign-off.
- 2026-03-07 [gameplay-programmer] Starting work. Root cause: InventoryActionPopup.new() bypasses scene tree, leaving @onready vars null. Fix: instantiate from .tscn instead.
- 2026-03-07 [gameplay-programmer] DONE. Commit: 7a34a58. PR: https://github.com/sqlhammer/Hammer-Forge-Studio/pull/381
