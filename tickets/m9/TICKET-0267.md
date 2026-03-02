---
id: TICKET-0267
title: "BUG: HUD controls indicator shows keyboard keys when gamepad is the active controller"
type: BUG
status: TODO
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-03-02
updated_at: 2026-03-02
milestone: "M9"
phase: "Gamepad Bugs"
depends_on: []
blocks: []
tags: [bug, gamepad, hud, input, controls-hint, uat-rejection]
---

## Summary

The bottom-right HUD panel always displays keyboard key labels regardless of the active input device:

| HUD label | Keyboard | Gamepad (currently shown) | Gamepad (correct) |
|-----------|----------|--------------------------|-------------------|
| Ping      | Q        | Q                        | gamepad button    |
| Inventory | I        | I                        | Select / Back     |
| Jump      | Space    | Space                    | A / Cross         |
| Headlamp  | F        | F                        | gamepad button    |

When the player switches to a gamepad, the hint labels should update to reflect the bound gamepad buttons. As-is, a gamepad player sees "I for Inventory" and "Space for Jump" — neither of which applies.

Discovered during Studio Head UAT.

## Reproduction Steps

1. Launch the game with a gamepad connected.
2. Enter gameplay (load into a biome).
3. Touch the gamepad to make it the active controller.
4. Look at the bottom-right HUD controls indicator.
5. Observe: it still shows `Q`, `I`, `Space`, `F` — keyboard keys.

## Expected Behavior

When the gamepad is the active input device (`InputManager.current_device == "gamepad"` or equivalent), the HUD hint labels update to show the gamepad button bound to each action:

- **Ping**: the button bound to the `ping` action (e.g., `LB` / `L1`)
- **Inventory**: the button bound to `inventory_toggle` (e.g., `Select`)
- **Jump**: the button bound to `jump` (e.g., `A` / `Cross`)
- **Headlamp**: the button bound to `toggle_headlamp` (e.g., a face or shoulder button)

The labels must update dynamically when the player switches between keyboard/mouse and gamepad mid-session.

## Actual Behavior

HUD hint labels are static keyboard strings; they never update when a gamepad is detected.

## Acceptance Criteria

- [ ] When gamepad is active, each HUD hint label displays the gamepad button bound to that action instead of the keyboard key.
- [ ] When keyboard/mouse is active, keyboard labels are shown as before.
- [ ] Switching between keyboard and gamepad mid-session updates the labels without requiring a scene reload.
- [ ] If an action has no binding for the active device, the hint label is hidden or shows `—` rather than showing the wrong device's binding.
- [ ] Existing unit tests pass.

## Implementation Notes

`InputManager` already tracks the active device (check `InputManager.current_device` or an equivalent signal/property). The HUD hint component (likely in `game_hud.gd` or a dedicated `controls_hint.gd`) should:

1. Connect to `InputManager`'s device-changed signal (or poll in `_process`).
2. On device change, query `InputMap.action_get_events(action_name)` and filter for the event type matching the active device (`InputEventKey` for keyboard, `InputEventJoypadButton` for gamepad).
3. Format the event as a short label string (e.g., `"A"`, `"Select"`, `"LB"`).
4. Update each hint label node's text.

A helper function `get_action_label(action_name: String, device: String) -> String` centralizing this logic is recommended to keep the HUD node clean.

## Activity Log

- 2026-03-02 [producer] Filed — UAT rejection. Studio Head reported HUD bottom-right controls indicator always shows keyboard keys (I, Q, Space, F) even when gamepad is the active controller. Labels must be device-aware.
