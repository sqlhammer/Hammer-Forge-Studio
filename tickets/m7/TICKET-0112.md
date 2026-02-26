---
id: TICKET-0112
title: "Refactor — Resource deposit as a standalone instanced scene with type subscenes"
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
tags: [scene-design, deposit, resource, refactor, standards]
---

## Summary
Per the updated Scene Design standard, every conceptual game object must be its own self-contained `.tscn` scene. The resource deposit is currently represented as a raw `.glb` mesh (`assets/meshes/props/mesh_resource_node_scrap.glb`) with no wrapping scene that applies `deposit.gd`. This ticket creates:
- `deposit.tscn` — base scene with `deposit.gd` attached, collision, and scan/mine interaction area
- `deposit_scrap_metal.tscn` — type subscene that inherits from `deposit.tscn` and sets scrap-metal-specific properties

Additional deposit type subscenes (ore, etc.) should follow the same pattern in future tickets as those resource types are defined.

## Acceptance Criteria
- [ ] `game/scenes/objects/deposit.tscn` created — base scene with `StaticBody3D` root, `deposit.gd` attached, `CollisionShape3D`, and an `Area3D` named `ScanArea` for scanner detection
- [ ] `game/scenes/objects/deposit_scrap_metal.tscn` created — inherits `deposit.tscn`, sets the scrap metal mesh and resource type export
- [ ] `deposit.gd` export variables (`resource_type`, `yield_amount`, `yield_randomness`) are set via the inspector in each type subscene — no hardcoding
- [ ] Scene is independently openable and runnable in the Godot editor without errors
- [ ] `test_world.tscn` or any level scene that placed the raw `.glb` directly is updated to instance `deposit_scrap_metal.tscn` instead
- [ ] All code follows `docs/engineering/coding-standards.md`

## Implementation Notes
- Base `deposit.tscn` root type: `StaticBody3D` with a `MeshInstance3D` child placeholder; type subscenes override the mesh
- The `ScanArea` (`Area3D`) defines the radius within which the scanner detects this deposit — export the radius so it can be tuned per deposit type
- Subscene inheritance in Godot: create a new scene, set the root node to be an instance of `deposit.tscn`, then save as `deposit_scrap_metal.tscn`
- Reference `scripts/systems/deposit.gd` and `scripts/data/resource_defs.gd` for existing data contracts

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-25 [producer] Created ticket — standards refactor, self-contained scene rule
- 2026-02-26 [producer] Scheduled into M7 — Ship Interior milestone
