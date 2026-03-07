---
id: TICKET-0348
title: "BUG — test_dropped_item_unit crashes test runner due to InventoryScreen standalone instantiation"
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
tags: [test-suite, inventory-screen, dropped-item, unit-test, pre-existing]
---

## Summary

The `test_dropped_item_unit` test suite crashes the test runner with an unhandled runtime
exception in `_test_inventory_screen_drop_signal_defined`. This aborts all subsequent test
suites, preventing a full unit test run. The crash predates TICKET-0318 — confirmed by git
log showing `inventory_screen.gd` was last modified by TICKET-0308, and `test_dropped_item_unit.gd`
was last modified by TICKET-0218.

---

## Reproduction Steps

1. Launch `res://addons/hammer_forge_tests/test_runner.tscn`
2. Wait for the test runner to reach `test_dropped_item_unit`
3. Observe runtime errors from `inventory_screen.gd:52` onward:
   `Node not found: "%DimRect"` (and many others)
4. Observe fatal runtime error: `InventoryScreen._connect_signals: Invalid access to property
   or key 'mouse_entered' on a base object of type 'null instance'`
5. Test runner aborts — all suites after `test_dropped_item_unit` do not run

**Affected test:** `test_dropped_item_unit.gd:207` — `_test_inventory_screen_drop_signal_defined`

---

## Root Cause

`_test_inventory_screen_drop_signal_defined` calls `InventoryScreen.new()` and `add_child(screen)`
to verify the `item_drop_requested` signal exists. `InventoryScreen._ready()` calls
`_connect_signals()` which accesses `@onready` nodes via `%` unique names (e.g., `%DimRect`,
`%MainPanel`, etc.). These nodes only exist when InventoryScreen is instantiated from its
proper `.tscn` scene file — not when instantiated standalone via `InventoryScreen.new()`.

The test was written when InventoryScreen was simpler. TICKET-0308 added `@onready` node
references and signal wiring that now fail when the class is instantiated without its scene.

---

## Expected Behavior

The test should verify that `InventoryScreen` has the `item_drop_requested` signal without
crashing. The test runner should complete all suites with pass/fail counts reported.

## Actual Behavior

`InventoryScreen._connect_signals` throws an unhandled exception when accessing `mouse_entered`
on a null instance, crashing the test runner mid-suite. All subsequent test suites are skipped.

---

## Fix Approach

Either:
1. Update `_test_inventory_screen_drop_signal_defined` to verify the signal without
   instantiating a full InventoryScreen (e.g., use `InventoryScreen` class metadata or
   check signal definitions via `ClassDB`), OR
2. Instantiate InventoryScreen from its `.tscn` scene file rather than via `.new()`

---

## Evidence

From test runner output during TICKET-0346 verification:
```
inventory_screen.gd:52 @ @implicit_ready(): Node not found: "%DimRect"
...
InventoryScreen._connect_signals: Invalid access to property or key 'mouse_entered'
  on a base object of type 'null instance'.
Stack trace:
  0 - inventory_screen.gd:335 - _connect_signals
  1 - inventory_screen.gd:76 - _ready
  2 - test_dropped_item_unit.gd:207 - _test_inventory_screen_drop_signal_defined
```

Suites completed before abort:
- test_debris_field_biome_unit: 25/25 ✓
- test_debug_launcher_unit: 6/6 ✓
- test_deep_resource_node_scene: 14/14 ✓
- test_deep_resource_node_unit: 27/27 ✓
- test_deposit_registry_unit: 17/17 ✓
- test_deposit_unit: 20/20 ✓
- test_drone_agent_unit: 15/15 ✓
- test_drone_program_unit: 10/10 ✓

Suites NOT run due to abort: test_dropped_item_unit (partial), test_fabricator_unit,
test_fuel_system_unit, test_game_startup_unit, test_game_world_unit, and all subsequent.

---

## Activity Log

- 2026-03-07 [play-tester] Created during TICKET-0346 verification. Pre-existing crash
  confirmed: inventory_screen.gd last changed TICKET-0308, test_dropped_item_unit.gd last
  changed TICKET-0218. Not caused by TICKET-0318 (which only modified game_world.gd).
