---
id: TICKET-0124
title: "Cockpit console — greybox 3D mesh placeholder"
type: TASK
status: DONE
priority: P2
owner: technical-artist
created_by: producer
created_at: 2026-02-26
updated_at: 2026-02-26
milestone: "M7"
phase: "Foundation"
depends_on: []
blocks: [TICKET-0126]
tags: [3d-asset, cockpit, console, greybox, ship-interior]
---

## Summary

Create a greybox 3D mesh for the cockpit navigation console. This is a non-functional placeholder that will be wired up for ship navigation in M8. The console should read as a control panel / dashboard that a player would sit or stand at to pilot the ship.

## Design Constraints

- **Art style:** Greybox — simple geometric shapes, no textures, placeholder materials only
- **Approximate size:** ~2m wide × 0.8m deep × 1.2m tall (standing console, not a seated cockpit)
- **Material:** Medium grey `StandardMaterial3D` consistent with M4 greybox palette
- **Scene structure:** Standalone `.tscn` scene per coding standards (self-contained instanced scene)
- **Output path:** `game/scenes/objects/cockpit_console.tscn` with mesh at `game/assets/meshes/ship/mesh_cockpit_console.glb` (or CSGBox construction if preferred for greybox)

## Visual Reference

The console should suggest:
- A dashboard/control surface (angled top face, ~30° tilt toward the player)
- A base/pedestal anchoring it to the floor
- Optionally a simple screen area (flat face on the angled surface) where navigation UI will later appear

Keep it simple — this is greybox. 3–5 CSG primitives or a basic modeled mesh are sufficient.

## Acceptance Criteria

- [x] `game/scenes/objects/cockpit_console.tscn` exists as a standalone scene
- [x] Console mesh has appropriate collision shape(s)
- [x] Scene is independently openable and runnable in the Godot editor without errors
- [x] Mesh uses greybox placeholder materials (no textures)
- [x] A `Marker3D` named `ScreenCenter` marks where the navigation UI will later be placed
- [x] All code/scenes follow `docs/engineering/coding-standards.md`

## Implementation Notes

- CSGBox3D construction is fine for greybox — no need to model in Blender unless preferred
- If using CSG, parent under a `StaticBody3D` root with a simplified collision shape
- The `ScreenCenter` marker is for M8 to anchor a `SubViewport` or UI panel

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-26 [producer] Created ticket — cockpit console greybox mesh
- 2026-02-26 [technical-artist] Implemented — CSG greybox console (3 CSGBox3D: base, body, angled screen), StaticBody3D root, BoxShape3D collision, ScreenCenter Marker3D, medium grey StandardMaterial3D
