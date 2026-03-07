---
id: TICKET-0330
title: "VERIFY — Standards remediation: Fix Input.is_action_just_pressed() bypass (TICKET-0301)"
type: TASK
status: TODO
priority: P1
owner: play-tester
created_by: producer
created_at: 2026-03-07
updated_at: 2026-03-07
milestone: "M11"
phase: "QA"
depends_on: [TICKET-0301]
blocks: []
tags: [verify, standards, input, inventory]
---

## Summary

Verify that inventory_screen.gd routes input through InputManager correctly (no direct
Input.is_action_just_pressed() calls) and that all inventory keyboard shortcuts still work
after TICKET-0301.

---

## Acceptance Criteria

- [ ] Visual verification: Inventory opens and closes correctly using keyboard shortcuts
      (Tab/I/Escape) — no regression in input response
- [ ] Visual verification: Item selection, drop, and destroy actions still function via
      keyboard in the inventory screen
- [ ] State dump: No quantitative assertions required; check for ERROR-free console
- [ ] Unit test suite: zero failures across all tests
- [ ] No runtime errors during any verification scenario

---

## Handoff Notes

(Leave blank until verification is complete.)

---

## Activity Log

- 2026-03-07 [producer] Created VERIFY ticket for TICKET-0301 — Standards: Input bypass fix
