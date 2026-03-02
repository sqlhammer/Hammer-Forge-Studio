---
id: TICKET-0219
title: "Feature — Destroy (discard) an item directly from inventory"
type: FEATURE
status: DONE
priority: P2
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-28
updated_at: 2026-02-28
milestone: "M9"
phase: "Gameplay Polish"
depends_on: []
blocks: []
tags: [feature, inventory, items, ui, m9]
---

## Summary

Players cannot remove unwanted items from their inventory other than by using them. This ticket adds a destroy/discard action that permanently removes a selected item from the inventory without spawning it in the world.

## Acceptance Criteria

- [x] Player can destroy a selected item from the inventory UI — item is removed from inventory and does not spawn in the world
- [x] A confirmation step is required before destruction (e.g., hold to destroy, or a confirm dialog) to prevent accidental loss
- [x] Destroyed items are gone permanently — no recovery
- [x] The action is clearly labeled "Destroy" or "Discard" in the UI to distinguish it from drop (TICKET-0218)
- [x] Unit tests cover: destroy removes item from inventory, item count decrements correctly, confirmation gate blocks accidental destruction
- [x] Full test suite passes with no new failures

## Implementation Notes

- If TICKET-0218 (drop) is also implemented in M9, destroy and drop should be distinct actions in the inventory UI — drop leaves the item in the world; destroy does not
- A hold-to-confirm pattern (hold for ~1.5s to destroy) avoids a dialog and is consistent with mining hold mechanics
- Alternatively, a simple "Are you sure?" dialog with Yes/No buttons is acceptable

## Activity Log

- 2026-02-28 [producer] Created — deferred from M8; Studio Head requested during M8 playtest
- 2026-03-01 [gameplay-programmer] Starting work — implementing destroy/discard item feature with confirm dialog
- 2026-03-01 [gameplay-programmer] DONE — commit 61f9218 (PR #236 https://github.com/sqlhammer/Hammer-Forge-Studio/pull/236). Implemented destroy action with confirm dialog (DESTROY/CANCEL buttons, CANCEL focused by default). Drop and destroy are distinct actions: [G]/right-click = drop, [Enter] = destroy with confirmation. Added 5 unit tests for destroy behavior.
