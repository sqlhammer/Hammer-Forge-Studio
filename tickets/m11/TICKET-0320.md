---
id: TICKET-0320
title: "VERIFY — Scene-First remediation: Ship Machine Panels (TICKET-0291)"
type: TASK
status: TODO
priority: P1
owner: play-tester
created_by: producer
created_at: 2026-03-07
updated_at: 2026-03-07
milestone: "M11"
phase: "QA"
depends_on: [TICKET-0291]
blocks: []
tags: [verify, scene-first, recycler, fabricator, automation-hub]
---

## Summary

Verify that the Recycler panel, Fabricator panel, and Automation Hub panel all open and
function correctly after the Scene-First refactor in TICKET-0291.

---

## Acceptance Criteria

- [ ] Visual verification: Recycler panel opens when interacting with the Recycler in the ship
      interior — grid and controls are visible and correctly laid out
- [ ] Visual verification: Fabricator panel opens with a populated recipe list; input
      requirements display correctly (not blank)
- [ ] Visual verification: Automation Hub panel opens without errors
- [ ] State dump: No ERROR lines in console during panel open/close for any of the three panels
- [ ] Unit test suite: zero failures across all tests
- [ ] No runtime errors during any verification scenario

---

## Handoff Notes

(Leave blank until verification is complete.)

---

## Activity Log

- 2026-03-07 [producer] Created VERIFY ticket for TICKET-0291 — Scene-First: Ship Machine Panels
