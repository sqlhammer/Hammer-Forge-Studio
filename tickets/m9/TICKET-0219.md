---
id: TICKET-0219
title: "Feature — Destroy (discard) an item directly from inventory"
type: FEATURE
status: OPEN
priority: P2
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-28
updated_at: 2026-02-28
milestone: "M9"
phase: "TBD"
depends_on: []
blocks: []
tags: [feature, inventory, items, ui, m9]
---

## Summary

Players cannot remove unwanted items from their inventory other than by using them. This ticket adds a destroy/discard action that permanently removes a selected item from the inventory without spawning it in the world.

## Acceptance Criteria

- [ ] Player can destroy a selected item from the inventory UI — item is removed from inventory and does not spawn in the world
- [ ] A confirmation step is required before destruction (e.g., hold to destroy, or a confirm dialog) to prevent accidental loss
- [ ] Destroyed items are gone permanently — no recovery
- [ ] The action is clearly labeled "Destroy" or "Discard" in the UI to distinguish it from drop (TICKET-0218)
- [ ] Unit tests cover: destroy removes item from inventory, item count decrements correctly, confirmation gate blocks accidental destruction
- [ ] Full test suite passes with no new failures

## Implementation Notes

- If TICKET-0218 (drop) is also implemented in M9, destroy and drop should be distinct actions in the inventory UI — drop leaves the item in the world; destroy does not
- A hold-to-confirm pattern (hold for ~1.5s to destroy) avoids a dialog and is consistent with mining hold mechanics
- Alternatively, a simple "Are you sure?" dialog with Yes/No buttons is acceptable

## Activity Log

- 2026-02-28 [producer] Created — deferred from M8; Studio Head requested during M8 playtest
