---
id: TICKET-0113
title: "Refactor — Ship machines as standalone instanced scenes (Recycler, Fabricator, Automation Hub)"
type: REFACTOR
status: DONE
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
- [x] `game/scenes/objects/recycler.tscn` — root node with `recycler.gd` attached, `Area3D` interaction zone named `InteractionArea`, and mesh child (placeholder or GLB reference)
- [x] `game/scenes/objects/fabricator.tscn` — same structure with `fabricator.gd`; reference the Fabricator GLB mesh from M5 asset production
- [x] `game/scenes/objects/automation_hub.tscn` — same structure with `automation_hub.gd`
- [x] Each scene has a `Marker3D` named `PlayerStandPoint` indicating where the player should stand during interaction
- [x] `ship_interior.tscn` instances each machine scene at its correct interior position — machines are not defined inline
- [x] All three scenes are independently openable and runnable in the Godot editor without errors
- [x] Existing machine scripts (`recycler.gd`, `fabricator.gd`, `automation_hub.gd`) are not modified — only the scene wrappers are added
- [x] All code follows `docs/engineering/coding-standards.md`

## Implementation Notes
- Root node type for each machine: `Node3D` (machines are not physics bodies; the player walks up to them)
- The `InteractionArea` (`Area3D`) with a `CollisionShape3D` defines the region where the player can trigger the interaction UI — export the shape size so it can be tuned per machine
- Fabricator 3D mesh was produced in TICKET-0067; use that asset as the `MeshInstance3D` child
- Recycler and Automation Hub meshes may still be placeholders (greybox cubes) — that is acceptable for this refactor ticket; visual polish is a future task
- After this ticket, `ship_interior.tscn` should instance all three scenes and position them in the interior layout

## Handoff Notes
- Created 3 new scene files: `recycler.tscn`, `fabricator.tscn`, `automation_hub.tscn` in `game/scenes/objects/`
- All three use their corresponding GLB mesh from `assets/meshes/machines/` (no greybox needed — all meshes existed)
- Each scene: Node3D root → script, instanced GLB mesh, Area3D InteractionArea (3x2x3 box), Marker3D PlayerStandPoint (1.5m front offset)
- Updated `ship_interior.tscn` to instance all three at zone positions (A=-3,0,-1 B=0,0,-1 C=3,0,-1)
- Note: recycler.gd, fabricator.gd, automation_hub.gd are registered as autoloads in project.godot — attaching them to scene nodes creates duplicate instances. Systems Programmer should evaluate whether to remove autoload registrations or create separate scene-only scripts in a follow-up ticket.
- No existing `.gd` scripts were modified

## Activity Log
- 2026-02-25 [producer] Created ticket — standards refactor, self-contained scene rule
- 2026-02-26 [producer] Scheduled into M7 — Ship Interior milestone
- 2026-02-26 [gameplay-programmer] Starting work — creating standalone machine scenes
- 2026-02-26 [gameplay-programmer] Completed — commit e9b1b16, PR https://github.com/sqlhammer/Hammer-Forge-Studio/pull/78 (merged)
