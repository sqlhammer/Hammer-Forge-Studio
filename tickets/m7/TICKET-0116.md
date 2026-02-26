---
id: TICKET-0116
title: "Refactor — Mining drone as a standalone instanced scene"
type: REFACTOR
status: IN_PROGRESS
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
- [x] `game/scenes/objects/mining_drone.tscn` created — root `CharacterBody3D` (drone navigates the world) with `drone_controller.gd` attached
- [x] `CollisionShape3D` child appropriate for the drone's physical footprint
- [x] `MeshInstance3D` child for the drone visual (placeholder box mesh acceptable)
- [x] `Marker3D` named `MiningPoint` indicating the drone's active drill position offset
- [x] Scene is independently openable and runnable in the Godot editor without errors
- [x] `drone_manager.gd` and `automation_hub.gd` instantiate `mining_drone.tscn` at runtime rather than creating nodes procedurally
- [x] Existing scripts (`drone_controller.gd`, `drone_manager.gd`) are not modified beyond the scene path reference update
- [x] All code follows `docs/engineering/coding-standards.md`

## Implementation Notes
- `CharacterBody3D` root is appropriate because the drone moves through the world and may need collision response; adjust if navigation does not require it
- The drone scene is spawned at runtime by `DroneManager` — ensure the scene path is exported or defined as a constant in `drone_manager.gd`
- `drone_controller.gd` configures drone behavior via `DroneProgramResource` data objects — the scene wrapper does not need to change this contract
- Visual polish (proper drone mesh) is a future task; placeholder geometry is acceptable for this refactor

## Handoff Notes
- Created `game/scenes/objects/mining_drone.tscn` — CharacterBody3D root with CollisionShape3D (BoxShape3D 0.8x0.4x1.2), MeshInstance3D (teal placeholder box with emission), and Marker3D named MiningPoint
- Updated `drone_controller.gd`: changed extends from Node3D → CharacterBody3D, removed programmatic `_build_mesh()` method (mesh now lives in scene), removed unused `MESH_SIZE` constant and `_mesh_instance` variable
- Updated `drone_manager.gd`: added `MINING_DRONE_SCENE` constant, replaced `DroneController.new()` with `load(MINING_DRONE_SCENE).instantiate()`
- `automation_hub.gd` was not modified — it creates `DroneAgent` (RefCounted data objects), not physical drone scene nodes; no procedural node creation exists there
- All drone gameplay logic unchanged

## Activity Log
- 2026-02-25 [producer] Created ticket — standards refactor, self-contained scene rule
- 2026-02-26 [producer] Scheduled into M7 — Ship Interior milestone
- 2026-02-26 [gameplay-programmer] Starting work — creating mining_drone.tscn and updating instantiation
