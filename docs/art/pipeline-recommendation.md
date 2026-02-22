# Pipeline Recommendation: 3D Asset Pipeline

**Ticket:** TICKET-0011
**Author:** technical-artist
**Date:** 2026-02-22
**Status:** UPDATED WITH ACTUAL RESULTS — STUDIO HEAD APPROVED

---

## Executive Summary

**We recommend a hybrid pipeline: AI Generation (Tripo3D) as primary, with Blender Python as secondary for procedural/geometric assets and post-processing cleanup.**

Both pipelines were evaluated against the six criteria from `docs/art/poc-evaluation-criteria.md` and both have been executed with actual assets imported into Godot. The hybrid recommendation holds, but with an important caveat: AI-generated meshes require mandatory retopology before game use (100K-285K vertices vs 1.5K-15K budget). Blender Python's role as the cleanup/optimization layer is more critical than initially projected.

---

## Scored Comparison

| Dimension | Weight | Blender Python (1-5) | Blender Weighted | AI Generation (1-5) | AI Weighted |
|-----------|--------|----------------------|------------------|----------------------|-------------|
| Visual Quality | 0.25 | 3 | 0.75 | 4 | 1.00 |
| Iteration Speed | 0.20 | 3 | 0.60 | 5 | 1.00 |
| Consistency | 0.20 | 4 | 0.80 | 2 | 0.40 |
| Godot Compatibility | 0.15 | 4 | 0.60 | 3 | 0.45 |
| AI-Team Suitability | 0.10 | 4 | 0.40 | 4 | 0.40 |
| Maintainability | 0.10 | 5 | 0.50 | 3 | 0.30 |
| **Total** | **1.00** | | **3.65** | | **3.55** |

**Updated with actual execution data.** Margin: 0.10 points in favor of Blender. Both within the 0.3-point hybrid threshold.

**Score changes from pre-execution estimates:** AI Visual Quality up (3.5→4, textures are excellent), Consistency down (2.5→2, style drift confirmed), Godot Compatibility down (4→3, 285K vertex meshes need retopology), AI-Team Suitability down (5→4, API provisioning was painful), Maintainability down (3.5→3, non-deterministic output confirmed).

---

## Score Justification

### Visual Quality (Blender: 3, AI Gen: 4)

**Blender Python:**
- Silhouettes are readable and proportions match the stylized aesthetic
- Material zones are clearly defined (8-10 PBR materials per asset)
- Geometry is constructed from primitives + modifiers — no organic sculpted detail
- No texture maps, only flat PBR colors — reads as "placeholder" quality
- Score 3: Acceptable, meets the bar with minor issues

**AI Generation (Tripo3D):**
- Full PBR texture sets (Color, Normal, ORM) automatically generated per asset
- Detailed surface treatment — weathering, material transitions, surface detail
- Each asset is visually recognizable and detailed at game camera distances
- Score 4: Good quality, visually rich, clearly readable as intended objects

**Evidence (actual):** AI-generated hand drill has visible grip texture, metallic housing detail, and drill bit geometry. Player character shows suit fabric detail, helmet reflections. Ship exterior has hull paneling and engine detail. All significantly more visually rich than Blender's flat-color primitives.

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

### Consistency (Blender: 4, AI Gen: 2)

**Blender Python:**
- Same material palette, same primitive patterns, same modifier stack across all assets
- Deterministic output — identical every run
- Visual language is consistent by construction
- Score 4: Strong cohesion; all four assets clearly share an art style

**AI Generation (Tripo3D):**
- Each asset has distinctly different texture treatment and style
- No style lock-in mechanism — prompts with "Outer Wilds" did not produce cohesive style
- Hand drill, character, ship, and resource node look like they come from different games
- Score 2: Noticeable style drift between assets; would require post-processing to unify

**Evidence (actual):** Viewing all 4 AI assets side-by-side in Godot, each has different lighting assumptions, texture resolution, and surface treatment. The Blender assets, by contrast, share a consistent material palette and geometric language.

### Godot Compatibility (Blender: 4, AI Gen: 3)

