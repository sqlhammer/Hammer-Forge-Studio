---
id: TICKET-0174
title: "Player jump — 50% player height, first-person and third-person controllers"
type: FEATURE
status: DONE
priority: P2
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "M8"
phase: "Gameplay"
depends_on: []
blocks: []
tags: [player, movement, jump, first-person, third-person, m8-gameplay]
---

## Summary

Add a jump action to both the first-person and third-person player controllers. Jump height is 50% of the player's standing height. The jump must be bound to an input action and must work in both camera modes.

## Acceptance Criteria

- [x] Jump input action defined in InputMap (default key: Space)
- [x] First-person controller: pressing jump applies vertical impulse, player rises to 50% of standing height
- [x] Third-person controller: same jump behaviour, camera follows correctly
- [x] Jump is only possible when the player is on the ground (no double-jump)
- [x] Jump does not interfere with existing movement, scanning, or mining inputs
- [x] Jump input surfaced in the interaction prompt HUD controls panel
- [x] Unit tests cover: jump height within tolerance of 50% player height, ground-only constraint, both controller modes
- [x] Full test suite passes

## Implementation Notes

- Player standing height is defined in the CharacterBody3D collision shape — derive jump height from that value, do not hardcode a pixel/unit number
- Use Godot's `is_on_floor()` for ground detection
- Jump impulse: `velocity.y = sqrt(2 * gravity * jump_height)` for physics-correct height
- Jump input was already registered in InputManager (`_add_action_if_missing("jump", [KEY_SPACE])`)
- PlayerThirdPerson is an orbital camera (Node3D), not a CharacterBody3D — jump lives on PlayerFirstPerson; the orbital camera naturally follows vertical position changes via `set_orbit_center()`
- Jump height derived from `head_height` export var (1.6m default) × `JUMP_HEIGHT_RATIO` (0.5) = 0.8m
- Jump velocity = `sqrt(2 × 9.8 × 0.8)` ≈ 3.96 m/s

## Handoff Notes

**Scripts created/modified:**
- `game/scripts/gameplay/player_first_person.gd` — added `signal player_jumped`, `JUMP_HEIGHT_RATIO` constant, `get_jump_height()`, `get_jump_velocity()`, `try_jump()`, `_update_jump()` methods
- `game/scripts/ui/interaction_prompt_hud.gd` — added `_add_jump_control_row()` using shared `_create_control_row()` factory; resolved merge conflict with headlamp controls from main
- `game/tests/test_player_jump_unit.gd` — 11 unit tests covering constants, formulas, ground constraint, signal, third-person camera follow

**Known limitations:**
- Unit tests for ground-only constraint use non-physics CharacterBody3D (`is_on_floor()` returns false); positive-path jump with physics floor requires integration testing
- UID file for `test_player_jump_unit.gd` pending next Godot editor scan

## Activity Log

- 2026-02-27 [producer] Created — M8 Gameplay phase
- 2026-02-27 [gameplay-programmer] Status → IN_PROGRESS — Starting work on player jump mechanic
- 2026-02-27 [gameplay-programmer] Status → DONE — commit fb6fb19, PR https://github.com/sqlhammer/Hammer-Forge-Studio/pull/147
