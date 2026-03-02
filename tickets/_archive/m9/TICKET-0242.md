---
id: TICKET-0242
title: "BUG — Gamepad right stick turn sensitivity too slow"
type: BUG
status: DONE
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-03-01
updated_at: 2026-03-01
milestone: "M9"
phase: "Gamepad Bugs"
depends_on: [TICKET-0235]
blocks: []
tags: [gamepad, input, camera, sensitivity, bug]
---

## Summary

Turning with the right stick is far too slow to be playable. A full deflection of the right stick produces a barely-perceptible rotation rate.

## Root Cause

In `game/scripts/gameplay/player_first_person.gd`, `_update_look()`, the gamepad look rate is computed as:

```gdscript
var yaw_delta: float = look_input.x * camera_sensitivity * 60.0
var pitch_delta: float = look_input.y * camera_sensitivity * 60.0
```

`camera_sensitivity` is exported at `0.003` — a value tuned for raw mouse pixel deltas, which arrive at a much higher rate and magnitude than a normalized [-1, 1] analog stick. At full stick deflection the effective turn rate is `0.003 × 60 = 0.18 rad/frame`, which is unacceptably slow for a gamepad.

`InputManager` already exposes `gamepad_sensitivity_x` and `gamepad_sensitivity_y` (both default `1.0`), but the player script never reads them.

## Acceptance Criteria

- [x] Right stick produces a comfortable turn rate at default settings (full deflection completes a 360° horizontal rotation in approximately 2–4 seconds).
- [x] `InputManager.gamepad_sensitivity_x` and `gamepad_sensitivity_y` are applied to the gamepad look calculation.
- [x] Default values for `InputManager.gamepad_sensitivity_x` and `gamepad_sensitivity_y` are raised to a playable baseline (suggested: `3.0` horizontal, `2.0` vertical).
- [x] Mouse look speed is unaffected.
- [x] Existing unit tests pass.

## Implementation Notes

**Files:**
- `game/autoloads/InputManager.gd` — update default values of `gamepad_sensitivity_x` / `gamepad_sensitivity_y`
- `game/scripts/gameplay/player_first_person.gd` — apply those values in `_update_look()`

In `_update_look()`, the gamepad look branch should multiply by the InputManager sensitivity:

```gdscript
var yaw_delta: float = look_input.x * camera_sensitivity * 60.0 * InputManager.gamepad_sensitivity_x
var pitch_delta: float = look_input.y * camera_sensitivity * 60.0 * InputManager.gamepad_sensitivity_y
```

Set the new exported defaults in `InputManager.gd`:

```gdscript
@export var gamepad_sensitivity_x: float = 3.0
@export var gamepad_sensitivity_y: float = 2.0
```

These remain `@export` so they can be tuned from the editor inspector without code changes.

## Activity Log

- 2026-03-01 [producer] Created ticket — player-reported: right stick turning is far too slow
- 2026-03-01 [gameplay-programmer] Starting work — dependency TICKET-0235 verified DONE
- 2026-03-01 [gameplay-programmer] DONE — raised gamepad_sensitivity_x to 3.0, gamepad_sensitivity_y to 2.0, applied InputManager sensitivities in _update_camera(). Mouse look unaffected. Commit e740fc0, PR https://github.com/sqlhammer/Hammer-Forge-Studio/pull/266
