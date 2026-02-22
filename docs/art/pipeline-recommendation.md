# Pipeline Recommendation: 3D Asset Pipeline

**Ticket:** TICKET-0011
**Author:** technical-artist
**Date:** 2026-02-22
**Status:** RECOMMENDATION READY — PENDING STUDIO HEAD DECISION

---

## Executive Summary

**We recommend a hybrid pipeline: AI Generation (Tripo3D) as primary, with Blender Python as secondary for procedural/geometric assets and post-processing cleanup.**

Both pipelines were evaluated against the six criteria from `docs/art/poc-evaluation-criteria.md`. The AI generation pipeline scores higher overall due to overwhelming speed advantage and AI-team suitability, while the Blender Python pipeline offers superior consistency and maintainability. A hybrid approach captures the strengths of both.

---

## Scored Comparison

| Dimension | Weight | Blender Python (1-5) | Blender Weighted | AI Generation (1-5) | AI Weighted |
|-----------|--------|----------------------|------------------|----------------------|-------------|
| Visual Quality | 0.25 | 3 | 0.75 | 3.5 | 0.875 |
| Iteration Speed | 0.20 | 3 | 0.60 | 5 | 1.00 |
| Consistency | 0.20 | 4 | 0.80 | 2.5 | 0.50 |
| Godot Compatibility | 0.15 | 4 | 0.60 | 4 | 0.60 |
| AI-Team Suitability | 0.10 | 4 | 0.40 | 5 | 0.50 |
| Maintainability | 0.10 | 5 | 0.50 | 3.5 | 0.35 |
| **Total** | **1.00** | | **3.65** | | **3.725** |

**Margin: 0.075 points** — within the 0.3-point hybrid threshold.

---

## Score Justification

### Visual Quality (Blender: 3, AI Gen: 3.5)

**Blender Python:**
- Silhouettes are readable and proportions match the stylized aesthetic
- Material zones are clearly defined (8-10 PBR materials per asset)
- Geometry is constructed from primitives + modifiers — no organic sculpted detail
- No texture maps, only flat PBR colors — reads as "placeholder" quality
- Score 3: Acceptable, meets the bar with minor issues

**AI Generation (Tripo3D):**
- v3.0 Ultra's 20B parameter model produces more naturally detailed meshes
- AI-generated textures add visual richness that flat PBR colors cannot
- Stylized output quality depends heavily on prompt engineering
- Some assets may lean too realistic or too stylized without careful prompting
- Score 3.5: Between acceptable and good; potential for 4 with prompt iteration

**Evidence:** The Blender pipeline produces exactly what's coded — consistent but limited to primitive composition. AI generation produces more visually rich output but with less predictability.

### Iteration Speed (Blender: 3, AI Gen: 5)

**Blender Python:**
- ~45-60 minutes to write a new asset script from scratch
- ~15 seconds to execute (Blender background mode)
- Total for 4 assets: ~3 hours authoring + ~1 minute execution
- Modifications require code changes and re-runs
- Score 3: 1-4 hours per asset bracket

**AI Generation (Tripo3D):**
- ~15 seconds per asset (prompt → GLB)
- Total for 4 assets: ~70 seconds
- Can generate 10 variants in the time Blender produces 1
- Iteration is trivial — adjust prompt, regenerate
- Score 5: Under 15 minutes per asset

**Evidence:** AI generation is ~150x faster for the generation step. Even accounting for prompt iteration (generate 5 variants per asset), total time is ~6 minutes vs ~3 hours.

### Consistency (Blender: 4, AI Gen: 2.5)

**Blender Python:**
- Same material palette, same primitive patterns, same modifier stack across all assets
- Deterministic output — identical every run
- Visual language is consistent by construction
- Score 4: Strong cohesion; all four assets clearly share an art style

**AI Generation (Tripo3D):**
- Each generation is non-deterministic — different topology, proportions, and texture treatment
- No style lock-in mechanism on consumer plans
- Consistency requires disciplined prompting and variant selection
- Four diverse asset types (tool, character, vehicle, prop) may diverge in style
- Score 2.5: Some shared elements but noticeable style drift likely between asset types

**Evidence:** This is the most significant weakness of AI generation. A hand drill and a ship generated independently may not look like they belong in the same game without post-processing to unify materials and color palettes.

### Godot Compatibility (Blender: 4, AI Gen: 4)

**Blender Python:**
- GLB export via `bpy.ops.export_scene.gltf()` is well-tested
- Scale set explicitly in scripts — imports at correct dimensions
- PBR materials map to Godot's StandardMaterial3D
- Score 4: Clean import with minimal adjustment

