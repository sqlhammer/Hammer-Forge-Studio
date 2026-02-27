---
id: TICKET-0179
title: "Cryonite deposit — greybox 3D mesh (pressurized rock formation)"
type: TASK
status: PENDING
priority: P1
owner: technical-artist
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "M8"
phase: "Foundation"
depends_on: [TICKET-0157]
blocks: []
tags: [art, mesh, cryonite, deposit, 3d, m8-foundation]
---

## Summary

Produce a greybox 3D mesh for the Cryonite deposit node. Cryonite forms in pressurized rock environments — the mesh should read as a rock formation with visible stress fractures or crystalline seams that hint at internal pressure. It must be visually distinct from the existing Scrap Metal resource node so players can identify it at a glance.

## Acceptance Criteria

- [ ] Greybox mesh produced in Blender using the established M2 pipeline SOP
- [ ] Visually distinct from Scrap Metal deposit node — different silhouette and surface detail language
- [ ] Pressurized rock aesthetic: stress fractures, bulging surfaces, or exposed seam lines suggesting internal pressure
- [ ] Poly count within established M3 resource node budget (reference: existing resource node mesh)
- [ ] Exported as `.glb` and imported into Godot at `game/assets/meshes/cryonite_deposit.glb`
- [ ] Mesh sits flat on terrain — no floating geometry, base aligns to ground plane
- [ ] Reviewed and approved by Studio Head before biome scene tickets begin placement

## Implementation Notes

- Reference the existing resource node mesh for scale and poly budget
- Greybox aesthetic — no texture maps needed in M8; base material with vertex color or flat color is sufficient
- The mesh will be used in TICKET-0173 (deep resource nodes) and TICKET-0170–0172 (biome scenes)

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created — M8 Foundation phase
