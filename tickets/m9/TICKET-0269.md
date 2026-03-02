---
id: TICKET-0269
title: "FEATURE: Wire InventoryActionPopup into inventory screen — Y button, grid pause, hint bar, gamepad controls descriptor"
type: FEATURE
status: IN_PROGRESS
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-03-02
updated_at: 2026-03-02
milestone: "M9"
phase: "Gamepad Bugs"
depends_on: [TICKET-0268]
blocks: []
tags: [gamepad, inventory, popup, ui, drop, destroy, controls-hint, uat]
---

## Summary

Wire the `InventoryActionPopup` scene (TICKET-0268) into the inventory screen. This covers: opening the popup with the **Y** gamepad button, pausing grid navigation while the popup is open, routing popup signals to the existing drop/destroy logic, updating the controls hint bar, and replacing the static keyboard-only controls descriptor at the bottom of the inventory with a device-aware version.

## Design Reference

See `docs/studio/design-proposals/gamepad-inventory-actions.md` — **Modified Option B** section.

## Acceptance Criteria

### Popup trigger
- [ ] Pressing **Y (JOY_BUTTON_Y)** while a slot is focused opens `InventoryActionPopup` for the focused slot index.
- [ ] Pressing Y with no slot focused does nothing (popup does not open).
- [ ] No existing keyboard shortcut (G, Enter, Right-click) is removed or broken.

### Grid input pause
- [ ] While the popup is open, stick/D-pad navigation input does **not** move the focused slot in the grid beneath.
- [ ] When the popup closes (either via action or cancel), grid navigation resumes immediately from the previously focused slot.

### Action routing
- [ ] `action_requested("drop", slot_index)` → calls the existing drop logic (the same path triggered by G / right-click today, as implemented in TICKET-0218).
- [ ] `action_requested("destroy", slot_index)` → calls the existing destroy logic (the same path triggered by Enter / confirm today, as implemented in TICKET-0219). The popup's built-in hold-to-confirm in TICKET-0268 replaces the keyboard confirm dialog for gamepad — the underlying inventory destroy method is called directly without re-prompting.

### Controls descriptor (bottom bar)
- [ ] When **keyboard/mouse** is the active device, the existing descriptor is shown unchanged:
  `[G] Drop | [Enter/A] Destroy | [Right-Click] Drop`
- [ ] When **gamepad** is the active device, the descriptor updates to:
  `[Y] Actions`
- [ ] The descriptor updates dynamically when the player switches device mid-session (no scene reload required), consistent with the device-detection system from TICKET-0267.
- [ ] If no slot is focused, the descriptor is hidden or blank on both devices.

### Hint bar (while popup is open)
- [ ] While the popup is open, the persistent HUD hint bar (bottom-right) temporarily displays:
  `[A] Confirm / Hold to Destroy   [B] Cancel   D-pad ↑↓ Navigate`
- [ ] When the popup closes, the hint bar reverts to the standard gameplay hints.

### Tests
- [ ] Unit tests cover: Y press opens popup for focused slot, Y press with no focus is a no-op, drop signal routes to drop logic, destroy signal routes to destroy logic, grid navigation is blocked while popup is open and resumes after close, controls descriptor shows correct text per device.
- [ ] Full test suite passes with no new failures.

## Implementation Notes

**Files likely touched:**
- `game/scenes/ui/inventory_screen.tscn` — add `InventoryActionPopup` as a child node
- `game/scripts/ui/inventory_screen.gd` — primary wiring location
- `game/scripts/ui/game_hud.gd` (or `controls_hint.gd`) — hint bar override while popup is open

**Key wiring pattern:**

```gdscript
# In inventory_screen.gd

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_action_menu"):   # bind Y to this action
        if _focused_slot_index >= 0:
            _action_popup.show_for_slot(_focused_slot_index)
            set_process_unhandled_input(false)       # pause grid input

func _on_action_popup_action_requested(action: String, slot_index: int) -> void:
    set_process_unhandled_input(true)
    if action == "drop":
        _handle_drop(slot_index)
    elif action == "destroy":
        _handle_destroy(slot_index)   # call existing path directly, no re-prompt

func _on_action_popup_cancelled() -> void:
    set_process_unhandled_input(true)
```

**New input action:** Add `ui_action_menu` to `InputManager._setup_input_actions()` with `JOY_BUTTON_Y` binding (no keyboard equivalent needed — keyboard users already have G and Enter).

**Controls descriptor:** Add a `_refresh_controls_descriptor()` method (or extend the existing device-refresh path from TICKET-0267) that checks `InputManager.current_device` and swaps the descriptor text accordingly.

## Activity Log

- 2026-03-02 [producer] Filed — depends on TICKET-0268 (popup component). Completes the Option B gamepad inventory action implementation.
- 2026-03-02 [gameplay-programmer] Starting work — TICKET-0268 is DONE, all dependencies satisfied.
