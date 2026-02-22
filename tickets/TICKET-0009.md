---
id: TICKET-0009
title: "Blender Python PoC — produce 4 game assets"
type: TASK
status: IN_PROGRESS
priority: P1
owner: technical-artist
created_by: producer
created_at: 2026-02-22
updated_at: 2026-02-22
milestone: "M2"
depends_on: [TICKET-0008]
blocks: [TICKET-0011]
tags: [art-pipeline, blender, poc]
---

## Summary
Using the existing Blender Python pipeline (`blender_experiments/`), produce all 4 target assets defined in TICKET-0008. Extend or refactor the pipeline as needed. Document time, process, pain points, and results in a PoC report — this report feeds directly into the evaluation in TICKET-0011.

## Acceptance Criteria
- [ ] All 4 assets produced as importable `.glb` files:
  - `poc_blender/mesh_hand_drill.glb`
  - `poc_blender/mesh_player_character.glb`
  - `poc_blender/mesh_ship_exterior.glb`
  - `poc_blender/mesh_resource_node_scrap.glb`
- [ ] All 4 GLBs successfully imported into Godot without errors
- [ ] Each asset visually interpretable (clearly readable as what it is meant to be)
- [x] Python scripts used to generate each asset committed to `blender_experiments/`
- [x] PoC report written at `docs/art/poc-report-blender.md` covering:
  - Time per asset (rough estimate)
  - What worked well
  - What was painful or required workarounds
  - Honest assessment of visual quality against the criteria in TICKET-0008
  - Any limitations of the approach

## Implementation Notes
- Build on `blender_experiments/master_control.py` — extend it, do not start from scratch
- One Python script per asset is acceptable; a single parameterized script is better if feasible
- PoC quality bar: clearly readable, importable, representative of what the pipeline can produce — not final production quality
- Document any manual steps required (steps that could not be scripted) — these are critical findings
- Asset naming follows `docs/art/tech-specs.md`: `<type>_<descriptor>_<variant>.glb`
- Store PoC output in `blender_experiments/poc_output/` — not in `game/` yet

## Activity Log
- 2026-02-22 [producer] Created ticket; depends on TICKET-0008
- 2026-02-22 [technical-artist] Scripts complete: build_hand_drill.py, build_player_character.py, build_ship_exterior.py, build_resource_node.py, run_poc_all.py. PoC report written. BLOCKER: Blender not installed — GLB generation pending. All scripting AC met.
