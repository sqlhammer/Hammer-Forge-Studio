---
id: TICKET-0174
title: "Player jump — 50% player height, first-person and third-person controllers"
type: FEATURE
status: PENDING
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

- [ ] Jump input action defined in InputMap (default key: Space)
- [ ] First-person controller: pressing jump applies vertical impulse, player rises to 50% of standing height
- [ ] Third-person controller: same jump behaviour, camera follows correctly
- [ ] Jump is only possible when the player is on the ground (no double-jump)
- [ ] Jump does not interfere with existing movement, scanning, or mining inputs
- [ ] Jump input surfaced in the interaction prompt HUD controls panel
- [ ] Unit tests cover: jump height within tolerance of 50% player height, ground-only constraint, both controller modes
- [ ] Full test suite passes

## Implementation Notes

- Player standing height is defined in the CharacterBody3D collision shape — derive jump height from that value, do not hardcode a pixel/unit number
- Use Godot's `is_on_floor()` for ground detection
- Jump impulse: `velocity.y = sqrt(2 * gravity * jump_height)` for physics-correct height

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created — M8 Gameplay phase
