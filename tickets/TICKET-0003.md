---
id: TICKET-0003
title: "Implement first-person player controller"
type: TASK
status: OPEN
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-21
updated_at: 2026-02-21
milestone: "M1"
depends_on: [TICKET-0002]
blocks: [TICKET-0005]
tags: [player-controller, first-person]
---

## Summary
Implement the first-person player controller that handles character movement (WASD), camera control (mouse/gamepad look), and integration with the InputManager. Controller must be modular and testable independently.

## Acceptance Criteria
- [ ] `res://player/PlayerFirstPerson.gd` created with `class_name PlayerFirstPerson` (extends CharacterBody3D)
- [ ] Movement implemented: forward/backward, strafe left/right via InputManager
- [ ] Camera control working: mouse and analog stick look
- [ ] Gravity and basic physics working (player doesn't fall through ground)
- [ ] Movement speed configurable via @export variables
- [ ] Camera sensitivity configurable via @export variables
- [ ] All input routed through InputManager (no direct Input.is_action_pressed calls)
- [ ] Scene created at `res://player/player_first_person.tscn` with controller script attached
- [ ] All code follows `docs/engineering/coding-standards.md`
- [ ] Debug logging for movement state and input
- [ ] Scene is independently testable and runnable

## Implementation Notes
- Use CharacterBody3D for physics and movement
- Reference InputManager for all input queries
- Implement basic head-bob if time permits (non-blocking)
- Camera should use Node3D transform for look direction
- Consider Y-axis inversion option for gamepad look
- Physics layer assignments in `docs/engineering/physics-layers.md`

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-21 [producer] Created ticket; depends on TICKET-0002
