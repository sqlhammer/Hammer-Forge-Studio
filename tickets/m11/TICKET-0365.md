---
id: TICKET-0365
title: "BUG — test_navigation_console_unit crashes in before_each() due to NavigationConsole.new() missing scene nodes"
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
tags: [test, navigation-console, bug, unit-test, scene-instantiation]
---

## Summary

`test_navigation_console_unit.gd` crashes in `before_each()` because it instantiates
`NavigationConsole` via `NavigationConsole.new()` instead of loading the `.tscn` scene.
After TICKET-0292 converted NavigationConsole to a scene-first pattern with `%` unique
name node references, the test's bare `.new()` instantiation leaves all `@onready` vars
null, causing `_apply_styles()` to crash with `Cannot call method 'add_theme_stylebox_override'
on a null value` at navigation_console.gd:203.

---

## Severity

**P2 — Defect in expected behavior**: Test suite crashes mid-run, preventing remaining suites
from executing. Not a regression from TICKET-0311 — this is a pre-existing issue caused by
the same `.new()` vs `.tscn` pattern fixed in TICKET-0354 and TICKET-0359.

---

## Error Details

```
navigation_console.gd:50 @ @implicit_ready(): Node not found: "%DimRect" (relative to
  "/root/TestRunner/@Node@1116/@CanvasLayer@1117").
[... 20+ similar "Node not found" errors for all @onready % nodes ...]
NavigationConsole._apply_styles: Cannot call method 'add_theme_stylebox_override' on a null value.
```

**Stack trace:**
```
0 - res://scripts/ui/navigation_console.gd:203 - at function: _apply_styles
1 - res://scripts/ui/navigation_console.gd:77  - at function: _ready
2 - res://tests/test_navigation_console_unit.gd:25 - at function: before_each
3 - res://addons/hammer_forge_tests/test_suite.gd:186 - at function: _run_single_test
4 - res://addons/hammer_forge_tests/test_suite.gd:74  - at function: run_all_tests
5 - res://addons/hammer_forge_tests/test_runner.gd:96 - at function: _run_suite_from_path
```

---

## Reproduction Steps

1. Open `res://addons/hammer_forge_tests/test_runner.tscn` and play it.
2. The test runner crashes mid-suite when reaching `test_navigation_console_unit`.
3. Observe the runtime errors: `Node not found: "%DimRect"` and
   `Cannot call method 'add_theme_stylebox_override' on a null value`.

---

## Expected Behavior

`test_navigation_console_unit.gd` instantiates `NavigationConsole` from its `.tscn`
scene file so all `%` unique-name node references resolve correctly, matching the pattern
used in `test_inventory_screen_popup_unit` (TICKET-0354) and `test_mouse_interaction_unit`
(TICKET-0359).

## Actual Behavior

`before_each()` line 24 calls `NavigationConsole.new()` which creates only the script
instance without the scene tree, leaving all `@onready var _dim_rect: ColorRect = %DimRect`
and similar vars null.

---

## Suggested Fix

In `test_navigation_console_unit.gd`, change `before_each()` to load the scene:

```gdscript
var packed = preload("res://scenes/ui/navigation_console.tscn")
_console = packed.instantiate() as NavigationConsole
add_child(_console)
```

This matches the fix applied in TICKET-0354 for `test_inventory_screen_popup_unit`
and TICKET-0359 for `test_mouse_interaction_unit`.

---

## Files Involved

- `game/tests/test_navigation_console_unit.gd` — line 24: `NavigationConsole.new()`
- `game/scripts/ui/navigation_console.gd` — line 203: `_apply_styles()` crashes on null

---

## Activity Log

- 2026-03-07 [play-tester] Filed — discovered during TICKET-0339 unit test run; pre-existing issue unrelated to TICKET-0311 changes.
- 2026-03-07 [qa-engineer] Starting work — replacing NavigationConsole.new() with scene instantiation in before_each().
- 2026-03-07 [qa-engineer] DONE — Fixed. Commit 8cb626b, PR https://github.com/sqlhammer/Hammer-Forge-Studio/pull/387.
