---
id: TICKET-0114
title: "Refactor — Tools (Hand Drill, Scanner) as standalone instanced scenes"
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
tags: [scene-design, tools, hand-drill, scanner, refactor, standards]
---

## Summary
Per the updated Scene Design standard, every conceptual game object must be its own self-contained `.tscn` scene. The Hand Drill and Scanner are conceptual tools with logic scripts (`mining.gd`, `scanner.gd`) but no corresponding `.tscn` scenes — currently the raw `.glb` mesh is referenced directly. This ticket creates proper scenes for each tool.

## Acceptance Criteria
- [ ] `game/scenes/objects/hand_drill.tscn` — root `Node3D` with `mining.gd` attached; `mesh_hand_drill.glb` instanced as a child `MeshInstance3D`
- [ ] `game/scenes/objects/scanner.tscn` — root `Node3D` with `scanner.gd` attached; mesh child (placeholder acceptable if no scanner mesh exists yet)
- [ ] Each tool scene has an `Area3D` named `UseArea` defining the effective range of the tool
- [ ] Both scenes are independently openable and runnable in the Godot editor without errors
- [ ] The player scene(s) (`player_first_person.tscn`, `player_third_person.tscn`) instance the tool scenes rather than embedding mesh or logic inline
- [ ] Existing scripts (`mining.gd`, `scanner.gd`) are not modified — only scene wrappers are added
- [ ] All code follows `docs/engineering/coding-standards.md`

## Implementation Notes
- Tools are held by the player and rendered in-world; root node type `Node3D` is appropriate
- The Hand Drill GLB lives at `assets/meshes/tools/mesh_hand_drill.glb` (M2 asset)
- The Scanner may not have a dedicated mesh yet — a placeholder `MeshInstance3D` with a `BoxMesh` is acceptable until a mesh is produced
- Player scenes should instance tools as children and toggle visibility/activation based on the active tool slot — this wiring is out of scope for this refactor but the scene structure must support it

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-25 [producer] Created ticket — standards refactor, self-contained scene rule
- 2026-02-26 [producer] Scheduled into M7 — Ship Interior milestone
- 2026-02-26 [gameplay-programmer] Starting work — creating standalone tool scenes for Hand Drill and Scanner
