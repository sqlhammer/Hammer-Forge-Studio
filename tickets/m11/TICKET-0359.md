---
id: TICKET-0359
title: "BUG — test_mouse_interaction_unit fails: FabricatorPanel instantiated with .new() instead of .tscn"
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
tags: [test, mouse-interaction, fabricator-panel, regression, m11]
---

## Summary

`test_mouse_interaction_unit` fails for every test in the suite. `before_each` instantiates
`FabricatorPanel` (and `InventoryScreen`, `TechTreePanel`, `ModulePlacementUI`) using `.new()`,
which triggers `_ready` before the UI nodes exist in the scene hierarchy. This causes
`get_node()` to return null for all percent-sign node references, and
`add_theme_stylebox_override` to fail on a null value.

This is the same pattern as `test_inventory_screen_popup_unit` which was fixed in TICKET-0354.

---

## Severity

**P2 — Test failures prevent zero-failure gate**: All tests in the suite fail. The suite
is not producing useful signal. The test runner continues past this suite (it does not hang),
but it introduces noise into the test results.

---

## Regression Source

`test_mouse_interaction_unit.gd` was introduced in TICKET-0153 using the `.new()` pattern
for all four UI panels. The fix pattern is `.tscn` instantiation (see TICKET-0354).

---

## Reproduction Steps

1. Run the full unit test suite: `res://addons/hammer_forge_tests/test_runner.tscn`
2. Observe errors after test_module_manager_unit completes:
   ```
   ERROR: Node not found: "%DimRect" (relative to "/root/TestRunner/@Node@667/@CanvasLayer@668")
   ERROR: Cannot call method 'add_theme_stylebox_override' on a null value.
     at: FabricatorPanel._apply_styles (res://scripts/ui/fabricator_panel.gd:169)
     GDScript backtrace:
       [0] _apply_styles (fabricator_panel.gd:169)
       [1] _ready (fabricator_panel.gd:74)
       [2] before_each (test_mouse_interaction_unit.gd:21)
   ```
3. Every test in test_mouse_interaction_unit produces this error pattern

---

## Expected Behavior

`before_each` instantiates each UI panel from its `.tscn` scene file (using
`preload("res://...").instantiate()`), which ensures the full node hierarchy is
present before `_ready` fires.

## Actual Behavior

UI panels are instantiated with `.new()`, causing all `@export` node references and
percent-sign node paths to be null, leading to cascading errors in `_ready`.

---

## Suggested Fix

In `test_mouse_interaction_unit.gd`, change `before_each()` to use `.tscn` instantiation,
following the same pattern as the fix in TICKET-0354:

```gdscript
func before_each() -> void:
    var inventory_scene = preload("res://scenes/ui/inventory_screen.tscn")
    _inventory_screen = inventory_scene.instantiate() as InventoryScreen
    add_child(_inventory_screen)
    # ...etc for fabricator, tech_tree, module_placement
```

---

## Files Involved

- `game/tests/test_mouse_interaction_unit.gd` — `before_each()` uses `.new()` pattern

---

## Evidence

Discovered during TICKET-0338 (VERIFY compass_bar fix). godot.log from test run shows
every test in the suite generating ~30 error lines:
```
[25542] --- Suite: test_module_manager_unit --- 25/25 passed
ERROR: Node not found: "%DimRect" (relative to "/root/TestRunner/@Node@667/@CanvasLayer@668").
   at: get_node (scene/main/node.cpp:1907)
   GDScript backtrace: [0] @implicit_ready (inventory_screen.gd:52) [1] before_each (test_mouse_interaction_unit.gd:19)
...
SCRIPT ERROR: Cannot call method 'add_theme_stylebox_override' on a null value.
   at: FabricatorPanel._apply_styles (fabricator_panel.gd:169)
   GDScript backtrace: [0] _apply_styles (fabricator_panel.gd:169) [1] _ready (fabricator_panel.gd:74) [2] before_each (test_mouse_interaction_unit.gd:21)
```

---

## Activity Log

- 2026-03-07 [play-tester] Filed — P2 pre-existing test failure discovered during TICKET-0338 verification. Every test in test_mouse_interaction_unit fails with node-not-found errors due to .new() instantiation pattern. Fix: use .tscn instantiation per TICKET-0354 pattern. Owner: qa-engineer.
