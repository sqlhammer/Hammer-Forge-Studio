---
id: TICKET-0115
title: "Refactor — Carriable items (Spare Battery, Head Lamp) as standalone instanced scenes"
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
tags: [scene-design, items, spare-battery, head-lamp, refactor, standards]
---

## Summary
Per the updated Scene Design standard, every conceptual game object must be its own self-contained `.tscn` scene. Spare Battery (`spare_battery.gd`) and Head Lamp (`head_lamp.gd`) are distinct carriable/equippable items with logic scripts but no corresponding `.tscn` scene files. This ticket creates a standalone scene for each.

## Acceptance Criteria
- [x] `game/scenes/objects/spare_battery.tscn` — root `RigidBody3D` (pickupable world item); `CollisionShape3D`; `MeshInstance3D` child (placeholder). **Note:** `spare_battery.gd` extends `RefCounted` — cannot be attached to any Node type. Scene created without script.
- [x] `game/scenes/objects/head_lamp.tscn` — root `Node3D` (equipment attached to player) with `head_lamp.gd` attached; `SpotLight3D` child named `LampLight`; `MeshInstance3D` child (placeholder)
- [x] `spare_battery.tscn` has an `Area3D` named `PickupArea` for player interaction range
- [x] Both scenes are independently openable and runnable in the Godot editor without errors
- [x] Existing scripts (`spare_battery.gd`, `head_lamp.gd`) are not modified — only scene wrappers are added
- [ ] Player scene(s) instance `head_lamp.tscn` as an equipment child; world spawn points instance `spare_battery.tscn` as a droppable item — **Deferred:** `head_lamp.gd` is an autoload singleton; instancing the scene in the player would duplicate state/drain logic. Requires architectural decision to separate visual scene from autoload state manager. No world spawn points exist for spare_battery.
- [x] All code follows `docs/engineering/coding-standards.md`

## Implementation Notes
- Spare Battery is a pickupable field item — `RigidBody3D` root lets it sit naturally on the ground and react to physics; set `freeze = true` until picked up
- Head Lamp is permanently attached to the player suit — `Node3D` root is appropriate since it is not a free-standing physics object
- Meshes for both items are likely placeholders (colored primitive meshes); visual polish is a future task
- The `LampLight` (`SpotLight3D`) in `head_lamp.tscn` should be visible=false by default; the toggle mechanic in `head_lamp.gd` controls visibility at runtime

## Handoff Notes
**Scenes created:**
- `game/scenes/objects/spare_battery.tscn` — RigidBody3D root, freeze=true, BoxShape3D collision, BoxMesh placeholder, PickupArea (Area3D) with SphereShape3D (radius 1.5). Physics: layer 4 (interactable), mask 3 (environment). PickupArea: layer 4, mask 1 (player).
- `game/scenes/objects/head_lamp.tscn` — Node3D root with head_lamp.gd, SpotLight3D named LampLight (visible=false), BoxMesh placeholder.

**Known limitations:**
1. `spare_battery.gd` extends `RefCounted` (not a Node subclass) — cannot be attached to the RigidBody3D root. A separate scene-specific script (e.g. `spare_battery_world.gd extends RigidBody3D`) would be needed in a follow-up ticket to add pickup interaction logic to the scene.
2. `head_lamp.gd` is registered as an autoload singleton in `project.godot`. Instancing `head_lamp.tscn` in the player scene would create a duplicate Node running the same `_process()` drain logic. A follow-up ticket should either (a) create a separate visual-only scene script that listens to the autoload's signals, or (b) refactor the autoload into a scene-based approach.
3. No world spawn points currently exist for spare_battery instancing.

## Activity Log
- 2026-02-25 [producer] Created ticket — standards refactor, self-contained scene rule
- 2026-02-26 [producer] Scheduled into M7 — Ship Interior milestone
- 2026-02-26 [gameplay-programmer] Starting work — creating standalone scene wrappers for Spare Battery and Head Lamp