**AI Generation (Tripo3D):**
- GLB is a native export format
- Scale and orientation may need correction (AI tools don't guarantee game-engine-ready transforms)
- AI-generated PBR textures should import cleanly
- Score 4: Clean import expected; minor scale/orientation fix possible

**Evidence:** Both pipelines produce GLB with PBR materials. Neither should have significant Godot import issues.

### AI-Team Suitability (Blender: 4, AI Gen: 5)

**Blender Python:**
- Fully scriptable — an LLM writes and modifies the Python scripts
- Requires Blender installed as a dependency
- Writing new asset scripts requires understanding Blender's Python API
- Score 4: Fully scriptable with clear parameters; agent can execute given documentation

**AI Generation (Tripo3D):**
- Official Python SDK with env var auth
- REST API with clean async workflow
- Brief in, GLB out — no 3D knowledge needed
- No desktop application dependency
- Score 5: Fully automated end-to-end; brief in, GLB out, no human intervention

**Evidence:** Both pipelines can be operated by AI agents. AI generation wins because it requires zero 3D modeling knowledge — the agent only needs to write good prompts, not construct geometry from primitives.

### Maintainability (Blender: 5, AI Gen: 3.5)

**Blender Python:**
- Deterministic scripts produce identical output
- Seeded randomness where applicable
- Code is readable, documented, and modifiable
- Another agent can reproduce results exactly
- Score 5: Fully reproducible; SOP + scripts produce identical output

**AI Generation (Tripo3D):**
- Prompts are documented and reproducible as input
- Output is non-deterministic — same prompt produces different meshes
- Pipeline is simple (prompt → API → GLB) and easily documented
- But exact reproduction of a specific asset is not possible
- Score 3.5: Documentable as SOP; another agent can follow it but won't get identical output

**Evidence:** Blender Python is perfectly reproducible. AI generation is reproducible in process but not in output — this is inherent to the technology.

---

## Per-Asset Comparison

| Asset | Blender Strength | AI Gen Strength |
|-------|-----------------|-----------------|
| **Hand Drill** | Precise geometry control for mechanical parts | Faster iteration; AI textures add surface detail |
| **Player Character** | Exact proportions, T-pose placement | More natural anatomy, richer visual detail |
| **Ship Exterior** | Precise hull geometry, exact asymmetry | Overall silhouette and weathering feel more natural |
| **Resource Node** | Seeded reproducibility for scatter placement | Organic rock shapes more convincing than deformed spheres |

---

## Recommendation: Hybrid Pipeline

### Decision Rule

**Use AI Generation (Tripo3D) as the primary pipeline for:**
- Hero assets (player character, ship, major props)
- Organic shapes (rocks, vegetation, terrain features)
- Assets where visual richness matters more than geometric precision
- Rapid prototyping and variant exploration

**Use Blender Python as the secondary pipeline for:**
- Procedural/parameterized geometry (tiling patterns, modular building pieces)
- Assets requiring exact reproducibility across instances
- Post-processing cleanup of AI-generated meshes (material unification, scale correction, poly optimization)
- Assets where exact dimensional control matters

### Workflow

```
1. Write asset brief (game-designer)
2. Generate 3-5 variants via Tripo3D API (technical-artist)
3. Select best variant
4. Import to Blender for cleanup if needed (scale, materials, poly reduction)
5. Export final GLB to game/assets/meshes/
6. Import to Godot, validate against tech-specs.md
```

### Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| Art style inconsistency across AI assets | Post-process in Blender: unify material palettes, adjust color values to match game's color scheme |
| AI output too high-poly | Use Smart Low-Poly retopology or Blender decimation modifier |
| AI tool becomes unavailable/changes pricing | Blender Python pipeline as full fallback; scripts already written for all 4 asset types |
| Non-deterministic output complicates iteration | Version-control selected GLBs; document which generation was chosen and why |

---

## Cost Projection

| Item | Monthly Cost |
|------|-------------|
| Tripo3D Professional | $11.94 |
| Blender | $0 (open source) |
| **Total** | **$11.94/month** |

At Professional tier: ~75 assets/month, sufficient for M2-M3 production.

---

## Conclusion

The two pipelines are complementary, not competing. AI generation dominates on speed and ease-of-use; Blender Python dominates on consistency and reproducibility. The hybrid approach leverages AI generation for rapid asset creation while using Blender Python as the quality control and standardization layer.

**Recommendation: Adopt hybrid pipeline. Tripo3D primary, Blender Python secondary.**

Studio Head decision required to proceed to TICKET-0012 (SOP) and TICKET-0013 (production assets).
