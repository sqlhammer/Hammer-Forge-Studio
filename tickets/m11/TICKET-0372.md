---
id: TICKET-0372
title: "BUG — test_ship_interior_unit fails in-editor: null material_override in ShipInterior._ready"
type: BUG
status: OPEN
priority: P2
owner: systems-programmer
created_by: qa-engineer
created_at: 2026-03-08
updated_at: 2026-03-08
milestone: "M11"
phase: "QA"
depends_on: []
blocks: []
tags: [test-failure, in-editor, ship-interior, rendering]
---

## Summary

`test_ship_interior_unit` triggers a runtime error in-editor when the test runner plays
`test_runner.tscn`. `ShipInterior._ready` fails with
`Invalid access to property or key 'material_override' on a base object of type 'null instance'`
at `ship_interior.gd:71`. This halts the in-editor test run. Headless runs are unaffected — all
1009 tests pass headless.

## Severity

P2 — Breaks in-editor test suite execution for any test that instantiates ShipInterior. Workaround
is to run headless (`godot --headless`), which passes 1009/1009 with zero failures.

## Reproduction Steps

1. Open the Godot editor for this project
2. Open `res://addons/hammer_forge_tests/test_runner.tscn`
3. Play the scene (in-editor, not headless)
4. Observe the debugger break on:
   `Invalid access to property or key 'material_override' on a base object of type 'null instance'.`
5. Runtime stack trace:
   - `ship_interior.gd:71 @ _ready`
   - `test_ship_interior_unit.gd:15 @ before_each`
   - `test_suite.gd:186 @ _run_single_test`

## Root Cause (Analysis)

`ship_interior.gd:71` accesses `_viewport_window.material_override` where `_viewport_window` is
`null` when the scene is instantiated in the editor play context. The SubViewport or its parent
node is not properly initialized before `_ready` runs in editor mode, unlike headless mode where
the property access may succeed (or SubViewport renders differently without a display server).

## Expected Behavior

`test_ship_interior_unit` should complete without errors in both headless and in-editor modes.
`_viewport_window` should be non-null by the time `_ready` accesses `material_override`.

## Actual Behavior

`_viewport_window` is `null` in-editor, causing a crash at `ship_interior.gd:71`. The debugger
halts the entire in-editor test run.

## Evidence

- Runtime error captured during TICKET-0371 in-editor verification run (2026-03-08):
  `Invalid access to property or key 'material_override' on a base object of type 'null instance'.`
- Stack trace: `ship_interior.gd:71 → test_ship_interior_unit.gd:15 → test_suite.gd:186`
- Headless run confirmed unaffected: 1009 passed, 0 failed, 0 skipped (2026-03-08)

## Fix Suggestion

Add a null guard in `ship_interior.gd:_ready` before accessing `_viewport_window.material_override`,
or ensure the SubViewport node reference is valid before the property is read. Alternatively,
restructure the `_ready` initialization to use `call_deferred` or `await get_tree().process_frame`
so the SubViewport has time to initialize in editor play mode.

## Activity Log

- 2026-03-08 [qa-engineer] Bug discovered during TICKET-0371 in-editor verification. Observed while running test_runner.tscn in-editor after the async before_each fix. Ship interior test fails before the navigation console suite. Filed as P2 — headless workaround available.
