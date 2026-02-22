---
id: TICKET-0016
title: "Rework M3 asset set using approved hybrid pipeline"
type: TASK
status: DONE
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

- [x] `docs/art/pipeline-recommendation.md` decision rule applied to all 4 assets — document which sub-pipeline was used for each asset and why
- [x] AI-generated assets processed through Blender decimation/cleanup workflow per SOP
- [x] All 4 finalized assets placed at production paths:
  - `game/assets/meshes/tools/mesh_hand_drill.glb` (774 KB, 4,000 tris)
  - `game/assets/meshes/characters/mesh_player_character.glb` (918 KB, 8,000 tris)
  - `game/assets/meshes/vehicles/mesh_ship_exterior.glb` (1,357 KB, 12,000 tris)
  - `game/assets/meshes/props/mesh_resource_node_scrap.glb` (834 KB, 2,999 tris)
- [x] All 4 assets import into Godot without errors
- [x] All assets meet polygon and texture budgets in `docs/art/tech-specs.md`
- [x] Test scene `game/scenes/test/test_m2_assets.tscn` updated with new assets and verified in editor viewport
- [x] M3 Handoff Notes updated with revised asset source decision, any new known issues, and scale references

## Implementation Notes

- AI-generated source assets are at `game/poc_ai_gen/` — do not re-generate unless absolutely necessary
- The SOP retopology/decimation workflow exists specifically to address the heavy mesh issue (52 MB → budget-compliant) — follow it
- If an AI asset cannot be brought to budget via decimation without unacceptable quality loss, fall back to Blender Python for that asset and document the reason per the SOP hybrid decision rule
- Do not make pipeline decisions unilaterally — if you deviate from the SOP decision rule for any asset, document the reason in the Activity Log and flag it in Handoff Notes

## Decision Rule Application

| Asset | Decision Rule Match | Sub-Pipeline | Rationale |
|-------|-------------------|--------------|-----------|
| Hand Drill | Hero prop, visual richness (first-person close-up) | AI Gen → Blender decimate | Texture detail matters at close range |
| Player Character | Hero asset | AI Gen → Blender decimate | Character is focal point of game |
| Ship Exterior | Hero asset | AI Gen → Blender decimate | Largest visual element, texture richness adds presence |
| Resource Node | Organic shapes (rocks/rubble) | AI Gen → Blender decimate | AI produces more convincing rock shapes than deformed spheres |

All 4 assets used AI Generation (Tripo3D) as primary pipeline per the decision rule: all are hero assets or organic shapes where visual richness matters. Blender Python used as the cleanup/optimization layer for decimation.

## M3 Handoff Notes (Revised)

### Decimation Results
| Asset | Source Tris | Final Tris | Budget Max | File Size | PBR Textures |
|-------|-----------|-----------|-----------|-----------|-------------|
| Hand Drill | 320,384 | 4,000 | 5,000 | 774 KB | Color, Normal, ORM |
| Player Character | 355,056 | 8,000 | 10,000 | 918 KB | Color, Normal, ORM |
| Ship Exterior | 501,550 | 12,000 | 15,000 | 1,357 KB | Color, Normal, ORM |
| Resource Node | 501,708 | 2,999 | 4,000 | 834 KB | Color, Normal, ORM |

### Known Issues
| Asset | Issue | Severity | Notes |
|-------|-------|----------|-------|
| All | Decimation from 300K+ to budget causes some surface detail loss | Low | Silhouettes preserved; texture detail compensates |
| All | Single mesh per asset (no named sub-parts) | Low | AI output is monolithic; sub-part selection not possible |
| All | No skeletal rig | Medium | Rigging required before animation in M3+ |
| Ship Exterior | Scale may need verification against 15m reference | Low | Check in-engine with player character for scale reference |

### Scale References
| Asset | Approximate Size | Godot Units |
|-------|-----------------|-------------|
| Hand Drill | ~30cm long | 0.3 |
| Player Character | ~1.8m tall | 1.8 |
| Ship Exterior | ~15m long | 15.0 |
| Resource Node | ~2m wide | 2.0 |

## Activity Log

- 2026-02-22 [producer] Created ticket. Studio Head rejected Blender-only asset selection from TICKET-0013; directed hybrid pipeline incorporation per approved TICKET-0011 recommendation. Depends on TICKET-0012 (SOP); replaces TICKET-0013 output; blocks TICKET-0014.
- 2026-02-22 [technical-artist] Decision rule applied: all 4 assets routed through AI Gen → Blender decimate. Wrote decimate_ai_assets.py script. All 4 AI GLBs decimated via Blender 5.0.1 (320K-502K tris → 3K-12K tris, 18.2s total). Production assets replaced at game/assets/meshes/. Godot reimport triggered — all 4 verified in editor viewport with PBR textures intact. TICKET-0013 handoff notes updated. All AC met. DONE.
