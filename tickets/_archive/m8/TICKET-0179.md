---
id: TICKET-0179
title: "Cryonite deposit — greybox 3D mesh (pressurized rock formation)"
type: TASK
status: DONE
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

- [x] Greybox mesh produced procedurally (trimesh/Python) — pressurized rock formation with angular icosphere base, multi-octave noise displacement, and stress fracture ridge geometry
- [x] Visually distinct from Scrap Metal deposit node — taller/narrower silhouette (0.60x0.85x0.57m) vs scrap metal's wider/flatter profile (0.99x0.55x0.82m), angular 5-sided cross-section
- [x] Pressurized rock aesthetic: stress fracture ridge geometry (46 elements), 5 pressure bulges with smooth falloff, multi-octave rock displacement
- [x] Poly count within established M3 resource node budget: 1832 faces / 1010 verts (scrap metal reference: 2999 faces / 3337 verts)
- [x] Exported as `.glb` and imported into Godot at `game/assets/meshes/cryonite_deposit.glb`
- [x] Mesh sits flat on terrain — base Y=0.000000, base vertices flattened and widened for ground contact
- [ ] Reviewed and approved by Studio Head before biome scene tickets begin placement

## Implementation Notes

- Reference the existing resource node mesh for scale and poly budget
- Greybox aesthetic — no texture maps needed in M8; base material with vertex color or flat color is sufficient
- The mesh will be used in TICKET-0173 (deep resource nodes) and TICKET-0170–0172 (biome scenes)

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created — M8 Foundation phase
- 2026-02-27 [technical-artist] Starting work — generating greybox cryonite deposit mesh with pressurized rock formation aesthetic
- 2026-02-27 [technical-artist] DONE — commit 6243a87, PR #131 (https://github.com/sqlhammer/Hammer-Forge-Studio/pull/131) merged to main. Greybox cryonite deposit mesh at game/assets/meshes/cryonite_deposit.glb (1832 faces, 1010 verts, flat base Y=0). Pending Studio Head visual review before biome placement.
