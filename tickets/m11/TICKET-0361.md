---
id: TICKET-0361
title: "VERIFY — BUG fix: test_dropped_item_unit flaky ClassDB registration timing (TICKET-0350)"
type: TASK
status: DONE
priority: P1
owner: play-tester
created_by: producer
created_at: 2026-03-08
updated_at: 2026-03-08
milestone: "M11"
phase: "QA"
depends_on: [TICKET-0350]
blocks: []
tags: [auto-created]
---

## Summary

Verify that test_dropped_item_unit::inventory_screen_drop_signal_defined is no longer flaky after the ClassDB registration timing fix in TICKET-0350.

## Acceptance Criteria

- [x] Visual verification: Run the full unit test suite — test_dropped_item_unit::inventory_screen_drop_signal_defined must pass consistently across at least two sequential runs with no intermittent failures
- [x] State dump: Zero flaky-test failures reported for inventory_screen_drop_signal_defined in godot.log across both runs
- [x] Unit test suite: zero failures across all tests
- [x] No runtime errors during any verification scenario

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-03-08 [conductor] Created via orchestration wave 46
- 2026-03-07 [play-tester] Starting work. Running test suite twice to verify inventory_screen_drop_signal_defined is no longer flaky after TICKET-0350 fix.
- 2026-03-07 [play-tester] VERIFICATION COMPLETE — PASS. Ran full unit test suite headlessly twice sequentially.

  **Run 1** (test_report_2026-03-08 04-12-55.json): 1009 passed, 0 failed, 0 skipped. STATUS: ALL PASSED.
  - test_dropped_item_unit::inventory_screen_drop_signal_defined — PASSED (90ms). No flaky failure.
  - No lines matching inventory_screen_drop_signal_defined failures in godot.log.

  **Run 2** (test_report_2026-03-08 04-17-27.json): 1009 passed, 0 failed, 0 skipped. STATUS: ALL PASSED.
  - test_dropped_item_unit::inventory_screen_drop_signal_defined — PASSED (82ms). No flaky failure.
  - No lines matching inventory_screen_drop_signal_defined failures in godot.log.

  Both runs: exit code 0. Zero runtime test-related errors. The instance-based has_signal() fix from TICKET-0350 eliminated the ClassDB registration timing flakiness. Verdict: ALL PASS.
