---
id: TICKET-0322
title: "VERIFY — Scene-First remediation: Inventory Screen and Inventory Action Popup (TICKET-0293)"
type: TASK
status: TODO
priority: P1
owner: play-tester
created_by: producer
created_at: 2026-03-07
updated_at: 2026-03-07
milestone: "M11"
phase: "QA"
depends_on: [TICKET-0293]
blocks: []
tags: [verify, scene-first, inventory]
---

## Summary

Verify that the Inventory Screen opens with items displayed and that the Inventory Action
Popup appears on item interaction after the Scene-First refactor in TICKET-0293.

---

## Acceptance Criteria

- [ ] Visual verification: Inventory screen opens (inventory_toggle action); item grid shows
      items with icons and labels; screen closes cleanly
- [ ] Visual verification: Action popup is hidden when inventory first opens — not visible
      by default
- [ ] Visual verification: Right-clicking an item shows the action popup with options
      (Drop, Destroy); actions execute correctly
- [ ] State dump: INVENTORY_USED count decreases by 1 after dropping an item
- [ ] Unit test suite: zero failures across all tests
- [ ] No runtime errors during any verification scenario

---

## Handoff Notes

(Leave blank until verification is complete.)

---

## Activity Log

- 2026-03-07 [producer] Created VERIFY ticket for TICKET-0293 — Scene-First: Inventory Screen
