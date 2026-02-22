# Technical Artist — Decision Log

## [2026-02-22] [TICKET-0010] AI Mesh Generation Tool Selection: Tripo3D

**Context:** TICKET-0010 required evaluating at minimum 3 AI mesh generation tools and selecting the best candidate for the project's 3D asset pipeline.

**Decision:** Selected Tripo3D (tripo3d.ai) as the primary AI generation tool.

**Alternatives considered:**
- **Meshy (meshy.ai):** Good stylized output, large community. Rejected as primary due to no free API tier, higher per-asset cost ($0.40 vs $0.21), and slower generation (1-3 min vs 8-15s).
- **Rodin/Hyper3D:** Highest mesh quality (9/10). Rejected as primary due to cost ($120/month Business tier), slower speed (70-90s), and text-to-3D being weaker than image-to-3D.
- **CSM.ai:** Python SDK exists. Rejected due to slowest generation times, AI Retopology locked behind Enterprise paywall, and photorealistic bias.
- **Luma AI Genie:** Eliminated — product sunset January 1, 2026.
- **Sloyd (bonus):** Noted for future prop generation. Limited by template categories.

**Rationale:** Tripo3D offers the best combination of: (1) Python SDK for AI agent automation, (2) fastest generation speed (8-15s), (3) Smart Low-Poly feature matching our poly budgets, (4) best free tier (300 credits), and (5) most cost-effective at scale ($11.94/month for ~75 assets).

## [2026-02-22] [TICKET-0011] Pipeline Recommendation: Hybrid (AI Primary + Blender Secondary)

**Context:** Both PoC pipelines were evaluated against the 6-dimension weighted scoring framework. Scores fell within the 0.3-point hybrid threshold (Blender 3.65, AI Gen 3.725, margin 0.075).

**Decision:** Recommend hybrid pipeline — Tripo3D as primary generator, Blender Python as secondary for procedural assets and post-processing cleanup.

**Alternatives considered:**
- **AI-only:** Fastest workflow but lacks consistency (score 2.5) and reproducibility.
- **Blender-only:** Most consistent and reproducible but too slow for iterative production (~3h per 4 assets vs ~70s).
- **Hybrid (recommended):** Captures AI speed for generation + Blender determinism for quality control.

**Rationale:** The scoring margin (0.075) clearly falls within the 0.3-point hybrid threshold defined in the evaluation criteria. Neither pipeline dominates across all dimensions — AI wins on speed and suitability, Blender wins on consistency and maintainability. The hybrid decision rule assigns each pipeline to asset categories where it scores highest.

## [2026-02-22] [TICKET-0009] Player Character Script: T-Pose vs Posed

**Context:** Existing `build_space_suit_character.py` has character posed looking at wrist device. PoC evaluation requires comparable output across pipelines.

**Decision:** Created new `build_player_character.py` with T-pose for PoC. Original posed script preserved unchanged.

**Alternatives considered:**
- Reusing posed script directly — rejected because posed character makes pipeline comparison harder (AI tools generate T/A-pose by default).
- Modifying original script — rejected to preserve existing work.

**Rationale:** T-pose is industry standard for character mesh evaluation. Enables fair comparison with AI-generated character (which will also be T/A-pose). Original posed script remains available for future use.
