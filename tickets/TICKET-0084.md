---
id: TICKET-0084
title: "Gameplay phase gate — regression test suite"
type: TASK
status: OPEN
priority: P1
owner: qa-engineer
created_by: producer
created_at: 2026-02-25
updated_at: 2026-02-25
milestone: "M5"
milestone_gate: "M4"
phase: "Gameplay"
depends_on: [TICKET-0068, TICKET-0069, TICKET-0070, TICKET-0071, TICKET-0072, TICKET-0073, TICKET-0074, TICKET-0082]
blocks: [TICKET-0075]
tags: [qa, testing, phase-gate, gameplay]
---

## Summary

Run the full regression test suite once all Gameplay phase tickets are DONE. This is the formal test verification condition for the Gameplay phase gate. The gate cannot pass — and the QA phase (TICKET-0075 code review, TICKET-0076 full QA) cannot open — until this ticket is DONE with a clean result.

## Acceptance Criteria

- [ ] All Gameplay phase tickets (TICKET-0068–0074, TICKET-0082) are DONE before this ticket begins
- [ ] Full test suite executed via `res://addons/hammer_forge_tests/test_runner.tscn`
- [ ] Zero test failures
- [ ] Prior baseline of 284 tests (M4 close) holds — no tests removed or skipped
- [ ] New unit tests added by gameplay-programmer (if any) pass
- [ ] Any failures investigated and a P0/P1 BLOCKER ticket opened before marking this DONE
- [ ] Pass result and test count posted in Activity Log

## Implementation Notes

- Gameplay phase adds significant new systems (tech tree, Fabricator UI, minigame, third-person scan/mine, drones, Spare Battery, Head Lamp, ship entry bugfix) — regression risk is higher than Foundation gate; run a full suite, not a targeted subset
- This is a regression check only — unit test authorship for new M5 systems is handled in TICKET-0076
- If the Compliance phase runs in parallel with Gameplay, TICKET-0083 and TICKET-0084 together cover all code changes prior to the QA phase

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-25 [producer] Created ticket — phase gate test verification was missing from original M5 ticket set
