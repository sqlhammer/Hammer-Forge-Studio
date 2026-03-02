---
id: TICKET-0244
title: "BUG — No gamepad button mapped to interact action; cannot enter ship with controller"
type: BUG
status: DONE
priority: P0
owner: gameplay-programmer
created_by: producer
created_at: 2026-03-01
updated_at: 2026-03-02
milestone: "M9"
phase: "Gamepad Bugs"
depends_on: [TICKET-0235]
blocks: [TICKET-0243]
tags: [gamepad, input, interact, bug, blocker]
---

## Summary

No gamepad button is mapped to the `interact` action. The player cannot enter the ship (or interact with any interactable) when using a controller, even when standing in the correct trigger zone. Pressing every face button and shoulder button produces no response. The keyboard `E` key works correctly.

## Root Cause

In `game/autoloads/InputManager.gd`, `_setup_input_actions()`, the `interact` action is registered with only a keyboard binding:

```gdscript
_add_action_if_missing("interact", [KEY_E])
```

`_add_action_if_missing()` accepts only `keys: Array` (keyboard) and `mouse_buttons: Array`. It has no parameter for `InputEventJoypadButton`, so there is no path to register a joypad button for any action.

## Acceptance Criteria

- [x] The `interact` action fires when the bottom face button is pressed on a connected gamepad (`JOY_BUTTON_A` — Xbox A / PlayStation Cross).
- [x] The player can enter the ship using the gamepad without touching the keyboard.
- [x] Keyboard `E` binding is preserved alongside the new gamepad binding.
- [x] The same `_add_action_if_missing()` extension (or a new helper) is available for use by other actions that need gamepad bindings in the future.
- [x] Existing unit tests pass.

## Implementation Notes

**File:** `game/autoloads/InputManager.gd`

### 1. Extend `_add_action_if_missing()` to accept joypad buttons

Add a `joy_buttons: Array = []` parameter:

```gdscript
func _add_action_if_missing(
        action_name: String,
        keys: Array = [],
        mouse_buttons: Array = [],
        joy_buttons: Array = []) -> void:
    if InputMap.has_action(action_name):
        return
    InputMap.add_action(action_name)
    for key in keys:
        var event := InputEventKey.new()
        event.keycode = key
        InputMap.action_add_event(action_name, event)
    for button in mouse_buttons:
        var event := InputEventMouseButton.new()
        event.button_index = button
        InputMap.action_add_event(action_name, event)
    for joy_button in joy_buttons:
        var event := InputEventJoypadButton.new()
        event.button_index = joy_button
        InputMap.action_add_event(action_name, event)
```

### 2. Add `JOY_BUTTON_A` to `interact`

Update the registration call:

```gdscript
_add_action_if_missing("interact", [KEY_E], [], [JOY_BUTTON_A])
```

### 3. Scope

Only `interact` is in scope for this ticket. Additional gamepad bindings for other actions (scan, jump, inventory, etc.) should be handled in a follow-up if needed. Do not add bindings speculatively.

## Activity Log

- 2026-03-01 [producer] Created ticket — P0: gamepad has no interact binding; blocks TICKET-0243 (prompt label fix depends on a button existing to display)
- 2026-03-02 [gameplay-programmer] Verified implementation already committed and merged (fc76396, PR #264). _add_action_if_missing() extended with joy_buttons parameter, JOY_BUTTON_A added to interact action. All acceptance criteria met. Marking DONE.
