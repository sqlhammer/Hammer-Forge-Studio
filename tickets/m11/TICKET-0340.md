---
id: TICKET-0340
title: "VERIFY — BUG fix: fabricator_defs get_inputs() Array[Dictionary] cast regression (TICKET-0312)"
type: TASK
status: TODO
priority: P1
owner: play-tester
created_by: producer
created_at: 2026-03-07
updated_at: 2026-03-07
milestone: "M11"
phase: "QA"
depends_on: [TICKET-0312]
blocks: []
tags: [verify, bug, fabricator-defs, array-cast]
---

## Summary

Verify that fabricator recipe input resolution works correctly and produces no SCRIPT ERROR
from the Array[Dictionary] as-cast regression fixed in TICKET-0312.

---

## Acceptance Criteria

- [ ] Visual verification: Fabricator panel opens; all recipes show their input requirements
      with correct material names and quantities
- [ ] Visual verification: Crafting a recipe successfully resolves inputs from inventory —
      no errors or empty input lists
- [ ] State dump: No quantitative assertions required; check for ERROR-free console
      (specifically no "Invalid cast" or SCRIPT ERROR lines)
- [ ] Unit test suite: zero failures across all tests
- [ ] No runtime errors during any verification scenario

---

## Handoff Notes

(Leave blank until verification is complete.)

---

## Activity Log

- 2026-03-07 [producer] Created VERIFY ticket for TICKET-0312 — BUG: fabricator_defs get_inputs() cast fix
