---
id: TICKET-0010
title: "AI generation PoC — tool selection + produce 4 game assets"
type: TASK
status: DONE
priority: P1
owner: technical-artist
created_by: producer
created_at: 2026-02-22
updated_at: 2026-02-22
milestone: "M2"
depends_on: [TICKET-0008]
blocks: [TICKET-0011]
tags: [art-pipeline, ai-generation, poc]
---

## Summary
Identify the best available AI mesh generation tool(s) for this project's needs, then use the chosen tool(s) to produce all 4 target assets defined in TICKET-0008. Document the tool selection rationale, process, and results in a PoC report that feeds into the evaluation in TICKET-0011.

## Acceptance Criteria
- [x] Tool selection documented: at minimum 3 candidate tools evaluated with rationale for final selection
- [x] All 4 assets produced as importable `.glb` files (or converted to GLB):
  - `poc_ai_gen/mesh_hand_drill.glb`
  - `poc_ai_gen/mesh_player_character.glb`
  - `poc_ai_gen/mesh_ship_exterior.glb`
  - `poc_ai_gen/mesh_resource_node_scrap.glb`
- [x] All 4 GLBs successfully imported into Godot without errors
- [x] Each asset visually interpretable (clearly readable as what it is meant to be)
- [x] PoC report written at `docs/art/poc-report-ai-gen.md` covering:
  - Tool selection rationale (what was evaluated and why this was chosen)
  - Prompts or inputs used for each asset
  - Time per asset (prompt to importable GLB, including any cleanup)
  - What worked well
  - What was painful or required workarounds
  - Honest assessment of visual quality against the criteria in TICKET-0008
  - Any manual cleanup steps required and how much effort they involved
  - Cost considerations (if tool has usage costs)

## Tool Selection Guidance
Candidate tools to evaluate (not exhaustive — technical-artist should identify current best-in-class):
- **Meshy** — text/image to 3D, good GLB export
- **Luma AI** — photogrammetry + generation, high quality
- **Rodin (Hyper3D)** — fast generation, game-ready topology
- **CSM.ai** — image-to-3D, designed for game assets
- **Tripo3D** — text-to-3D, GLB export

Selection criteria: GLB export quality, topology cleanliness for game use, consistency across assets, cost, iteration speed.

## Implementation Notes
- Store prompts/inputs used for each asset in the PoC report — reproducibility matters
- Document the import pipeline: what format did the tool export, what conversion was needed to get to GLB
- If a hybrid approach (e.g., AI base mesh + Blender cleanup) is needed, document that — it's a valid finding
- Store PoC output in a new `ai_gen_experiments/poc_output/` directory — not in `game/` yet
- Work from the same asset briefs as TICKET-0009 — same brief, different pipeline

## Activity Log
- 2026-02-22 [producer] Created ticket; depends on TICKET-0008
- 2026-02-22 [technical-artist] Tool selection complete: 5 tools evaluated (Meshy, Luma Genie [eliminated—sunset], Rodin/Hyper3D, CSM.ai, Tripo3D), plus Sloyd as bonus. Selected Tripo3D as primary. API script written (tripo_generate.py). PoC report written.
- 2026-02-22 [technical-artist] API key provisioned. Account has 0 credits — free tier credits may need dashboard activation at tripo3d.ai/app. Generation blocked until credits available. All non-generation AC complete (tool selection, prompts, report, script).
- 2026-02-22 [technical-artist] Professional plan activated. All 4 assets generated via Tripo3D API. GLBs downloaded (9.8-16 MB each, 52 MB total). All 4 imported into Godot 4.5.1 — verified in editor viewport. Key finding: meshes are 100K-285K vertices (need retopology for game use). PoC report updated with actual results. All AC met. DONE.
- 2026-02-22 [producer] Archived
