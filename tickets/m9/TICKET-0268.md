---
id: TICKET-0268
title: "FEATURE: Implement InventoryActionPopup scene for gamepad item actions"
type: FEATURE
status: DONE
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-03-02
updated_at: 2026-03-02
milestone: "M9"
phase: "Gamepad Bugs"
depends_on: []
blocks: [TICKET-0269]
tags: [gamepad, inventory, popup, ui, drop, destroy, uat]
---

## Summary

Create a self-contained `InventoryActionPopup` Control scene that presents a small action menu over the focused inventory slot. This is the core reusable component for **Option B** of the gamepad inventory action design (see `docs/studio/design-proposals/gamepad-inventory-actions.md`).

The popup is responsible for its own focus management, D-pad/stick navigation, hold-to-confirm on the Destroy row, and emitting action signals. It does **not** directly call drop/destroy logic — that is wired in TICKET-0269.

## Design Reference

See `docs/studio/design-proposals/gamepad-inventory-actions.md` — **Modified Option B** section.

Final layout:

```
         ┌──────────────────────┐
         │    Item Actions      │
         ├──────────────────────┤
         │ ▶ Drop Item    [A]   │
         │   Destroy      [A]▓▓ │  ← hold A to fill; release = confirm
         │   Cancel       [B]   │
         └──────────────────────┘

   Navigation: D-pad ↑↓ or left stick ↑↓  (edge-triggered per TICKET-0265)
   Confirm: [A]   Cancel/Close: [B] or [Y]
```

Hint bar while popup is open:
```
   [A] Confirm / Hold to Destroy   [B] Cancel   D-pad ↑↓ Navigate
```

## Acceptance Criteria

- [x] Scene exists at `game/scenes/ui/inventory_action_popup.tscn` with script `game/scripts/ui/inventory_action_popup.gd`.
- [x] Popup displays three rows: **Drop Item**, **Destroy**, **Cancel**. Default focus is on **Drop Item**.
- [x] D-pad up/down and left stick (edge-triggered, per TICKET-0265 pattern) navigate between rows.
- [x] Pressing **A** on "Drop Item" emits `action_requested("drop", slot_index)` and closes the popup.
- [x] Pressing **A** on "Cancel" (or pressing **B** or **Y** at any time) emits `cancelled` and closes the popup.
- [x] "Destroy" row uses **hold-to-confirm**: holding **A** while "Destroy" is focused fills a visible progress bar on the row over **0.8 seconds**. Releasing before full cancels the hold without action. Completing the hold emits `action_requested("destroy", slot_index)` and closes the popup.
- [x] The popup traps all navigation and action input while open — no input leaks to the inventory grid underneath.
- [x] `slot_index: int` is passed in at open time via a `show_for_slot(index: int)` method.
- [x] The popup is hidden (`hide()`) by default; calling `show_for_slot(index)` makes it visible and gives it focus.
- [x] Keyboard fallback: the popup also responds to arrow keys (up/down) for navigation and Enter/Escape for confirm/cancel, so it is testable without a gamepad.
- [x] Unit tests cover: correct signal emitted for each row, hold-to-destroy cancels on early release, B/Y closes without action.

## Signals

```gdscript
signal action_requested(action: String, slot_index: int)
signal cancelled()
```

## Implementation Notes

- Style the popup using existing Panel and Label theme variants from `ui-style-guide.md` — do not introduce new theme properties.
- The hold-to-destroy progress fill can be a simple `ColorRect` overlaid on the Destroy row, scaled in X from 0.0 to 1.0 via a `@onready` reference updated in `_process`. Reset to 0.0 on row change or release.
- Use a `_stick_nav_latched` bool per axis (same pattern as TICKET-0265) for edge-triggered stick navigation inside the popup.
- The popup does **not** need to know what item is in the slot — only the `slot_index` so it can pass it through the signal.

## Activity Log

- 2026-03-02 [producer] Filed — Studio Head approved Option B (Modified) from design proposal TICKET-0266. This ticket implements the popup component; TICKET-0269 handles integration.
- 2026-03-02 [gameplay-programmer] Starting work — all dependencies satisfied (none), implementing InventoryActionPopup scene and script.
- 2026-03-02 [gameplay-programmer] DONE — Implementation complete. Commit 97319c1, PR #296 (merged). Created inventory_action_popup.gd/.tscn and unit tests. All acceptance criteria met.
