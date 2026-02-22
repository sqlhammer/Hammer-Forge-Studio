---
id: TICKET-0017
title: "Downscale Hand Drill and Resource Node textures to 1024x1024"
type: BUG
status: OPEN
priority: P2
owner: technical-artist
created_by: qa-engineer
created_at: 2026-02-22
updated_at: 2026-02-22
milestone: "M3"
depends_on: []
blocks: []
tags: [art-pipeline, textures, budget-compliance]
---

## Summary

Hand Drill and Resource Node extracted textures are 2048x2048, exceeding the 1024x1024 max defined in `docs/art/tech-specs.md` for their asset types (Handheld prop and Environment prop hero). The AI generation pipeline (Tripo3D) outputs all textures at 2048x2048 regardless of asset type. The Blender decimation pass in TICKET-0016 reduced geometry but did not downscale textures.

## Severity

**P2** — Assets are functional and display correctly in-engine. Godot's VRAM compression mitigates runtime impact. This is a spec compliance issue, not a visual or functional defect.

## Reproduction Steps

1. Open Godot editor
2. Load `res://assets/meshes/tools/mesh_hand_drill_Color_*.jpg` — observe resolution is 2048x2048
3. Load `res://assets/meshes/props/mesh_resource_node_scrap_Color_*.jpg` — observe resolution is 2048x2048
4. Compare against `docs/art/tech-specs.md` Texture Budgets table:
   - Handheld prop (PBR): max 1024x1024
   - Environment prop (PBR): max 1024x1024

## Expected Behavior

All extracted textures (Color, Normal, ORM) for Hand Drill and Resource Node should be 1024x1024 or smaller per tech-specs.md.

## Actual Behavior

All 6 textures (3 per asset) are 2048x2048 — 2x over budget.

### Affected Files

| Asset | Texture | Actual | Budget |
|-------|---------|--------|--------|
| Hand Drill | Color, Normal, ORM | 2048x2048 | 1024x1024 |
| Resource Node | Color, Normal, ORM | 2048x2048 | 1024x1024 |

## Recommended Fix

Add a texture downscale step to the Blender decimation pipeline for assets whose type budget is below 2048x2048. Alternatively, update `docs/art/tech-specs.md` to allow 2048x2048 for AI-generated assets if the team decides the extra resolution is worth the VRAM cost.

## Evidence

QA validation report: `docs/qa/test-results-M2.md` (Finding M2-F01)
QA ticket: TICKET-0014

## Activity Log

- 2026-02-22 [qa-engineer] Created ticket from M2 QA finding M2-F01. Identified during TICKET-0014 validation. Both assets functional but not spec-compliant.
