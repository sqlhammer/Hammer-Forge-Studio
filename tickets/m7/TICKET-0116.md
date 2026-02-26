---
id: TICKET-0116
title: "Refactor — Mining drone as a standalone instanced scene"
type: REFACTOR
status: TODO
priority: P2
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-25
updated_at: 2026-02-26
milestone: "M7"
phase: "Refactoring"
depends_on: []
blocks: []
tags: [scene-design, drone, automation, refactor, standards]
---

## Summary
Per the updated Scene Design standard, every conceptual game object must be its own self-contained `.tscn` scene. The Mining Drone is a distinct autonomous agent with a logic script (`drone_controller.gd`) but no corresponding `.tscn` scene. This ticket creates `mining_drone.tscn`.

## Acceptance Criteria
- [ ] `game/scenes/objects/mining_drone.tscn` created — root `CharacterBody3D` (drone navigates the world) with `drone_controller.gd` attached
- [ ] `CollisionShape3D` child appropriate for the drone's physical footprint
- [ ] `MeshInstance3D` child for the drone visual (placeholder box mesh acceptable)
- [ ] `Marker3D` named `MiningPoint` indicating the drone's active drill position offset
- [ ] Scene is independently openable and runnable in the Godot editor without errors
- [ ] `drone_manager.gd` and `automation_hub.gd` instantiate `mining_drone.tscn` at runtime rather than creating nodes procedurally
- [ ] Existing scripts (`drone_controller.gd`, `drone_manager.gd`) are not modified beyond the scene path reference update
- [ ] All code follows `docs/engineering/coding-standards.md`

## Implementation Notes
- `CharacterBody3D` root is appropriate because the drone moves through the world and may need collision response; adjust if navigation does not require it
- The drone scene is spawned at runtime by `DroneManager` — ensure the scene path is exported or defined as a constant in `drone_manager.gd`
- `drone_controller.gd` configures drone behavior via `DroneProgramResource` data objects — the scene wrapper does not need to change this contract
- Visual polish (proper drone mesh) is a future task; placeholder geometry is acceptable for this refactor

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-25 [producer] Created ticket — standards refactor, self-contained scene rule
- 2026-02-26 [producer] Scheduled into M7 — Ship Interior milestone
