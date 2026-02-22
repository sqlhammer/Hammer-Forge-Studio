# PoC Report: AI Generation Pipeline

**Ticket:** TICKET-0010
**Author:** technical-artist
**Date:** 2026-02-22
**Status:** TOOL SELECTION COMPLETE — AWAITING API KEY FOR EXECUTION

---

## Executive Summary

Five AI 3D mesh generation tools were evaluated against the project's requirements. **Tripo3D** is selected as the primary tool based on its Python SDK, fast generation speed, Smart Low-Poly feature, and competitive pricing. An API integration script has been written and is ready to execute once an API key is provisioned.

**Blocker:** A Tripo3D API key is required. Sign up at https://www.tripo3d.ai/ — the free tier provides 300 credits for initial testing (~7 assets).

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

## Time Estimates (Projected)

| Asset | Generation Time | Download + Post | Total |
|-------|----------------|-----------------|-------|
| Hand Drill | ~10s | ~5s | ~15s |
| Player Character | ~15s | ~5s | ~20s |
| Ship Exterior | ~15s | ~5s | ~20s |
| Resource Node | ~10s | ~5s | ~15s |
| **Total** | **~50s** | **~20s** | **~70s** |

Plus Smart Low-Poly retopology if needed: +8-10s per asset.

**Total estimated pipeline time: ~2-3 minutes for all 4 assets.** This is dramatically faster than the Blender Python pipeline (~3 hours of script authoring).

---

## What Worked Well (Anticipated)

1. **API-first design:** Tripo's REST API and Python SDK are clean and well-documented for agent operation
2. **Speed:** Orders of magnitude faster than manual or scripted 3D modeling
3. **Low barrier:** No Blender, no 3D modeling knowledge, no geometric construction required
4. **Iteration:** Fast enough to generate 10 variants and select the best

## What Was Painful / Required Workarounds (Anticipated)

1. **Art style consistency:** No style lock-in. Each generation may vary. Mitigation: consistent prompt structure, negative prompts
2. **Prompt engineering:** Getting the right level of detail and style requires iteration
3. **Post-processing:** May need Blender cleanup for specific issues (scale, orientation, material names)
4. **Poly count control:** Smart Low-Poly is good but not guaranteed to hit exact budgets
5. **No texture map control:** PBR textures are auto-generated, not artist-directed

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
└── poc_output/                  # OUTPUT DIRECTORY (empty until API key provided)
    ├── mesh_hand_drill.glb          # (pending)
    ├── mesh_player_character.glb    # (pending)
    ├── mesh_ship_exterior.glb       # (pending)
    └── mesh_resource_node_scrap.glb # (pending)
```

---

## Provisional Self-Assessment (for TICKET-0011)

| Dimension | Estimated Score | Notes |
|-----------|----------------|-------|
| Visual Quality | 3-4 | v3.0 Ultra is strong; stylized output depends on prompting |
| Iteration Speed | 5 | ~15s per asset, ~70s total for all 4 |
| Consistency | 2-3 | Weakest area — no style lock-in across generations |
| Godot Compatibility | 4 | GLB native export; may need scale/orientation fix |
| AI-Team Suitability | 5 | Python SDK, REST API, env var auth, fully automated |
| Maintainability | 3-4 | Prompts are documented; output is non-deterministic |

**These scores are estimates and must be updated after actual generation and Godot import testing.**
