---
id: TICKET-0241
title: "BUG — Gamepad left stick Y-axis inverted (push down goes forward)"
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
tags: [gamepad, input, movement, bug]
---

## Summary

Pushing the left stick **down** moves the player forward. The convention should be: push **up** (toward the top of the controller) = move forward, push **down** = move backward.

## Root Cause

In `game/scripts/gameplay/player_first_person.gd`, `_update_movement()`, the gamepad path reads the left stick via `InputManager.get_analog_input("left")`, which returns the raw `JOY_AXIS_LEFT_Y` value. On standard gamepads, pushing the stick **up** (forward) produces a **negative** Y value; pushing **down** produces a positive Y. The movement code applies `input_vector.y` positively for forward motion, meaning the axis polarity is reversed.

## Acceptance Criteria

- [x] Pushing the left stick up (toward the top of the controller) moves the player forward.
- [x] Pulling the left stick down moves the player backward.
- [x] Keyboard movement (W/S) is unaffected.
- [x] The fix is consistent: if `invert_gamepad_look_y` exists as a separate option, movement Y is not entangled with it.
- [x] Existing unit tests pass.

## Implementation Notes

**File:** `game/scripts/gameplay/player_first_person.gd` — `_update_movement()` method.

The gamepad branch currently reads:
```gdscript
input_vector = InputManager.get_analog_input("left")
```

The Y component must be negated to align physical "push forward" with positive-Y-means-forward:
```gdscript
input_vector = InputManager.get_analog_input("left")
input_vector.y = -input_vector.y
```

Do not negate inside `InputManager.get_analog_input()` — the raw axis value should remain faithful to hardware there. The sign correction belongs in the consumer (player script) where the axis-to-world-direction mapping is defined.

## Activity Log

- 2026-03-01 [producer] Created ticket — player-reported: pushing left stick down goes forward
- 2026-03-01 [gameplay-programmer] Starting work — dependency TICKET-0235 verified DONE
- 2026-03-01 [gameplay-programmer] DONE — negated input_vector.y in gamepad branch of _update_movement(). Commit ad980f3, PR https://github.com/sqlhammer/Hammer-Forge-Studio/pull/263 (merged)
