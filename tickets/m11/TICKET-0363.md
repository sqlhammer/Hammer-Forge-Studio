---
id: TICKET-0363
title: "VERIFY — BUG fix: InventoryActionPopup _update_focus_visual null instance crash (TICKET-0352)"
type: TASK
status: OPEN
priority: P1
owner: play-tester
created_by: producer
created_at: 2026-03-08
updated_at: 2026-03-08
milestone: "M11"
phase: "QA"
depends_on: [TICKET-0352]
blocks: []
tags: [auto-created]
---

## Summary

Verify that InventoryActionPopup no longer crashes the test runner with _update_focus_visual null instance errors after the fix in TICKET-0352.

## Acceptance Criteria

- [ ] Visual verification: Run the full unit test suite — the InventoryActionPopup suite must complete with all tests passing and no null-instance errors in godot.log
- [ ] State dump: Zero ERROR lines in godot.log attributable to _update_focus_visual or InventoryActionPopup null instance during the test run
- [ ] Unit test suite: zero failures across all tests
- [ ] No runtime errors during any verification scenario

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-03-08 [conductor] Created via orchestration wave 46
