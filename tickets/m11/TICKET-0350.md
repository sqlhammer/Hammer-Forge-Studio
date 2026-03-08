---
id: TICKET-0350
title: "BUG — test_dropped_item_unit::inventory_screen_drop_signal_defined is flaky (ClassDB registration timing)"
type: BUG
status: DONE
priority: P3
owner: qa-engineer
created_by: play-tester
created_at: 2026-03-07
updated_at: 2026-03-07
milestone: "M11"
phase: "QA"
depends_on: []
blocks: []
tags: [test-suite, inventory-screen, unit-test, flaky, classdb]
---

## Summary

`test_dropped_item_unit::inventory_screen_drop_signal_defined` fails intermittently. The test
uses `ClassDB.class_has_signal("InventoryScreen", "item_drop_requested")` to verify the signal
exists, but `ClassDB` does not reliably return GDScript class signals when the class has not
yet been instantiated/registered by the engine at test execution time.

---

## Severity

P3 — Non-blocking flakiness. Does not indicate a real code defect. The `item_drop_requested`
signal is correctly defined in `inventory_screen.gd:8`. The failure is an artifact of ClassDB
registration timing, not a missing signal.

---

## Reproduction Steps

1. Launch `res://addons/hammer_forge_tests/test_runner.tscn`
2. Wait for the test runner to complete all suites
3. Observe that `test_dropped_item_unit::inventory_screen_drop_signal_defined` sometimes FAILs
   with: `InventoryScreen should have item_drop_requested signal: Expected true but got false`
4. Re-run — the test may pass on the next run with identical code

**Evidence of flakiness:**
- Run at 2026-03-07 18:01: 1009 passed, 0 failed (test PASSED)
- Run at 2026-03-07 19:38: 1008 passed, 1 failed (test FAILED)
- Run at 2026-03-07 19:39: 1008 passed, 1 failed (test FAILED)
- No code changes between these runs

---

## Root Cause

TICKET-0348 fixed a crash in this test by replacing `InventoryScreen.new()` with
`ClassDB.class_has_signal("InventoryScreen", "item_drop_requested")`. However,
`ClassDB.class_has_signal` for GDScript `class_name` types depends on whether the class has
been registered/loaded by the engine before the test runs. This is non-deterministic and
produces flaky results.

---

## Expected Behavior

The test should reliably verify that `InventoryScreen` has the `item_drop_requested` signal
without crashing or intermittently failing.

## Actual Behavior

`ClassDB.class_has_signal("InventoryScreen", "item_drop_requested")` returns `false`
non-deterministically, causing the test to fail even though the signal is defined.

---

## Fix Approach

Replace the `ClassDB.class_has_signal` check with a method that reliably detects GDScript
signals — for example, instantiate `InventoryScreen` from its `.tscn` scene file (which avoids
the `@onready` crash) and call `has_signal("item_drop_requested")` on the instance. Or use a
script-level metadata check that does not depend on ClassDB registration timing.

---

## Activity Log

- 2026-03-07 [play-tester] Created during TICKET-0330 verification. TICKET-0348 fix introduced
  ClassDB-based flakiness confirmed by test passing at 18:01 and failing at 19:38/19:39 with
  no code changes between runs. Signal IS correctly defined in inventory_screen.gd:8.
  NOT related to TICKET-0301.
- 2026-03-07 [qa-engineer] Starting work. Replacing ClassDB.class_has_signal with instance-based
  has_signal check using load("res://scenes/ui/inventory_screen.tscn").instantiate().
- 2026-03-07 [qa-engineer] Fix implemented in game/tests/test_dropped_item_unit.gd:205-210.
  Replaced ClassDB.class_has_signal("InventoryScreen", "item_drop_requested") with
  load("res://scenes/ui/inventory_screen.tscn").instantiate().has_signal("item_drop_requested").
  Full test suite run (headless): 1009 passed, 0 failed, 0 skipped. Report:
  user://test_reports/test_report_2026-03-07 22-42-16.json. Commit: aba878b, PR: #379 (merged).
