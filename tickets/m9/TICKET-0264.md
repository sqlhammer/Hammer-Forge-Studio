---
id: TICKET-0264
title: "BUG: Dropping item from inventory deletes it instead of spawning a physical world object"
type: BUG
status: OPEN
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-03-02
updated_at: 2026-03-02
milestone: "M9"
phase: "Root Game"
depends_on: []
blocks: []
tags: [bug, inventory, drop-item, dropped-item, uat-rejection]
---

## Summary

When a player drops an item from inventory (press **G** or right-click on an inventory slot), the item is removed from inventory but no physical object appears in the game world. The item is silently lost — it does not spawn as a `DroppedItem` near the player's feet.

Discovered during Studio Head UAT of TICKET-0218 (Drop Items from Inventory).

## Reproduction Steps

1. Launch with **Begin Wealthy** debug option enabled so inventory contains items.
2. Open inventory (**I**).
3. Select any item slot and press **G** (or right-click → drop).
4. Close inventory and look at the ground near the player.
5. Observe: the item is gone from inventory and no physical object exists in the world.

## Expected Behavior

After dropping, the item is removed from inventory **and** a `DroppedItem` node spawns at the player's feet with a mesh, bobbing animation, and interaction prompt. The player can walk up to it and press **E** to pick it back up.

## Actual Behavior

The item is removed from inventory and disappears entirely. No `DroppedItem` instance is created in the scene.

## Fix Recommendation

Investigate the drop path in `inventory_screen.gd` (or wherever the drop action is handled) and `dropped_item.gd`. Likely causes:

- The `DroppedItem` scene is not being instantiated or added to the scene tree on drop.
- The spawn position is invalid (e.g., `null` player reference, zero vector) causing the item to be placed out of bounds or culled immediately.
- The `DroppedItem` scene resource path is broken after a recent refactor.

Verify that `test_dropped_item_unit.gd` unit tests still pass — if they do, the bug is likely in the scene wiring rather than the core logic.

## Activity Log

- 2026-03-02 [producer] Filed — UAT rejection on TICKET-0218. Studio Head confirmed item is removed from inventory but no world object appears. Item is lost on drop.
