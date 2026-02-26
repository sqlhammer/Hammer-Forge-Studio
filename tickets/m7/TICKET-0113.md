---
id: TICKET-0113
title: "Refactor — Ship machines as standalone instanced scenes (Recycler, Fabricator, Automation Hub)"
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
tags: [scene-design, ship-machines, recycler, fabricator, automation-hub, refactor, standards]
---

## Summary
Per the updated Scene Design standard, every conceptual game object must be its own self-contained `.tscn` scene. The three ship machines — Recycler, Fabricator, and Automation Hub — each have scripts (`recycler.gd`, `fabricator.gd`, `automation_hub.gd`) but no corresponding `.tscn` scenes. They are currently placed inline or procedurally rather than as proper instanced scenes. This ticket creates a standalone scene for each machine.

## Acceptance Criteria
- [ ] `game/scenes/objects/recycler.tscn` — root node with `recycler.gd` attached, `Area3D` interaction zone named `InteractionArea`, and mesh child (placeholder or GLB reference)
- [ ] `game/scenes/objects/fabricator.tscn` — same structure with `fabricator.gd`; reference the Fabricator GLB mesh from M5 asset production
- [ ] `game/scenes/objects/automation_hub.tscn` — same structure with `automation_hub.gd`
- [ ] Each scene has a `Marker3D` named `PlayerStandPoint` indicating where the player should stand during interaction
- [ ] `ship_interior.tscn` instances each machine scene at its correct interior position — machines are not defined inline
- [ ] All three scenes are independently openable and runnable in the Godot editor without errors
- [ ] Existing machine scripts (`recycler.gd`, `fabricator.gd`, `automation_hub.gd`) are not modified — only the scene wrappers are added
- [ ] All code follows `docs/engineering/coding-standards.md`

## Implementation Notes
- Root node type for each machine: `Node3D` (machines are not physics bodies; the player walks up to them)
- The `InteractionArea` (`Area3D`) with a `CollisionShape3D` defines the region where the player can trigger the interaction UI — export the shape size so it can be tuned per machine
- Fabricator 3D mesh was produced in TICKET-0067; use that asset as the `MeshInstance3D` child
- Recycler and Automation Hub meshes may still be placeholders (greybox cubes) — that is acceptable for this refactor ticket; visual polish is a future task
- After this ticket, `ship_interior.tscn` should instance all three scenes and position them in the interior layout

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-25 [producer] Created ticket — standards refactor, self-contained scene rule
- 2026-02-26 [producer] Scheduled into M7 — Ship Interior milestone
- 2026-02-26 [gameplay-programmer] Starting work — creating standalone machine scenes
