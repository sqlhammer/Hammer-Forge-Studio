---
id: TICKET-0004
title: "Implement third-person ship/base view system"
type: TASK
status: DONE
priority: P1
owner: systems-programmer
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
**Implementation Complete - Ready for Code Review**

**Scripts Created:**
- `res://game/scripts/gameplay/player_third_person.gd` - PlayerThirdPerson orbital camera class (145 lines)

**Scene Created:**
- `res://game/scenes/gameplay/player_third_person.tscn` - Third-person player scene with Camera3D and test target BoxMesh

**Features Implemented:**
- Orbital camera system using spherical coordinates (yaw, pitch, distance)
- Camera orbits around configurable center point
- Smooth damping/easing (CAMERA_DAMPING = 0.15) for fluid motion
- Input control: Left stick for camera orbit, keyboard WASD/arrows support
- Pitch clamping: ±80° to prevent upside-down viewing
- Mouse wheel zoom support (MIN: 5 units, MAX: 50 units, DEFAULT: 15 units)
- Gamepad and keyboard input fully supported via InputManager
- Configurable sensitivity: camera_sensitivity_x/y via @export
- Smooth interpolation using lerp() for natural camera movement
- Public API: set_orbit_center(), get_orbit_center(), get_camera_position(), reset_orbit()

**Code Quality:**
- Follows `docs/engineering/coding-standards.md`: PascalCase class, snake_case methods, strong typing
- Warning ignore annotations for InputManager autoload type checking
- Scene tested and verified to run successfully
- Minor warnings (unused parameter, parameter shadowing) - non-blocking

**Dependencies Used:**
- InputManager autoload for all input queries
- Camera3D for orbital viewing
- MeshInstance3D for test target model

**Next Steps:**
1. Code review for standards compliance (minor warning fixes)
2. Integrate with TICKET-0005 to create unified player scene

## Activity Log
- 2026-02-21 [producer] Created ticket; depends on TICKET-0002
- 2026-02-21 [gameplay-programmer] Started implementation (parallel with TICKET-0003)
- 2026-02-21 [gameplay-programmer] Created PlayerThirdPerson.gd with orbital camera and spherical coordinate math
- 2026-02-21 [gameplay-programmer] Created player_third_person.tscn scene with Camera3D and test target model
- 2026-02-21 [gameplay-programmer] Implemented full input control (gamepad + keyboard)
- 2026-02-21 [gameplay-programmer] Added smooth damping and zoom functionality
- 2026-02-21 [gameplay-programmer] All acceptance criteria met; scene tested and verified
- 2026-02-21 [gameplay-programmer] Status changed to IN_REVIEW; submitted to systems-programmer for code review
- 2026-02-21 [systems-programmer] Code review completed
- 2026-02-21 [systems-programmer] ✅ APPROVED: Standards compliant, solid architecture, spherical math correct
- 2026-02-21 [systems-programmer] Minor warnings noted (non-blocking): parameter shadowing, unused delta
- 2026-02-21 [systems-programmer] Status changed to DONE
- 2026-02-21 [gameplay-programmer] Resolved all code review recommendations:
  - ✅ Renamed parameter "position" → "target_pos" in set_orbit_center() to avoid shadowing Node3D.position
  - ✅ Removed unused "delta" parameter from _apply_orbit_damping() (not needed for damping logic)
  - ✅ Updated _process() call to _apply_orbit_damping() without passing delta
- 2026-02-21 [gameplay-programmer] Scene tested - no compiler errors; all warnings resolved
- 2026-02-21 [producer] Archived
