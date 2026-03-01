---
id: TICKET-0261
title: "Code Quality: Fix NavigationConsole null spy reference in test after_each()"
type: BUG
status: OPEN
priority: P3
owner: qa-engineer
created_by: producer
created_at: 2026-03-01
updated_at: 2026-03-01
milestone: "M9"
phase: "Code Quality"
depends_on: []
blocks: []
tags: [code-quality, m8-cleanup, tests, navigation-console, null-reference, qa]
---

## Summary

`test_navigation_console_unit`'s `after_each()` calls `_spy.clear()` on a null spy reference, producing `SCRIPT ERROR` lines in the test log after every test case. The tests themselves pass, but the noisy errors make the log harder to read and can mask real failures. The null check is missing from the teardown path.

## Acceptance Criteria

- [ ] `after_each()` in `test_navigation_console_unit` guards `_spy.clear()` with a null check (or initializes `_spy` to a non-null default) so no `SCRIPT ERROR` is emitted during teardown
- [ ] All existing NavigationConsole unit tests still pass
- [ ] The test log contains zero `SCRIPT ERROR` lines attributable to this file
- [ ] Full test suite passes with no new failures

## Implementation Notes

- The fix is a one-liner null guard: `if _spy: _spy.clear()` or equivalent
- Do not change test logic, test count, or assertions — teardown cleanup only
- Confirmed location: `game/tests/test_navigation_console_unit.gd` (or similar path under `game/tests/`)

## Activity Log

- 2026-03-01 [producer] Created — deferred item D-029 from M8 QA (TICKET-0176); scheduled for M9 Code Quality phase
