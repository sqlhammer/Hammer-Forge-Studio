---
id: TICKET-0371
title: "BUG — test_navigation_console_unit fails in-editor: _spy is null in _test_console_emits_panel_closed_on_close"
type: BUG
status: OPEN
priority: P2
owner: qa-engineer
created_by: play-tester
created_at: 2026-03-08
updated_at: 2026-03-08
milestone: "M11"
phase: "QA"
depends_on: []
blocks: []
tags: [test-failure, async, navigation-console, in-editor]
---

## Summary

`test_navigation_console_unit._test_console_emits_panel_closed_on_close` crashes at runtime with
`Invalid call. Nonexistent function 'was_emitted' in base 'Nil'` when the test suite is run in-editor
(via `play_scene`). The test passed 15/15 in headless mode (TICKET-0368), but fails reproducibly
in-editor mode.

## Severity

P2 — Test failure blocks zero-failure unit test gate in in-editor verification mode. Not a game
runtime crash and does not affect headless CI.

## Reproduction Steps

1. Open the Godot editor for this project
2. Open `res://addons/hammer_forge_tests/test_runner.tscn`
3. Play the scene (in-editor, not headless)
4. Observe console error: `TestNavigationConsoleUnit.assert_signal_emitted: Invalid call. Nonexistent function 'was_emitted' in base 'Nil'.`
5. Runtime stack trace:
   - `test_suite.gd:154 @ assert_signal_emitted`
   - `test_navigation_console_unit.gd:117 @ _test_console_emits_panel_closed_on_close`

## Root Cause (Analysis)

`test_suite.gd:_run_single_test` calls `before_each()` without `await` (line 186). The navigation
console test's `before_each` contains `await get_tree().process_frame` — this causes the coroutine
to yield at that point, and the remainder of `before_each` (including `_spy = SignalSpy.new()`) does
not execute before the test callable runs. As a result, `_spy` is `null` when
`_test_console_emits_panel_closed_on_close` calls `assert_signal_emitted(_spy, "panel_closed", ...)`.

In headless mode (TICKET-0368 showed 15/15), the frame signal may resolve differently, allowing
`before_each` to complete before the test runs. This is an in-editor vs. headless behavioral difference.

**Note:** TICKET-0369 (terrain winding order fix) did NOT introduce this bug — it only changed
`terrain_generator.gd`. The failure is in `test_suite.gd`'s async handling of `before_each`.

## Expected Behavior

`test_navigation_console_unit` should pass 15/15 in both headless and in-editor modes. `_spy` should
be properly initialized before any test that uses it.

## Actual Behavior

`_spy` is `null` when `_test_console_emits_panel_closed_on_close` runs in-editor mode, causing a
runtime crash: `Invalid call. Nonexistent function 'was_emitted' in base 'Nil'`.

## Evidence

- Runtime error: `TestNavigationConsoleUnit.assert_signal_emitted: Invalid call. Nonexistent function 'was_emitted' in base 'Nil'.`
- Stack trace captured via `get_godot_errors` in TICKET-0370 verification run (2026-03-08)
- TICKET-0368 confirmed 15/15 passing in headless mode prior to TICKET-0369

## Fix Suggestion

In `test_suite.gd:_run_single_test`, change `before_each()` to `await before_each()` so async
`before_each` methods complete before the test runs. Alternatively, the navigation console test's
`before_each` could restructure to avoid the `await` (e.g., use `call_deferred` or synchronous
instantiation patterns).

## Activity Log

- 2026-03-08 [play-tester] Bug discovered during TICKET-0370 verification. In-editor test run shows _spy null in _test_console_emits_panel_closed_on_close. TICKET-0369 terrain fix is not the cause.
