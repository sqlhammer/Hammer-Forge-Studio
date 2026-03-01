---
id: TICKET-0218
title: "Feature — Drop items from inventory onto the ground and pick them back up"
type: FEATURE
status: OPEN
priority: P2
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-28
updated_at: 2026-02-28
milestone: "M9"
phase: "Gameplay Polish"
depends_on: []
blocks: []
tags: [feature, inventory, items, interaction, pickup, m9]
---

## Summary

Players have no way to discard or reposition items carried in their inventory. This ticket adds the ability to drop individual inventory items onto the ground as physical world objects, and to pick dropped items back up by interacting with them.

## Acceptance Criteria

- [ ] Player can drop a selected inventory item from the inventory UI — item is removed from inventory and spawned as a physical object at the player's feet / in front of the player
- [ ] Dropped items have a visible mesh appropriate to the resource type and show an interaction prompt when the player is close
- [ ] Player can pick up a dropped item by interacting with it (E or configured interact key) — item is added back to inventory if space allows
- [ ] If inventory is full when attempting to pick up, the pick-up fails gracefully with an appropriate feedback message
- [ ] Dropped items persist in the biome until picked up or until the biome is unloaded (travel clears dropped items — no cross-biome persistence required)
- [ ] Dropped items do not interfere with deposit scanning or mining raycasts
- [ ] Unit tests cover: drop removes item from inventory, pickup adds item to inventory, full-inventory pick-up rejection, item despawn on biome unload
- [ ] Full test suite passes with no new failures

## Implementation Notes

- A `DroppedItem` scene (e.g., `game/scenes/objects/dropped_item.tscn`) should carry a resource type, purity, and quantity; use a simple `Area3D` + collision shape for interaction detection
- The inventory UI needs a "drop" action per slot (context menu or dedicated key bind)
- Dropped items should register with the biome container so they are cleared on `TravelSequenceManager._clear_biome_container()`
- Consider whether multiple stacks of the same resource dropped separately should merge on pick-up or remain separate items

## Activity Log

- 2026-02-28 [producer] Created — deferred from M8; Studio Head requested during M8 playtest
