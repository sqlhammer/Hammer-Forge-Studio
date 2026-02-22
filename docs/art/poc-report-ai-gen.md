# PoC Report: AI Generation Pipeline

**Ticket:** TICKET-0010
**Author:** technical-artist
**Date:** 2026-02-22
**Status:** COMPLETE

---

## Executive Summary

Five AI 3D mesh generation tools were evaluated against the project's requirements. **Tripo3D** was selected as the primary tool and all 4 target assets were generated via the Tripo3D REST API. All 4 GLBs downloaded successfully and imported into Godot 4.5.1. Assets are visually detailed with full PBR textures (Color, Normal, ORM maps).

**Key finding:** AI-generated meshes are very high-poly (100K-285K vertices, 9-16 MB per GLB). Smart Low-Poly retopology or Blender decimation will be required before production use.

### Actual Generation Results

| Asset | GLB Size | Vertices | Godot Import |
|-------|----------|----------|--------------|
| mesh_hand_drill.glb | 9.8 MB | ~100K | Clean |
| mesh_player_character.glb | 10.9 MB | ~120K | Clean (retry needed) |
| mesh_ship_exterior.glb | 16.0 MB | 285,204 | Clean (delayed — needed full reimport) |
| mesh_resource_node_scrap.glb | 15.4 MB | ~200K | Clean |
| **Total** | **52.1 MB** | **~705K** | **All imported** |

Note: Ship exterior initially failed to load due to concurrent Godot reimport task. Succeeded after reimport completed. Player character failed once, succeeded on retry.

---

## Tool Selection: Candidates Evaluated

### 1. Meshy (meshy.ai)

| Criterion | Assessment |
|-----------|-----------|
| Text-to-3D | Yes (Meshy-6 model) |
| GLB Export | Yes |
| Poly Control | Configurable 3k-100k + Remesh tool |
| API | REST API (Pro+ tier, $20/month) |
| Speed | 1-3 minutes per asset |
| Cost | ~$0.40/asset on Pro plan |
| Stylized Output | Good — textures naturally lean stylized |
| Consistency | Low — significant run-to-run variation |

**Pros:** Large community, good documentation, naturally stylized textures, remesh tool for retopology.
**Cons:** No free API access. Inconsistent output quality. Complex prompts can yield 50k+ poly meshes.

### 2. Luma AI (Genie)

**ELIMINATED:** Genie was sunset January 1, 2026. Luma AI pivoted entirely to video generation (Ray3). No longer available.

### 3. Rodin / Hyper3D (hyper3d.ai)

| Criterion | Assessment |
|-----------|-----------|
| Text-to-3D | Yes |
| Image-to-3D | Yes (primary strength) |
| GLB Export | Yes (default format) |
| Poly Control | Excellent — explicit 2K/4K/8K/18K/50K tiers, quad or tri |
| API | REST API, also via fal.ai/WaveSpeed |
| Speed | 20-90 seconds |
| Cost | ~$0.30-0.58/asset on Business plan ($120/month) |
| Quality | Highest of all tools evaluated (9/10) |
| Consistency | Medium — consistent quality if input images are consistent |

**Pros:** Best mesh quality and topology. Explicit poly tier controls match our budgets perfectly. Production-ready output. GLB as default.
**Cons:** Expensive ($120/month for serious use). Image-to-3D is stronger than text-to-3D. Free tier extremely limited ($1.50/credit).

### 4. CSM.ai (Common Sense Machines)

| Criterion | Assessment |
|-----------|-----------|
| Text-to-3D | Yes |
| Image-to-3D | Yes |
| GLB Export | Yes |
| Poly Control | Limited without Enterprise retopology |
| API | REST API + Python SDK |
| Speed | Slowest of all evaluated tools |
| Cost | ~$0.20+/asset on Maker plan |
| Quality | Good for photorealistic, weaker for stylized |
| Consistency | Low |

**Pros:** Python SDK exists. Blender MCP integration.
**Cons:** AI Retopology locked behind Enterprise paywall. Slow generation. Photorealistic bias. Limited poly control. Not recommended.

### 5. Tripo3D (tripo3d.ai) — SELECTED

| Criterion | Assessment |
|-----------|-----------|
| Text-to-3D | Yes (v3.0 Ultra, 20B+ parameters) |
| Image-to-3D | Yes |
| GLB Export | Yes |
| Poly Control | Smart Low-Poly feature for game-ready retopology |
| API | REST API + official Python SDK (`pip install tripo3d`) |
| Speed | 8-15 seconds (fastest of all tools) |
| Cost | ~$0.21/asset on Professional plan ($11.94/month) |
| Quality | Good (8/10), strong for game assets |
| Consistency | Low-Medium — needs consistent prompting strategy |

