---
id: TICKET-0270
title: "BUG: Item Actions popup action buttons do nothing when confirmed with gamepad"
type: BUG
status: DONE
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-03-02
updated_at: 2026-03-02
milestone: "M9"
phase: "Gamepad Bugs"
depends_on: [TICKET-0269]
blocks: []
tags: [bug, gamepad, inventory, popup, drop, destroy, uat-rejection]
---

## Summary

The Item Actions popup opens correctly (Y button) and navigation between rows works, but pressing **A** to confirm an action (Drop or Destroy) does nothing. No drop occurs, no destroy occurs, and the popup does not close. The popup appears fully non-functional for its core purpose.

Discovered during Studio Head UAT of the gamepad inventory action feature (TICKET-0268/0269).

## Reproduction Steps

1. Launch with a gamepad connected and **Begin Wealthy** enabled.
2. Open inventory (**Select / Back**).
3. Navigate to any slot with an item.
4. Press **Y** to open the Item Actions popup.
5. Confirm the popup appears with Drop Item, Destroy, and Cancel rows.
6. With "Drop Item" focused, press **A**.
7. Observe: nothing happens — popup remains open, item stays in inventory.
8. Navigate to "Destroy", hold **A** until the progress fill completes.
9. Observe: nothing happens — popup remains open, item stays in inventory.

## Expected Behavior

- Pressing **A** on "Drop Item" drops the item (removes from inventory, spawns in world) and closes the popup.
- Completing the hold on "Destroy" permanently removes the item and closes the popup.

## Actual Behavior

Both actions fire no response. The popup stays open. No inventory state changes.

## Likely Causes

The `action_requested` signal from `InventoryActionPopup` is likely not connected to the handler in `inventory_screen.gd`, or the handler exists but calls a path that silently fails (e.g., invalid slot index, wrong method reference, or missing `await`). Also check:

- Whether `InventoryActionPopup.action_requested` is connected at all (missing `connect()` call in `inventory_screen.gd`).
- Whether the slot index passed via `show_for_slot(index)` is valid at the time the action fires.
- Whether the input action `"ui_accept"` / `JOY_BUTTON_A` is being consumed by the popup's `_unhandled_input` or if it is falling through to the parent.

## Acceptance Criteria

- [x] Pressing **A** on "Drop Item" drops the item and closes the popup.
- [x] Completing the hold on "Destroy" destroys the item and closes the popup.
- [x] The popup closes after any successful action.
- [x] Keyboard equivalents (Enter on Drop/Destroy) still function correctly.
- [x] Existing unit tests pass; add a new integration test if the signal connection was the root cause.

## Activity Log

- 2026-03-02 [producer] Filed — UAT rejection. Studio Head confirmed popup opens and navigates correctly but A button produces no action on either Drop or Destroy rows.
- 2026-03-02 [gameplay-programmer] Starting work — TICKET-0269 is DONE, dependency satisfied. Root cause identified: Godot 4 built-in ui_accept does not include JOY_BUTTON_A by default, and InputManager._add_action_if_missing() skips existing actions. Fix: add helper to InputManager that adds joypad events to existing built-in actions.
- 2026-03-02 [gameplay-programmer] DONE — Fixed shared root cause with TICKET-0271. Added _add_joy_button_to_existing_action() to InputManager, mapping JOY_BUTTON_A → ui_accept and JOY_BUTTON_B → ui_cancel. Added 2 regression tests. Commit db4d0eb (branch), merge commit e95592e (main), PR #300 (merged).
