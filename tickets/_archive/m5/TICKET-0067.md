---
id: TICKET-0067
title: "Fabricator — 3D mesh and ship interior placement"
type: TASK
status: DONE
priority: P1
owner: technical-artist
created_by: producer
created_at: 2026-02-24
updated_at: 2026-02-24
milestone: "M5"
milestone_gate: "M4"
phase: "Foundation"
depends_on: []
blocks: [TICKET-0069]
tags: [fabricator, 3d-asset, ship-interior, technical-art]
---

## Summary
Produce the Fabricator 3D mesh following the M2 pipeline SOP, import it into Godot, and place it in the greybox ship interior scene. The Fabricator is a crafting machine — visually distinct from the Recycler — that occupies a dedicated zone in the ship interior. The physical machine must be present in the scene before the interaction panel (TICKET-0069) can be implemented.

## Acceptance Criteria
- [x] Fabricator mesh produced following `docs/engineering/3d-pipeline-sop.md` (M2 pipeline)
- [x] Mesh is visually distinct from the Recycler — different silhouette and form factor appropriate to a fabrication/assembly machine
- [x] Mesh imported into Godot and placed in the greybox ship interior scene (`game/scenes/gameplay/`)
- [x] An `InteractionArea` (or equivalent collision/trigger node) attached to the Fabricator mesh — used by gameplay-programmer to wire the interaction in TICKET-0069
- [x] Mesh poly count and texture budget within M2 pipeline art tech spec limits
- [x] No Godot import errors or warnings
- [x] Scene saved and committed

## Implementation Notes
- Reference `docs/engineering/3d-pipeline-sop.md` for the full production pipeline
- Reference existing M4 Recycler asset for scale, placement style, and interaction area convention
- The Fabricator should read as a "crafting bench / assembly station" in form factor — not industrial heavy machinery (that's the Recycler's territory)
- Placement zone in the ship interior: coordinate with greybox layout established in M4 (TICKET-0043)
- UI panel design (TICKET-0065) runs in parallel — if form factor guidance is needed before TICKET-0065 completes, use general design intent from GDD and the Recycler as a reference

## Handoff Notes
- Fabricator mesh at `game/assets/meshes/machines/mesh_fabricator_module.glb` (79 KB, ~1,135 verts)
- Blender build script at `blender_experiments/build_fabricator_module.py`
- Asset brief at `docs/art/asset-briefs/fabricator.md`
- `_place_module_visual()` in `test_world.gd` handles `"fabricator"` module_id with InteractionArea
- InteractionArea uses Layer 4 (interactable), masks Layer 1 (player) — consistent with existing convention
- Fabricator visual: wide/low workbench (2.0W x 1.0D x 1.2H) with press arm, distinct from tall Recycler
- TICKET-0069 (gameplay-programmer) can use the InteractionArea to wire panel open/close

## Activity Log
- 2026-02-24 [producer] Created ticket
- 2026-02-24 [technical-artist] Implemented: mesh generated via Blender Python pipeline, placed in ship interior, InteractionArea attached, test_world.gd updated for fabricator module placement
