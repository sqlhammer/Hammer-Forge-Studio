---
id: TICKET-0151
title: "Bugfix — test_scanner_unit.gd parse error: Scanner.LAYER_INTERACTABLE removed"
type: BUGFIX
status: DONE
priority: P1
owner: systems-programmer
created_by: qa-engineer
created_at: 2026-02-26
updated_at: 2026-02-26
milestone: "M7"
phase: "QA"
depends_on: []
blocks: [TICKET-0130]
tags: [test, regression, scanner, physics-layers, bugfix, p1]
---

## Summary

`test_scanner_unit.gd` fails to parse with error: `Cannot find member "LAYER_INTERACTABLE" in base "Scanner"`. This was caused by TICKET-0144, which centralized physics layer constants into `PhysicsLayers` and removed `LAYER_INTERACTABLE` from `Scanner`, but did not update the test file reference on line 101.

This blocks the full test suite from running — the scanner unit test suite (23 tests) cannot load. The M7 QA gate requires all tests to pass, so this must be fixed before milestone close.

## Steps to Reproduce

1. Run the test suite headlessly: `godot --headless --path game res://addons/hammer_forge_tests/test_runner.tscn`
2. Observe parse error: `Parse Error: Cannot find member "LAYER_INTERACTABLE" in base "Scanner"` at `test_scanner_unit.gd:101`
3. The `test_scanner_unit` suite does not load — 23 tests are skipped

## Expected Behavior

`test_scanner_unit.gd` loads and all 23 tests execute successfully.

## Actual Behavior

The suite fails to parse at line 101 which references `Scanner.LAYER_INTERACTABLE` — a constant that was removed in TICKET-0144 and replaced with `PhysicsLayers.INTERACTABLE`.

## Acceptance Criteria

- [x] `test_scanner_unit.gd` line 101 updated to reference `PhysicsLayers.INTERACTABLE` instead of `Scanner.LAYER_INTERACTABLE`
- [x] Full test suite passes with `test_scanner_unit` included (expected total: 480 tests)
- [x] No other references to `Scanner.LAYER_INTERACTABLE` remain in the codebase

## Implementation Notes

Single-line fix at `game/tests/test_scanner_unit.gd` line 101:
- Change `Scanner.LAYER_INTERACTABLE` → `PhysicsLayers.INTERACTABLE`
- The test assertion value (`1 << 3`) is correct — only the reference source changed

## Activity Log
- 2026-02-26 [qa-engineer] Created — regression from TICKET-0144 (PhysicsLayers centralization) that was not caught during code review
- 2026-02-26 [systems-programmer] Starting work — single-line fix in test_scanner_unit.gd line 101
- 2026-02-26 [systems-programmer] DONE — replaced Scanner.LAYER_INTERACTABLE with PhysicsLayers.INTERACTABLE on line 101. Commit: b1849560f268438a68611b9d48398361279a85b2, PR: https://github.com/sqlhammer/Hammer-Forge-Studio/pull/115 (merged to main: d67525ef25a885998a24e8461394e4c39362a02f). Full test suite: 480/480 passed (0 failed, 0 skipped), test_scanner_unit: 23/23 passed.