**Blender Python:**
- GLB export via `bpy.ops.export_scene.gltf()` is well-tested
- Scale set explicitly in scripts — imports at correct dimensions
- PBR materials map to Godot's StandardMaterial3D
- All 4 assets imported with zero errors, 722 KB total
- Score 4: Clean import with minimal adjustment

**AI Generation (Tripo3D):**
- GLB format imports, PBR textures auto-detected and compressed by Godot
- Ship exterior (16 MB, 285K vertices) caused import contention — failed twice before succeeding
- Player character (10.9 MB) failed once, succeeded on retry
- Raw vertex counts (100K-285K) far exceed game poly budgets (1.5K-15K triangles)
- Total asset weight 52 MB vs Blender's 722 KB — 72x larger
- Retopology is mandatory before production use
- Score 3: Imports work but raw output is not game-ready; significant post-processing required

**Evidence (actual):** Blender assets imported instantly with zero issues. AI assets required retries and are too heavy for game use without decimation/retopology. This is the most significant practical difference between the pipelines.

### AI-Team Suitability (Blender: 4, AI Gen: 4)

**Blender Python:**
- Fully scriptable — an LLM writes and modifies the Python scripts
- Requires Blender installed as a dependency
- Writing new asset scripts requires understanding Blender's Python API
- Score 4: Fully scriptable with clear parameters; agent can execute given documentation

**AI Generation (Tripo3D):**
- REST API works well once provisioned
- API key/credit activation required multiple human interventions (plan upgrade, key regeneration)
- Download URL extraction required script debugging (undocumented response structure)
- Still requires no 3D modeling knowledge — prompt in, GLB out
- Score 4: Automated once set up, but initial provisioning needed human help

**Evidence (actual):** The Blender pipeline ran end-to-end on first attempt after installation. The Tripo API required 4 rounds of troubleshooting (env var propagation, 403 errors, credit activation, download URL format). Both are equally agent-suitable once operational.

### Maintainability (Blender: 5, AI Gen: 3)

**Blender Python:**
- Deterministic scripts produce identical output
- Seeded randomness where applicable
- Code is readable, documented, and modifiable
- Another agent can reproduce results exactly
- Score 5: Fully reproducible; SOP + scripts produce identical output

**AI Generation (Tripo3D):**
- Prompts documented and task IDs preserved for re-download
- Output is non-deterministic — same prompt produces different meshes each run
- Selected GLBs must be version-controlled as binary artifacts
- API changes or service disruption would break the pipeline entirely
- Score 3: Process is documentable but output is not reproducible; external service dependency

**Evidence (actual):** Blender scripts can be re-run by any agent at any time. AI-generated GLBs can be re-downloaded by task ID (limited window), but regeneration produces different output. The selected assets are effectively one-of-a-kind artifacts.

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

| Risk | Mitigation | Status |
|------|-----------|--------|
| Art style inconsistency across AI assets | Post-process in Blender: unify material palettes | **CONFIRMED** — style drift is significant |
| AI output too high-poly | Use Smart Low-Poly retopology or Blender decimation | **CONFIRMED** — 100K-285K vertices, mandatory retopology |
| AI tool becomes unavailable/changes pricing | Blender Python pipeline as full fallback | Mitigated — both pipelines operational |
| Non-deterministic output complicates iteration | Version-control selected GLBs; preserve task IDs | **CONFIRMED** — task IDs preserved |
| Large file sizes strain Godot import | Retopology before import, or import settings tuning | **NEW** — 16 MB GLB caused import failures |
| API provisioning requires human intervention | Document exact setup steps in SOP | **NEW** — credit activation was not straightforward |

---

## Cost Projection

| Item | Monthly Cost |
|------|-------------|
| Tripo3D Professional | $19.94 |
| Blender | $0 (open source) |
| **Total** | **$19.94/month** |

At Professional tier: ~75 assets/month, sufficient for M2-M3 production.

---

## Conclusion

The two pipelines are complementary, not competing. AI generation dominates on speed and ease-of-use; Blender Python dominates on consistency and reproducibility. The hybrid approach leverages AI generation for rapid asset creation while using Blender Python as the quality control and standardization layer.

**Recommendation: Adopt hybrid pipeline. Tripo3D primary, Blender Python secondary.**

Studio Head decision required to proceed to TICKET-0012 (SOP) and TICKET-0013 (production assets).
