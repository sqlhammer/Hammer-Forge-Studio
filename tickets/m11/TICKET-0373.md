---
id: TICKET-0373
title: "VERIFY — BUG fix: test_ship_interior_unit no longer crashes in-editor (TICKET-0372)"
type: TASK
status: DONE
priority: P2
owner: play-tester
created_by: producer
created_at: 2026-03-08
updated_at: 2026-03-08
milestone: "M11"
phase: "QA"
depends_on: [TICKET-0372]
blocks: []
tags: [auto-created]
---

## Summary

Confirm that the null-guard fix in ship_interior.gd eliminates the in-editor crash and test_ship_interior_unit completes without errors in both in-editor and headless modes.

## Acceptance Criteria

- [x] Visual verification: Open test_runner.tscn in the Godot editor and play it in-editor — the debugger must NOT halt at ship_interior.gd:71 or anywhere in the ship interior test suite
  - PARTIAL: Line 71 crash eliminated (TICKET-0372 fix confirmed). Debugger halted at ship_interior.gd:217 in _update_zone_visual — FAIL
- [ ] State dump: All test_ship_interior_unit tests pass (0 failures) in-editor; headless run continues to report 1009 passed, 0 failed, 0 skipped
  - In-editor: test halted at _test_place_module_in_zone_0_marks_occupied — FAIL
- [ ] Unit test suite: zero failures across all tests
  - In-editor run did not complete — FAIL
- [ ] No runtime errors during any verification scenario
  - Runtime error at ship_interior.gd:217: null marker in _update_zone_visual — FAIL

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-03-08 [conductor] Created via orchestration wave 131
- 2026-03-08 [play-tester] Starting work. Verifying null-guard fix from TICKET-0372 — will run test_runner.tscn in-editor and headless to confirm no crash at ship_interior.gd:71 and 1009/0/0 pass/fail/skip.
- 2026-03-08 [play-tester] DONE — VERDICT: FAIL. Ran test_runner.tscn in-editor twice. Summary:
  SCENARIO 1 — Debugger halt at line 71: PASS. No crash at ship_interior.gd:71. The TICKET-0372 null guard fix for _ready() is confirmed working.
  SCENARIO 2 — No halt anywhere in ship interior test suite: FAIL. Godot debugger halted at ship_interior.gd:217 in _update_zone_visual during _test_place_module_in_zone_0_marks_occupied. Editor screenshot confirms: error "Invalid access to property or key 'material_override' on a base object of type 'null instance'", Locals panel shows marker=<null>, _zone_floor_markers has size 4 but null entries because ZoneMarker nodes were not found during @onready.
  SCENARIO 3 — Unit test suite 0 failures: FAIL. In-editor run halted before suite could complete.
  SCENARIO 4 — No runtime errors: FAIL. Runtime error at ship_interior.gd:217.
  Root cause: _update_zone_visual at line 213-217 lacks a null guard for individual _zone_floor_markers entries. _zone_floor_markers has size 4 but entries are null when instantiated without the full scene tree. The line 214 bounds check passes (0 < 4) but marker itself is null.
  BUG filed: TICKET-0374 (P2, owner: systems-programmer).
