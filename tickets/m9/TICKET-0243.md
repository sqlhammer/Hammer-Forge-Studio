---
id: TICKET-0243
title: "BUG — Interaction prompt HUD does not switch to gamepad button hint when gamepad is active"
type: BUG
status: OPEN
priority: P2
owner: gameplay-programmer
created_by: producer
created_at: 2026-03-01
updated_at: 2026-03-01
milestone: "M9"
phase: "Gamepad Bugs"
depends_on: [TICKET-0235, TICKET-0244]
blocks: []
tags: [gamepad, input, hud, interaction-prompt, bug]
---

## Summary

When the interaction prompt HUD is visible and the player switches to a gamepad, the key badge continues to display the keyboard key (e.g., "E"). It should dynamically switch to show the mapped gamepad button (e.g., "A") when the gamepad is the active input device.

## Root Cause

Two compounding issues:

1. **`get_action_key_label()` is keyboard-only.** The method iterates `InputMap.action_get_events(action)` and returns only the first `InputEventKey` it finds. It never reads `InputEventJoypadButton` events, so it always returns the keyboard binding regardless of active device.

2. **No signal connection for device changes.** The HUD never connects to `InputManager.input_device_changed`, so even if the label lookup were device-aware, the displayed text would not refresh when the player picks up a controller.

## Acceptance Criteria

- [ ] When a gamepad is the active input device, the interaction prompt key badge displays the mapped gamepad button name (e.g., "A" for `JOY_BUTTON_A`).
- [ ] When the player switches back to keyboard, the badge reverts to the keyboard key (e.g., "E").
- [ ] The persistent headlamp control hint also updates when the device switches.
- [ ] The refresh happens within the same frame the device change is detected (driven by the signal, not polling).
- [ ] Existing unit tests pass. Add a test for the device-aware label lookup if coverage is absent.

## Implementation Notes

**File:** `game/scripts/ui/interaction_prompt_hud.gd`

### 1. Add a device-aware label lookup

Replace or extend `get_action_key_label()` to be device-aware:

```gdscript
## Returns the human-readable label for the given action based on the current input device.
func get_action_input_label(action: String) -> String:
    if InputManager.get_current_input_device() == "gamepad":
        return _get_action_joypad_label(action)
    return get_action_key_label(action)

func _get_action_joypad_label(action: String) -> String:
    var events: Array[InputEvent] = InputMap.action_get_events(action)
    for event: InputEvent in events:
        if event is InputEventJoypadButton:
            return _joy_button_name(event.button_index)
    return "?"

func _joy_button_name(button: int) -> String:
    match button:
        JOY_BUTTON_A:       return "A"
        JOY_BUTTON_B:       return "B"
        JOY_BUTTON_X:       return "X"
        JOY_BUTTON_Y:       return "Y"
        JOY_BUTTON_LEFT_SHOULDER:  return "LB"
        JOY_BUTTON_RIGHT_SHOULDER: return "RB"
        JOY_BUTTON_START:   return "Start"
        JOY_BUTTON_BACK:    return "Back"
        _:                  return "?"
```

### 2. Connect to device-change signal

In `_ready()`, connect to `InputManager.input_device_changed`:

```gdscript
InputManager.input_device_changed.connect(_on_input_device_changed)
```

Add the handler:

```gdscript
func _on_input_device_changed(_device: String) -> void:
    # Force a prompt content refresh on next frame
    _current_prompt = {}
    _refresh_headlamp_key_label()
```

Resetting `_current_prompt` to an empty dict ensures `_update_prompt_display()` will call `_apply_prompt_content()` on the next `_process()` tick and re-evaluate the key label.

### 3. Update `_apply_prompt_content()`

Change the key label resolution to use the new device-aware method:

```gdscript
func _apply_prompt_content(prompt: Dictionary) -> void:
    var action: String = prompt.get("action", "interact") as String
    var key_text: String = get_action_input_label(action)
    ...
```

Ensure the prompt dictionary includes an `"action"` key so the HUD knows which action to look up. If the prompt dict uses a hardcoded `"key"` string today, that path is still valid as a fallback when no action key is provided.

## Activity Log

- 2026-03-01 [producer] Created ticket — player-reported: interaction prompt always shows keyboard key even on gamepad; depends on TICKET-0244 (interact must be mapped to a gamepad button before label can be shown)
