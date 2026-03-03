---
id: TICKET-0279
title: "M10 Input — Assign gamepad Right Trigger to 'use_tool'"
type: TASK
status: OPEN
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-03-03
updated_at: 2026-03-03
milestone: "M10"
phase: "Foundation"
depends_on: []
blocks: []
tags: [input, gamepad, mining, interaction-prompt]
---

## Summary

Assign the gamepad Right Trigger (`JOY_AXIS_TRIGGER_RIGHT`) to the `use_tool` action so
players can hold right trigger to mine. Triggers use `InputEventJoypadMotion` rather than
`InputEventJoypadButton`, so this requires:

1. A new helper in `InputManager.gd` to register axis-based actions
2. Updating `interaction_prompt_hud.gd`'s joypad label lookup to handle `InputEventJoypadMotion`

---

## Acceptance Criteria

### InputManager.gd — New helper
- [ ] Add a private helper `_add_joy_axis_to_existing_action` that adds an
      `InputEventJoypadMotion` event to an already-registered action:
  ```gdscript
  func _add_joy_axis_to_existing_action(action_name: String, axis: int, axis_value: float = 0.5) -> void:
      if not InputMap.has_action(action_name):
          return
      for existing_event: InputEvent in InputMap.action_get_events(action_name):
          if existing_event is InputEventJoypadMotion:
              var existing_axis: InputEventJoypadMotion = existing_event as InputEventJoypadMotion
              if existing_axis.axis == axis:
                  return
      var event := InputEventJoypadMotion.new()
      event.axis = axis
      event.axis_value = axis_value
      InputMap.action_add_event(action_name, event)
  ```
- [ ] Call it in `_setup_input_actions()` after `use_tool` is registered:
  ```gdscript
  _add_joy_axis_to_existing_action("use_tool", JOY_AXIS_TRIGGER_RIGHT)
  ```

### interaction_prompt_hud.gd — Trigger label support
- [ ] Update `_get_action_joypad_label` to also check for `InputEventJoypadMotion`:
  ```gdscript
  func _get_action_joypad_label(action: String) -> String:
      var events: Array[InputEvent] = InputMap.action_get_events(action)
      for event: InputEvent in events:
          if event is InputEventJoypadButton:
              return _joy_button_name(event.button_index)
          if event is InputEventJoypadMotion:
              return _joy_axis_name(event.axis)
      return "?"
  ```
- [ ] Add a `_joy_axis_name` method:
  ```gdscript
  func _joy_axis_name(axis: int) -> String:
      match axis:
          JOY_AXIS_TRIGGER_LEFT:
              return "LT"
          JOY_AXIS_TRIGGER_RIGHT:
              return "RT"
          _:
              return "?"
  ```

### No Regressions
- [ ] Holding left mouse button still triggers `use_tool` (existing keyboard/mouse mapping unchanged)
- [ ] Holding Right Trigger on gamepad triggers `use_tool` — player can mine
- [ ] HUD displays "RT" (not "?") next to the Mine prompt when on gamepad
- [ ] `mining.gd`'s `is_action_pressed("use_tool")` correctly detects trigger hold — no
      changes needed there; Godot evaluates axis actions against the registered threshold

---

## Implementation Notes

Triggers in Godot 4 are analog axes (`JOY_AXIS_TRIGGER_RIGHT`), not buttons. To register
them as an action event, use `InputEventJoypadMotion` with `axis_value = 0.5` as the
activation threshold (range is 0.0–1.0; 0.5 is a comfortable midpoint that avoids ghost
activation from resting trigger position).

`use_tool` is already registered via `_add_action_if_missing("use_tool", [], [MOUSE_BUTTON_LEFT])`.
Use the new `_add_joy_axis_to_existing_action` helper (rather than changing `_add_action_if_missing`)
to keep the existing registration call untouched.

`deposit.gd` uses `_get_action_key_label("use_tool")` for the Mine prompt — this returns
the keyboard label. The HUD calls `get_action_input_label(action)` which dispatches to
the joypad variant when on gamepad. The fix to `_get_action_joypad_label` in
`interaction_prompt_hud.gd` ensures "RT" is shown correctly on gamepad.

---

## Handoff Notes

(Leave blank until handoff occurs.)

---

## Activity Log

- 2026-03-03 [producer] Created ticket — M10 gamepad: RT→use_tool, trigger axis support
