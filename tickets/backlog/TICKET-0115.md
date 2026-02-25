---
id: TICKET-0115
title: "Refactor — Carriable items (Spare Battery, Head Lamp) as standalone instanced scenes"
type: REFACTOR
status: TODO
priority: P2
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-25
updated_at: 2026-02-25
milestone: ""
phase: ""
depends_on: []
blocks: []
tags: [scene-design, items, spare-battery, head-lamp, refactor, standards]
---

## Summary
Per the updated Scene Design standard, every conceptual game object must be its own self-contained `.tscn` scene. Spare Battery (`spare_battery.gd`) and Head Lamp (`head_lamp.gd`) are distinct carriable/equippable items with logic scripts but no corresponding `.tscn` scene files. This ticket creates a standalone scene for each.

## Acceptance Criteria
- [ ] `game/scenes/objects/spare_battery.tscn` — root `RigidBody3D` (pickupable world item) with `spare_battery.gd` attached; `CollisionShape3D`; `MeshInstance3D` child (placeholder acceptable)
- [ ] `game/scenes/objects/head_lamp.tscn` — root `Node3D` (equipment attached to player) with `head_lamp.gd` attached; `SpotLight3D` child named `LampLight`; `MeshInstance3D` child (placeholder acceptable)
- [ ] `spare_battery.tscn` has an `Area3D` named `PickupArea` for player interaction range
- [ ] Both scenes are independently openable and runnable in the Godot editor without errors
- [ ] Existing scripts (`spare_battery.gd`, `head_lamp.gd`) are not modified — only scene wrappers are added
- [ ] Player scene(s) instance `head_lamp.tscn` as an equipment child; world spawn points instance `spare_battery.tscn` as a droppable item
- [ ] All code follows `docs/engineering/coding-standards.md`

## Implementation Notes
- Spare Battery is a pickupable field item — `RigidBody3D` root lets it sit naturally on the ground and react to physics; set `freeze = true` until picked up
- Head Lamp is permanently attached to the player suit — `Node3D` root is appropriate since it is not a free-standing physics object
- Meshes for both items are likely placeholders (colored primitive meshes); visual polish is a future task
- The `LampLight` (`SpotLight3D`) in `head_lamp.tscn` should be visible=false by default; the toggle mechanic in `head_lamp.gd` controls visibility at runtime

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-25 [producer] Created ticket — standards refactor, self-contained scene rule