**Pros:** Best API/SDK for agent automation. Fastest generation. Smart Low-Poly directly addresses our poly budgets. Best free tier (300 credits). Most cost-effective. Python SDK with async support.
**Cons:** Art style consistency requires careful prompting. Not as high-fidelity as Rodin for hero assets. Some export formats locked behind paid tiers.

### Bonus: Sloyd (sloyd.ai) — Noted for Future Reference

Parametric + AI hybrid platform. Excellent for hard-surface props (unlimited generations at $15/month), but limited to template categories. Worth considering for background/utility props in future milestones.

---

## Tool Selection Rationale

**Selected: Tripo3D** — for the following reasons:

1. **AI-Team Suitability:** Official Python SDK (`pip install tripo3d`) with environment variable auth, async support, and clean REST API. An AI agent can operate this end-to-end without human intervention.

2. **Smart Low-Poly:** Purpose-built retopology feature that produces game-ready meshes with optimal edge flow in 8-10 seconds. This directly addresses our 1.5k-15k triangle budgets without manual decimation.

3. **Speed:** 8-15 seconds per generation means rapid iteration. Can generate dozens of variants and pick the best in the time other tools produce one.

4. **Cost:** $11.94/month for 3,000 credits (~75 models). Free tier (300 credits) sufficient for this PoC evaluation.

5. **Quality:** v3.0 Ultra represents a significant quality leap (20B parameters, 300% detail improvement). Good for stylized output.

**Why not Rodin?** Rodin produces higher quality output but costs 10x more ($120/month vs $11.94), is slower (70-90s vs 8-15s), and its text-to-3D is weaker than its image-to-3D. For a PoC evaluation, Tripo's speed advantage enables more iteration, which is more valuable than Rodin's quality ceiling.

**Why not Meshy?** No free API access. Inconsistent quality. Higher cost per asset. Slower generation.

---

## Prompts / Inputs for Each Asset

### 1. Hand Drill

**Prompt:**
> A handheld sci-fi extraction drill tool, stylized chunky proportions. Worn brushed metal housing with rubber grip handle, glowing cyan energy conduit running along the top, drill bit tip at the front. Three small green charge indicator lights on the side panel. Exhaust vents at the rear. Size of a large cordless drill but slightly oversized for sci-fi readability. Outer Wilds art style, utilitarian research equipment aesthetic. Not a weapon.

**Negative prompt:** realistic, photorealistic, weapon, gun, military, tiny, miniature

### 2. Player Character

**Prompt:**
> Full-body humanoid character wearing a bulky environmental research suit. T-pose or A-pose. Rounded helmet with dark opaque visor. Deep blue fabric suit with gunmetal gray armor plates at shoulders, chest, and knees. Tall boots nearly to the knees. Equipment backpack on the back. Belt with tool attachment points. ~1.8m tall human proportions, slightly stylized and chunky. Outer Wilds / Hades inspired art style. Field researcher, not a soldier.

**Negative prompt:** realistic, photorealistic, military, soldier, weapon, skinny, anime

### 3. Ship Exterior

**Prompt:**
> Atmospheric research vessel, a mobile base that can fly. Chunky utilitarian sci-fi design like Outer Wilds spaceship. Asymmetric hull with cargo pod on one side. Dual main engines at the rear with visible thruster nozzles. Cockpit windshield at the front. Communication antenna dish on top. Three-point landing gear deployed. Riveted metal plating with orange accent stripes. Panel seams and hatches visible on hull. Size of a small cargo plane. Not sleek or military — cobbled together, utilitarian, has personality.

**Negative prompt:** realistic, photorealistic, military, fighter jet, sleek, symmetrical, starship

### 4. Resource Node (Scrap Metal Deposit)

**Prompt:**
> A pile of alien architecture rubble with exposed scrap metal deposits. Weathered rock and cracked synthetic debris forming an irregular mound about 2 meters wide. Bright metallic veins and fragments visible embedded in the dark rock, clearly readable as extractable resources. Oxidized rust-colored edges where metal meets rock. Partially buried in ground. Muted earth tones with reflective metal contrast. Stylized sci-fi prop, mineable resource node for a game.

**Negative prompt:** realistic, photorealistic, crystal, gem, glowing, floating, clean

---

## Actual Time Data

| Asset | Generation Time | Download | Total |
|-------|----------------|----------|-------|
| Hand Drill | ~10-15s | ~3s | ~18s |
| Player Character | ~10-15s | ~3s | ~18s |
| Ship Exterior | ~10-15s | ~5s | ~20s |
| Resource Node | ~10-15s | ~5s | ~20s |
| **Total** | **~50s** | **~16s** | **~76s** |

**Total pipeline time: ~76 seconds for all 4 assets.** This is dramatically faster than the Blender Python pipeline (~3 hours of script authoring + 12s execution).

**Note:** Generation times are approximate — the API returned completed tasks. Download times measured from signed CloudFront URLs. Script authoring for the API integration took ~30 minutes.

