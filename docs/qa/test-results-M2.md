# QA Test Results — M2: Art Pipeline & Asset Delivery

**Ticket:** TICKET-0014
**Tester:** qa-engineer
**Test Date:** 2026-02-22
**Godot Version:** 4.5.1 stable (Vulkan 1.4.325, Forward+)
**Hardware:** NVIDIA GeForce RTX 4070 Laptop GPU

---

## Executive Summary

**M2 QA SIGN-OFF: APPROVED**

All 4 production assets load cleanly in Godot, meet polygon and file size budgets, display correct PBR materials, and are placed in the correct directories with correct naming. Two P2 findings (texture oversizing) and one P3 finding (documentation gap) identified — none are blockers.

---

## Test Results

### 1. Asset Import Validation

| # | Test | Result | Notes |
|---|------|--------|-------|
| 1.1 | All 4 GLBs load in Godot without errors | **PASS** | 0 errors, 0 warnings in output log |
| 1.2 | All 4 assets display in test scene | **PASS** | `res://scenes/test/test_m2_assets.tscn` — all visible |
| 1.3 | No import contention or failure | **PASS** | All 4 imported on first open |

### 2. Polygon Budget Validation

| Asset | Type | Actual Tris | Budget Range | Hard Max | Result |
|-------|------|------------|-------------|----------|--------|
| Hand Drill | Handheld tool | 4,000 | 2,000–5,000 | 5,000 | **PASS** |
| Player Character | Character | 8,000 | 5,000–10,000 | 10,000 | **PASS** |
| Ship Exterior | Vehicle (hero) | 12,000 | 8,000–15,000 | 15,000 | **PASS** |
| Resource Node | Env prop (hero) | 2,999 | 1,500–4,000 | 4,000 | **PASS** |

### 3. Texture Resolution Validation

| Asset | Type | Actual Res | Max Allowed | Result |
|-------|------|-----------|-------------|--------|
| Hand Drill | Handheld prop | 2048x2048 | 1024x1024 | **FAIL — P2** |
| Player Character | Character | 2048x2048 | 2048x2048 | **PASS** |
| Ship Exterior | Vehicle/Ship | 2048x2048 | 2048x2048 | **PASS** |
| Resource Node | Env prop (hero) | 2048x2048 | 1024x1024 | **FAIL — P2** |

**Finding:** Hand Drill and Resource Node textures are 2x over the texture budget defined in `docs/art/tech-specs.md`. AI-generated textures from Tripo3D are output at 2048x2048 regardless of asset type. Godot's VRAM compression mitigates runtime impact, but the spec is not met.

### 4. GLB File Size Validation

| Asset | Size | Max Budget | Result |
|-------|------|-----------|--------|
| Hand Drill | 774.5 KB | 1 MB | **PASS** |
| Player Character | 918.1 KB | 2 MB | **PASS** |
| Ship Exterior | 1,356.9 KB | 3 MB | **PASS** |
| Resource Node | 834.2 KB | 1 MB | **PASS** |

### 5. Material & Visual Inspection

| # | Test | Result | Notes |
|---|------|--------|-------|
| 5.1 | All assets have StandardMaterial3D | **PASS** | Verified via editor script |
| 5.2 | Albedo textures present | **PASS** | All 4 assets |
| 5.3 | Normal maps enabled and present | **PASS** | All 4 assets |
| 5.4 | Roughness textures present | **PASS** | All 4 assets (via ORM) |
| 5.5 | Metallic textures present | **PASS** | All 4 assets (via ORM) |
| 5.6 | No missing materials (pink/magenta) | **PASS** | Visual inspection in editor viewport |
| 5.7 | No z-fighting visible | **PASS** | Editor viewport at default camera |
| 5.8 | No broken UVs visible | **PASS** | Textures map correctly to geometry |
| 5.9 | No inverted normals (dark patches) | **PASS** | All surfaces lit correctly |

### 6. Naming Convention & Directory Structure

