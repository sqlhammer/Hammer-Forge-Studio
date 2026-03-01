---
id: TICKET-0209
title: "Bugfix — Old biome not removed on second travel; container holds 2 biome nodes"
type: BUGFIX
status: DONE
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27T00:02
milestone: "M8"
phase: "QA"
depends_on: []
blocks: []
tags: [bugfix, travel, biome, regression, m8-qa]
---

## Summary

After a second biome travel, the biome container holds 2 biome nodes instead of 1. The old biome is not removed when the new biome is loaded on the second travel. This causes the test `old_biome_removed_on_second_travel` in `test_travel_sequence_unit` to fail.

Discovered during the M8 post-bugfix QA regression run (2026-02-27). The prior QA sign-off (879/879) passed this test; this is a regression introduced by one of TICKET-0200–0208.

## Failing Test

```
Suite:   test_travel_sequence_unit
Test:    old_biome_removed_on_second_travel
Message: Container should have exactly one biome node after second travel: Expected '1' but got '2'
File:    res://tests/test_travel_sequence_unit.gd:189
```

## Expected Behavior

After any biome travel, the biome container contains exactly one biome node — the newly loaded destination. The previously loaded biome is fully removed before or during the travel sequence.

## Acceptance Criteria

- [x] `old_biome_removed_on_second_travel` passes
- [x] Full test suite passes with 879/879 (zero failures)
- [x] No regression to other travel sequence tests

## Implementation Notes

- The likely root cause is the deposit cleanup added to `TravelSequenceManager._clear_biome_container()` in TICKET-0201 — that change may have broken the biome node removal logic (e.g., early return, exception swallowed, or node removal skipped when deposits are unregistered)
- Also check TICKET-0204 (terrain collision fix) if it modified anything in biome teardown
- Read `TravelSequenceManager._clear_biome_container()` and trace what happens on a second travel vs. the first — the first travel likely passes because there is no old biome to clear, while the second fails because the clear is now broken
- Compare against the version before TICKET-0201 using `git diff` to isolate what changed in the travel/biome teardown path

## Activity Log

- 2026-02-27 [producer] Created — discovered in post-bugfix QA regression run; 878/879, single failure in test_travel_sequence_unit
- 2026-02-27 [gameplay-programmer] Starting work — investigating _clear_biome_container() regression from TICKET-0201/0204
- 2026-02-27 [gameplay-programmer] DONE — fixed by reordering _clear_biome_container(): child removal now happens BEFORE deposit unregistration; added is_instance_valid() guard for stale freed deposit references. Commit: 59dc366, PR: https://github.com/sqlhammer/Hammer-Forge-Studio/pull/179
