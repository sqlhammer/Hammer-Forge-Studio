---
id: TICKET-0004
title: "Implement third-person ship/base view system"
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
tags: [player-controller, third-person, ship-view]
---

## Summary
Implement a third-person orbital camera system for viewing a player-controlled ship or base. System must support orbiting camera control via InputManager, smooth transitions, and independent testability.

## Acceptance Criteria
- [ ] `res://player/PlayerThirdPerson.gd` created with `class_name PlayerThirdPerson` (extends Node3D)
- [ ] Camera orbits around target using analog stick or mouse input
- [ ] Orbit rotation working on both horizontal (yaw) and vertical (pitch) axes
- [ ] Camera distance configurable via @export variables
- [ ] Smooth camera movement and damping implemented
- [ ] All input routed through InputManager
- [ ] Scene created at `res://player/player_third_person.tscn` with a test target model
- [ ] All code follows `docs/engineering/coding-standards.md`
- [ ] Debug logging for camera state
- [ ] Scene is independently testable and runnable

## Implementation Notes
- Use Camera3D node positioned relative to an orbit target
- Implement orbital motion math (spherical coordinates recommended)
- Add camera collision avoidance if obstacles present (stretch goal)
- Sensitivity configurable via @export for both axes
- Consider zoom support (mouse wheel or gamepad trigger)
- Reference InputManager for all camera input

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-21 [producer] Created ticket; depends on TICKET-0002
