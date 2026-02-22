---
id: TICKET-0016
title: "Rework M3 asset set using approved hybrid pipeline"
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
tags: [art-pipeline, assets, production, rework]
---

## Summary

TICKET-0013 produced the M3 asset set using Blender Python only, deviating from the approved hybrid pipeline (Tripo3D primary, Blender Python secondary). Studio Head has rejected the Blender-only selection and requires the AI-generated assets to be incorporated per the hybrid pipeline recommendation approved in TICKET-0011.

The AI-generated assets are preserved at `game/poc_ai_gen/`. The SOP at `docs/art/3d-pipeline-sop.md` defines the hybrid decision rule and the Blender decimation workflow for processing AI output. Apply the decision rule from `docs/art/pipeline-recommendation.md` to determine which sub-pipeline each asset goes through, then re-run the Blender cleanup/retopology pass on AI output to meet Godot import standards and polygon budgets.

## Acceptance Criteria

- [ ] `docs/art/pipeline-recommendation.md` decision rule applied to all 4 assets — document which sub-pipeline was used for each asset and why
- [ ] AI-generated assets processed through Blender decimation/cleanup workflow per SOP
- [ ] All 4 finalized assets placed at production paths:
  - `game/assets/meshes/tools/mesh_hand_drill.glb`
  - `game/assets/meshes/characters/mesh_player_character.glb`
  - `game/assets/meshes/vehicles/mesh_ship_exterior.glb`
  - `game/assets/meshes/props/mesh_resource_node_scrap.glb`
- [ ] All 4 assets import into Godot without errors
- [ ] All assets meet polygon and texture budgets in `docs/art/tech-specs.md`
- [ ] Test scene `game/scenes/test/test_m2_assets.tscn` updated with new assets and verified in editor viewport
- [ ] M3 Handoff Notes updated with revised asset source decision, any new known issues, and scale references

## Implementation Notes

- AI-generated source assets are at `game/poc_ai_gen/` — do not re-generate unless absolutely necessary
- The SOP retopology/decimation workflow exists specifically to address the heavy mesh issue (52 MB → budget-compliant) — follow it
- If an AI asset cannot be brought to budget via decimation without unacceptable quality loss, fall back to Blender Python for that asset and document the reason per the SOP hybrid decision rule
- Do not make pipeline decisions unilaterally — if you deviate from the SOP decision rule for any asset, document the reason in the Activity Log and flag it in Handoff Notes

## Activity Log

- 2026-02-22 [producer] Created ticket. Studio Head rejected Blender-only asset selection from TICKET-0013; directed hybrid pipeline incorporation per approved TICKET-0011 recommendation. Depends on TICKET-0012 (SOP); replaces TICKET-0013 output; blocks TICKET-0014.
