---
id: TICKET-0018
title: "Archive PoC experiment artifacts and clean up game directory"
type: TASK
status: DONE
priority: P2
owner: technical-artist
created_by: producer
created_at: 2026-02-22
updated_at: 2026-02-22
milestone: "M2"
depends_on: [TICKET-0016]
blocks: []
tags: [art-pipeline, cleanup, assets]
---

## Summary

The M2 PoC work generated experiment artifacts that are no longer part of the approved production pipeline. AI-generated assets at `game/poc_ai_gen/` and any other intermediate PoC outputs are currently sitting inside the game directory alongside approved production assets, creating confusion about what is canonical. Move all experiment artifacts to a top-level `experiments/` archive outside the game tree, while leaving approved production assets in place.

## Acceptance Criteria

- [x] `experiments/m2-poc/` directory created at the repo root to house all M2 experiment artifacts
- [x] All AI-generated PoC assets moved from `game/poc_ai_gen/` to `experiments/m2-poc/ai-gen/`
- [x] Any intermediate Blender Python PoC outputs not already at production paths moved to `experiments/m2-poc/blender-python/`
- [x] `game/poc_ai_gen/` directory removed (must not remain as an empty folder)
- [x] Production assets at approved paths untouched and verified present after cleanup:
  - `game/assets/meshes/tools/mesh_hand_drill.glb`
  - `game/assets/meshes/characters/mesh_player_character.glb`
  - `game/assets/meshes/vehicles/mesh_ship_exterior.glb`
  - `game/assets/meshes/props/mesh_resource_node_scrap.glb`
- [x] `experiments/m2-poc/README.md` written documenting what is archived, why it was not selected for production, and how to retrieve it if needed in future sprints
- [x] No `.import` files or Godot project references point to the archived paths — verify no broken references remain in `game/`
- [x] Changes committed to `main`

## Implementation Notes

- The `experiments/` directory is intentionally outside `game/` so Godot does not scan or import its contents
- Do not delete experiment artifacts — the value of PoC output is future reference; archiving preserves it without polluting the production asset tree
- Survey all of `game/` for any other one-off test outputs or intermediate files from M2 experimentation that are not part of the approved production asset set; include them in the archive
- The test scene at `game/scenes/test/test_m2_assets.tscn` is a production validation asset — do NOT move it; it validates the approved pipeline output and may be referenced in M3

## Activity Log

- 2026-02-22 [producer] Created ticket. M2 PoC artifacts require cleanup from game directory before M3 begins. Depends on TICKET-0016 (approved production assets must be in place before cleanup proceeds).
- 2026-02-22 [technical-artist] IN_PROGRESS. Dependency TICKET-0016 confirmed DONE. Surveyed game/ for all PoC and experiment artifacts: game/poc_ai_gen/ (AI gen), game/poc_blender/ (Blender Python), game/experiment/ (misc tests), ai_gen_experiments/ (Tripo script + raw outputs).
- 2026-02-22 [technical-artist] DONE (commit cf89d98). Archived all M2 PoC artifacts to experiments/m2-poc/ (ai-gen/, blender-python/, misc/). Removed game/poc_ai_gen/, game/poc_blender/, game/experiment/, ai_gen_experiments/. Stripped orphaned .import files. All 4 production assets verified present at approved paths. Godot filesystem scan clean — no broken references. README.md written documenting archive contents and retrieval instructions.