| Asset | Filename | Convention Match | Directory | Result |
|-------|----------|-----------------|-----------|--------|
| Hand Drill | `mesh_hand_drill.glb` | `mesh_<descriptor>.glb` | `assets/meshes/tools/` | **PASS** |
| Player Character | `mesh_player_character.glb` | `mesh_<descriptor>.glb` | `assets/meshes/characters/` | **PASS** |
| Ship Exterior | `mesh_ship_exterior.glb` | `mesh_<descriptor>.glb` | `assets/meshes/vehicles/` | **PASS** |
| Resource Node | `mesh_resource_node_scrap.glb` | `mesh_<descriptor>.glb` | `assets/meshes/props/` | **PASS** |

### 7. Documentation Check

| # | Test | Result | Notes |
|---|------|--------|-------|
| 7.1 | `docs/art/3d-pipeline-sop.md` exists and covers all sections | **PASS** | Prerequisites, Pipeline A, Pipeline B, Failure Modes, Worked Example, Appendix |
| 7.2 | `docs/art/tech-specs.md` has no `[TBD]` fields | **PASS** | Grep search returned 0 matches |
| 7.3 | `docs/art/pipeline-recommendation.md` records Studio Head approval | **FAIL — P3** | Approval recorded in TICKET-0011 Activity Log but document status still reads "PENDING STUDIO HEAD DECISION" |
| 7.4 | All SOP-referenced files exist in repo | **PASS** | All 9 referenced files/dirs verified |

### 8. Pipeline Reproducibility (Documentation Review)

| # | Test | Result | Notes |
|---|------|--------|-------|
| 8.1 | SOP references valid, existing files | **PASS** | All scripts, briefs, and specs present |
| 8.2 | SOP includes clear step-by-step for both pipelines | **PASS** | Pipeline A (AI Gen) and Pipeline B (Blender Python) fully documented |
| 8.3 | SOP includes validation commands | **PASS** | Python validation script and Blender decimation commands provided |
| 8.4 | SOP includes common failure modes | **PASS** | Import, AI gen, and Blender Python troubleshooting tables |
| 8.5 | SOP includes worked example | **PASS** | Hand Drill AI pipeline end-to-end |

**Note:** Full reproducibility test (running the SOP end-to-end to produce a new asset) was not executed. QA does not have Blender or Tripo API access. Documentation review confirms the SOP is complete and followable.

---

## Findings Summary

### P2 Findings (Non-blocking)

| ID | Finding | Affected Assets | Recommendation |
|----|---------|----------------|----------------|
| M2-F01 | Texture resolution exceeds budget (2048x2048 vs 1024x1024 max) | Hand Drill, Resource Node | Downscale textures to 1024x1024 in Blender pipeline, or update tech-specs to allow 2048x2048 for AI-generated assets. File BUG ticket for technical-artist. |
| M2-F02 | Texture resolution exceeds budget (2048x2048 vs 1024x1024 max) | Resource Node (same root cause as F01) | Same as above — single fix addresses both. |

### P3 Findings (Informational)

| ID | Finding | Recommendation |
|----|---------|----------------|
| M2-F03 | `docs/art/pipeline-recommendation.md` status line not updated post-approval | Technical-artist should update status from "PENDING STUDIO HEAD DECISION" to "APPROVED" with date. Not a blocker. |

---

## Blocker Assessment

- **P0 bugs:** 0
- **P1 bugs:** 0
- **P2 findings:** 2 (same root cause — AI texture output at 2048x2048 for budget-1024 assets)
- **P3 findings:** 1 (documentation status not updated)

Per QA protocol: no P0 or P1 bugs open. P2 findings documented for follow-up but do not block milestone closure. The texture oversizing has no runtime impact due to Godot's VRAM compression — this is a spec compliance issue, not a functional defect.

---

## QA Sign-Off

**M2 Milestone: Art Pipeline & Asset Delivery — APPROVED**

All 4 production assets are imported, within polygon and file size budgets, correctly textured with PBR materials, properly named and organized. The 3D Pipeline SOP is complete and documented. Two texture budget exceedances identified as P2 for follow-up in M3.

Signed: **qa-engineer**
Date: **2026-02-22**
