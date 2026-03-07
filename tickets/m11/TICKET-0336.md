---
id: TICKET-0336
title: "VERIFY — BUG fix: InventoryActionPopup hidden by default and correctly found (TICKET-0308)"
type: TASK
status: TODO
priority: P1
owner: play-tester
created_by: producer
created_at: 2026-03-07
updated_at: 2026-03-07
milestone: "M11"
phase: "QA"
depends_on: [TICKET-0308]
blocks: []
tags: [verify, bug, inventory, action-popup]
---

## Summary

Verify that InventoryActionPopup is hidden by default when the inventory opens, appears
correctly on item interaction, and is correctly located via get_node() after TICKET-0308.

---

## Acceptance Criteria

- [ ] Visual verification: Inventory screen opens — action popup is NOT visible by default
- [ ] Visual verification: Right-clicking (or pressing interact on) an item causes the
      action popup to appear correctly positioned near the item
- [ ] Visual verification: Popup closes after an action is taken or the player clicks
      elsewhere
- [ ] State dump: No quantitative assertions required; check for ERROR-free console
      (no "Node not found" errors)
- [ ] Unit test suite: zero failures across all tests
- [ ] No runtime errors during any verification scenario

---

## Handoff Notes

(Leave blank until verification is complete.)

---

## Activity Log

- 2026-03-07 [producer] Created VERIFY ticket for TICKET-0308 — BUG: InventoryActionPopup visibility fix
