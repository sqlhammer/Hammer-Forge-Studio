---
id: TICKET-0374
title: "BUG — test_ship_interior_unit crashes in-editor at ship_interior.gd:217: null marker in _update_zone_visual"
type: BUG
status: OPEN
priority: P2
owner: systems-programmer
created_by: play-tester
created_at: 2026-03-08
updated_at: 2026-03-08
milestone: "M11"
phase: "QA"
depends_on: []
blocks: []
tags: [test-failure, in-editor, ship-interior, rendering]
---

## Summary

After the TICKET-0372 null-guard fix in `ShipInterior._ready()`, the in-editor test run now
progresses past the line 71 crash but halts at `ship_interior.gd:217` in `_update_zone_visual`
with `Invalid access to property or key 'material_override' on a base object of type 'null
instance'`. The Godot debugger breaks execution, preventing the test suite from completing.

## Severity

P2 — Breaks in-editor test suite execution for test_ship_interior_unit. Headless workaround
likely still available (not confirmed post-fix). Discovered during TICKET-0373 verification.

## Reproduction Steps

1. Open the Godot editor for this project
2. Open `res://addons/hammer_forge_tests/test_runner.tscn`
3. Play the scene (in-editor, not headless)
4. Observe the debugger break:
   `Invalid access to property or key 'material_override' on a base object of type 'null instance'.`
5. Stack trace:
   - `ship_interior.gd:217 @ _update_zone_visual`
   - `ship_interior.gd:140 @ place_module_in_zone`
   - `test_ship_interior_unit.gd:76 @ _test_place_module_in_zone_0_marks_occupied`
   - `test_suite.gd:187 @ _run_single_test`

## Root Cause (Analysis)

`_zone_floor_markers` is pre-initialized as an Array of size 4, but its entries are `null`
because the `ZoneMarker_0` through `ZoneMarker_3` nodes are not found during `@onready`
assignment (the nodes don't exist when the script is instantiated via `.new()` in tests or the
editor play context without the full ShipInterior scene tree).

`_update_zone_visual` (line 213–223) checks `zone_index >= _zone_floor_markers.size()` (line 214)
which passes because the array has size 4, but does NOT check whether
`_zone_floor_markers[zone_index]` is null before accessing `.material_override` at line 217.

Before TICKET-0372, this function was never reached in-editor because the test crashed at
`ship_interior.gd:71` first. The line 71 null guard now allows tests to proceed further, exposing
this secondary null dereference.

## Expected Behavior

`_update_zone_visual` should guard against null entries in `_zone_floor_markers` and return
early (or skip the visual update) rather than crashing. Tests that call `place_module_in_zone`
should complete without halting the debugger.

## Actual Behavior

`_update_zone_visual` crashes at line 217 because `marker` is null. Debugger halts in-editor.
The in-editor test suite cannot complete.

## Evidence

- Editor screenshot captured during TICKET-0373 verification (2026-03-08): Godot debugger
  panel shows halt at `ship_interior.gd:217`, error message confirmed, Locals panel shows
  `marker: <null>` and `mat: <null>`, Members panel shows `_zone_floor_markers: Array (size 4)`.
- Runtime error log: `ShipInterior._update_zone_visual: Invalid access to property or key
  'material_override' on a base object of type 'null instance'.`
- Stack trace confirms test `_test_place_module_in_zone_0_marks_occupied` triggered the crash.

## Fix Suggestion

Add a null guard for `marker` in `_update_zone_visual` after line 216 (before accessing
`marker.material_override`):

```gdscript
var marker: MeshInstance3D = _zone_floor_markers[zone_index]
if not marker:
    return
```

## Activity Log

- 2026-03-08 [play-tester] Discovered during TICKET-0373 in-editor verification. The TICKET-0372
  fix correctly eliminated the line 71 crash, but exposed a pre-existing null dereference at
  line 217. Filed as P2 — same severity as TICKET-0372.