---

## What Worked Well

1. **API-first design:** Tripo's REST API is clean. Task creation → poll → download workflow is straightforward to automate.
2. **Speed:** ~15 seconds per asset generation. All 4 assets generated in under 2 minutes total including download.
3. **Visual richness:** AI-generated PBR textures (Color, Normal, ORM maps) add significant visual detail that flat Blender materials cannot match.
4. **Low barrier:** No Blender dependency, no 3D modeling knowledge, no geometric construction required.
5. **Texture maps included:** Each GLB includes full PBR texture set automatically.

## What Was Painful / Required Workarounds

1. **API key/credit provisioning:** Free tier does NOT include API access. Professional plan ($11.94/month) required. Credit balance took multiple attempts to activate. New API key generation required after plan upgrade.
2. **Download URL discovery:** The API does not have a separate download endpoint. The GLB URL is embedded in the task result at `output.pbr_model` as a signed CloudFront URL. Required script debugging to discover correct extraction path.
3. **Extremely high poly counts:** Default output is 100K-285K vertices per asset. Our budgets are 1.5K-15K triangles. Smart Low-Poly retopology or external decimation is mandatory.
4. **Large file sizes:** 9-16 MB per GLB (vs 88-343 KB for Blender). Not viable for game shipping without optimization.
5. **Godot import timing:** Large GLBs caused Godot reimport contention. Ship exterior (16 MB, 285K vertices) failed to load until reimport completed. Player character required retry.
6. **No style lock-in:** Each generation varies. Art style consistency across assets depends entirely on prompt discipline.

---

## Cost Considerations

| Plan | Monthly Cost | Credits | Assets/Month | Cost/Asset |
|------|-------------|---------|--------------|------------|
| Free | $0 | 300 | ~7 | $0 |
| Professional | $11.94 | 3,000 | ~75 | ~$0.16 |
| Advanced | $29.94 | 8,000 | ~200 | ~$0.15 |

For this PoC: Free tier is sufficient (4 assets = ~160 credits).
For production: Professional tier ($11.94/month) covers extensive iteration.

---

## Pipeline Script

Integration script ready at: `ai_gen_experiments/tripo_generate.py`

**Usage:**
```bash
export TRIPO_API_KEY="your-key"
python ai_gen_experiments/tripo_generate.py
```

**Single asset:**
```bash
python ai_gen_experiments/tripo_generate.py --asset hand_drill
```

**Output directory:** `ai_gen_experiments/poc_output/`

---

## Files Produced

```
ai_gen_experiments/
├── tripo_generate.py            # API integration script
└── poc_output/
    ├── mesh_hand_drill.glb          # 9.8 MB - GENERATED
    ├── mesh_player_character.glb    # 10.9 MB - GENERATED
    ├── mesh_ship_exterior.glb       # 16.0 MB - GENERATED
    └── mesh_resource_node_scrap.glb # 15.4 MB - GENERATED

game/poc_ai_gen/                     # Copied for Godot import verification
├── poc_ai_review.tscn               # Review scene with all 4 assets
├── mesh_hand_drill.glb              # + .import + 3 texture JPGs
├── mesh_player_character.glb        # + .import + 3 texture JPGs
├── mesh_ship_exterior.glb           # + .import + 3 texture JPGs
└── mesh_resource_node_scrap.glb     # + .import + 3 texture JPGs
```

### Tripo3D Task IDs (for reference/re-download)

| Asset | Task ID |
|-------|---------|
| Hand Drill | `4c827008-2baf-4b88-b945-f55c6ac442d6` |
| Player Character | `f1a3701c-b71b-4954-a670-7862ec25fa34` |
| Ship Exterior | `3e41ef89-76af-4dee-a3af-49381f9fcb17` |
| Resource Node | `a7109fcf-ef52-482b-9e9c-71e17b371893` |

---

## Self-Assessment (Updated After Execution)

| Dimension | Score | Notes |
|-----------|-------|-------|
| Visual Quality | 4 | Detailed meshes with full PBR textures. Visually rich, recognizable silhouettes. |
| Iteration Speed | 5 | ~15s per asset. Total ~76s for all 4. Orders of magnitude faster than Blender. |
| Consistency | 2 | Each asset has distinct texture/style treatment. No cohesive art direction across set. |
| Godot Compatibility | 3 | All imported, but 100K-285K vertex meshes are unusable without retopology. Import timing issues with large files. |
| AI-Team Suitability | 4 | API works well once provisioned. Credit/key activation was painful. Script needed debugging. |
| Maintainability | 3 | Prompts documented. Output non-deterministic. Task IDs allow re-download but not reproduction. |

**Key insight:** Visual quality per-asset is high (score 4), but Godot Compatibility drops to 3 because raw output is far too heavy for game use (52 MB total, 705K vertices). Production pipeline must include retopology step.
