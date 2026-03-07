---
id: TICKET-0339
title: "VERIFY — BUG fix: fabricator_panel Array[Dictionary] mismatch and TravelFadeLayer nodes (TICKET-0311)"
type: TASK
status: TODO
priority: P1
owner: play-tester
created_by: producer
created_at: 2026-03-07
updated_at: 2026-03-07
milestone: "M11"
phase: "QA"
depends_on: [TICKET-0311]
blocks: []
tags: [verify, bug, fabricator-panel, travel-fade-layer]
---

## Summary

Verify that the Fabricator panel displays recipe inputs correctly (no blank inputs from
Array[Dictionary] mismatch) and that biome travel fade plays correctly (TravelFadeLayer
nodes present) after fixes in TICKET-0311.

---

## Acceptance Criteria

- [ ] Visual verification: Fabricator panel opens; selecting a recipe shows its input
      requirements (materials and quantities) — not blank or empty
- [ ] Visual verification: Queuing a recipe with available inputs starts crafting without
      errors
- [ ] Visual verification: Biome travel fade-out and fade-in play correctly — no missing
      fade layer or abrupt cuts
- [ ] State dump: No quantitative assertions required; check for ERROR-free console
- [ ] Unit test suite: zero failures across all tests
- [ ] No runtime errors during any verification scenario

---

## Handoff Notes

(Leave blank until verification is complete.)

---

## Activity Log

- 2026-03-07 [producer] Created VERIFY ticket for TICKET-0311 — BUG: fabricator_panel + TravelFadeLayer fix
