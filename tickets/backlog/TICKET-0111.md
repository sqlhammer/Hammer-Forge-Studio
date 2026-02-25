---
id: TICKET-0111
title: "Refactor — Ship exterior as a standalone instanced scene"
type: REFACTOR
status: TODO
priority: P2
owner: technical-artist
created_by: producer
created_at: 2026-02-25
updated_at: 2026-02-25
milestone: ""
phase: ""
depends_on: []
blocks: []
tags: [scene-design, ship, refactor, standards]
---

## Summary
Per the updated Scene Design standard in `docs/engineering/coding-standards.md`, every conceptual game object must be its own self-contained `.tscn` scene. The ship exterior is currently represented only as a raw `.glb` mesh (`assets/meshes/vehicles/mesh_ship_exterior.glb`) with no wrapping scene. This ticket creates the canonical `ship_exterior.tscn` that wraps the GLB with a proper root node, collision, any required interaction areas, and future script hooks.

## Acceptance Criteria
- [ ] `game/scenes/objects/ship_exterior.tscn` created with a `StaticBody3D` (or appropriate type) root node
- [ ] The `mesh_ship_exterior.glb` is instantiated as a child of the scene root — not duplicated
- [ ] Collision shape(s) added appropriate to the mesh bounds
- [ ] Scene is independently openable and runnable in the Godot editor without errors
- [ ] Any scene that previously referenced the raw `.glb` directly (e.g., `test_world.tscn`, `test_m2_assets.tscn`) is updated to instance `ship_exterior.tscn` instead
- [ ] All code follows `docs/engineering/coding-standards.md`

## Implementation Notes
- Root node type: use `StaticBody3D` if the ship is a fixed world object, or `Node3D` with a child `StaticBody3D` if more hierarchy is needed for future interaction areas
- Leave a placeholder `Marker3D` named `EntranceDoor` for the ship entry/exit point (used by the player entry mechanic)
- This scene is the exterior-facing shell; ship interior machinery is a separate scene (`ship_interior.tscn`)
- The scene folder `game/scenes/objects/` is the canonical location for world-object scenes; create it if it does not exist

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-25 [producer] Created ticket — standards refactor, self-contained scene rule
