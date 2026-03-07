---
id: TICKET-0349
title: "BUG — test_inventory_action_popup_unit crashes test runner due to InventoryActionPopup standalone instantiation"
type: BUG
status: OPEN
priority: P2
owner: qa-engineer
created_by: play-tester
created_at: 2026-03-07
updated_at: 2026-03-07
milestone: "M11"
phase: "QA"
depends_on: []
blocks: []
tags: [bug, test, inventory, scene-first, regression]
---

## Summary

`test_inventory_action_popup_unit` crashes the test runner with an unhandled runtime
exception in `_test_show_for_slot_makes_visible`. This aborts all subsequent test suites.
The crash was introduced by TICKET-0293 which refactored `inventory_action_popup.gd` to
use `@onready` vars instead of programmatic construction — tests that instantiate via
`.new()` now receive null `@onready` nodes.

---

## Reproduction Steps

1. Launch `res://addons/hammer_forge_tests/test_runner.tscn`
2. Wait for the test runner to reach `test_inventory_action_popup_unit`
3. Observe runtime errors from `inventory_action_popup.gd:50` onward:
   `Node not found: "%Panel"` (and many others for @onready vars)
4. Observe fatal runtime error: `InventoryActionPopup._update_focus_visual:
   Invalid assignment of property or key 'text' with value of type 'String'
   on a base object of type 'null instance'`
5. Test runner aborts — all suites after `test_inventory_action_popup_unit` do not run

**Affected test:** `test_inventory_action_popup_unit.gd:81` — `_test_show_for_slot_makes_visible`

---

## Root Cause

`_test_show_for_slot_makes_visible` calls `InventoryActionPopup.new()` and `add_child()`
to instantiate the popup for testing. After TICKET-0293 refactored `inventory_action_popup.gd`
to use `@onready` vars sourced from `inventory_action_popup.tscn`, standalone instantiation
via `.new()` leaves all `@onready` vars null (no scene nodes are provided). When `show_for_slot()`
is called, it invokes `_update_focus_visual()` which tries to assign `.text` on null
`_indicator_labels[i]` — crashing the test runner.

---

## Fix Recommendation

Update `test_inventory_action_popup_unit` tests that require a live InventoryActionPopup
to instantiate via `load("res://scenes/ui/inventory_action_popup.tscn").instantiate()` instead
of `InventoryActionPopup.new()`. For tests that only need to check class metadata or signals,
use ClassDB (same approach as TICKET-0348 fix for test_dropped_item_unit).

---

## Evidence

Stack trace from test run (2026-03-07):
```
0 - res://scripts/ui/inventory_action_popup.gd:232 - _update_focus_visual
1 - res://scripts/ui/inventory_action_popup.gd:152 - show_for_slot
2 - res://tests/test_inventory_action_popup_unit.gd:81 - _test_show_for_slot_makes_visible
3 - res://addons/hammer_forge_tests/test_suite.gd:187 - _run_single_test
4 - res://addons/hammer_forge_tests/test_suite.gd:74 - run_all_tests
```

Suites confirmed passing before abort:
- test_debris_field_biome_unit: 25/25 (prior run)
- test_debug_launcher_unit: 6/6 (prior run)
- test_deep_resource_node_scene: 14/14 (prior run)
- test_deep_resource_node_unit: 27/27 (prior run)
- test_deposit_registry_unit: 17/17 (prior run)
- test_deposit_unit: 20/20 (prior run)
- test_drone_agent_unit: 15/15 (prior run)
- test_drone_program_unit: 10/10 (prior run)
- test_dropped_item_unit: passes (TICKET-0348 fix applied)
- test_fabricator_unit: unknown
- test_fuel_system_unit: 44/44 ✓
- test_game_startup_unit: 20/20 ✓
- test_game_world_unit: 14/14 ✓
- test_head_lamp_unit: 17/17 ✓
- test_input_manager_unit: 11/11 ✓
- test_interaction_prompt_hud_unit: 7/7 ✓
- test_inventory_action_popup_unit: CRASH (this ticket)

Suites NOT run due to abort: test_inventory_screen_unit and all subsequent suites.

---

## Activity Log

- 2026-03-07 [play-tester] Created during TICKET-0322 verification. Regression introduced
  by TICKET-0293 (scene-first refactor of inventory_action_popup.gd). test_inventory_action_popup_unit
  crashes on InventoryActionPopup.new() outside scene context — @onready vars null,
  _update_focus_visual() crashes on null _indicator_labels. Similar fix to TICKET-0348.
