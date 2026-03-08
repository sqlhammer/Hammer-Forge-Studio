---
id: TICKET-0366
title: "VERIFY — BUG fix: test_navigation_console_unit uses .tscn instantiation, test suite passes (TICKET-0365)"
type: TASK
status: IN_PROGRESS
priority: P2
owner: play-tester
created_by: producer
created_at: 2026-03-08
updated_at: 2026-03-08
milestone: "M11"
phase: "QA"
depends_on: [TICKET-0365]
blocks: []
tags: [auto-created]
---

## Summary

Verify that test_navigation_console_unit no longer crashes and the full unit test suite runs to completion after the TICKET-0365 fix.

## Acceptance Criteria

- [ ] Visual verification: test_navigation_console_unit runs without any 'Node not found' or null-value errors in the test runner output
- [ ] State dump: all test_navigation_console_unit test cases report PASS; zero crashes or runtime errors in the suite
- [ ] Unit test suite: zero failures across all tests
- [ ] No runtime errors during any verification scenario

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-03-08 [conductor] Created via orchestration wave 49
- 2026-03-08 [play-tester] Starting work — verifying test_navigation_console_unit fix from TICKET-0365
