---
id: TICKET-0013
title: "Finalize M3-ready asset set using chosen pipeline"
type: TASK
status: OPEN
priority: P1
owner: technical-artist
created_by: producer
created_at: 2026-02-22
updated_at: 2026-02-22
milestone: "M2"
depends_on: [TICKET-0012]
blocks: [TICKET-0014]
tags: [art-pipeline, assets, production]
---

## Summary
Using the finalized SOP from TICKET-0012, produce production-quality versions of the 4 game assets. These are the actual assets to be used in M3 gameplay — not PoC output. If the PoC assets are already at sufficient quality, this ticket is a cleanup and placement pass. If they are not, this is a full production run following the SOP.

## Acceptance Criteria
- [ ] All 4 assets finalized and placed at correct game paths:
  - `game/assets/meshes/tools/mesh_hand_drill.glb`
  - `game/assets/meshes/characters/mesh_player_character.glb`
  - `game/assets/meshes/vehicles/mesh_ship_exterior.glb`
  - `game/assets/meshes/props/mesh_resource_node_scrap.glb`
- [ ] All 4 assets imported into Godot without errors (`.import` files committed)
- [ ] All assets meet the polygon and texture budgets in `docs/art/tech-specs.md`
- [ ] All assets follow naming convention in `docs/art/tech-specs.md`
- [ ] Each asset placed in a simple test scene to verify in-engine appearance
- [ ] Asset production followed the SOP in `docs/art/3d-pipeline-sop.md` (validates SOP usability)
- [ ] Brief handoff notes written for M3: any known issues, intended usage context, or scale references

## Implementation Notes
- "Production-quality" for M3 means: correct proportions, clean import, readable at intended in-game viewing distance — not final polished art
- If PoC output is being reused: still run it through the SOP cleanup steps to confirm the documented process works
- Create `game/assets/` directory structure if it does not already exist
- Scale reference: player character should be approximately 1.8m tall in Godot units
- Test scene path: `game/scenes/test/test_m2_assets.tscn`

## Activity Log
- 2026-02-22 [producer] Created ticket; depends on TICKET-0012
