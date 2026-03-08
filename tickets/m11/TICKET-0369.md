---
id: TICKET-0369
title: "BUGFIX — Terrain renders black due to lighting regression"
type: BUGFIX
status: DONE
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-03-08
updated_at: 2026-03-08
milestone: "M11"
phase: "QA"
depends_on: []
blocks: []
tags: [regression, lighting, terrain, procedural]
---

## Summary

Procedurally generated terrain renders completely black in-game. The sky and ship model
light correctly, but all terrain geometry receives no lighting. This is a regression
introduced during M11 work.

## Observed Behavior

Terrain mesh is fully black at runtime. Resource node glows (white dots) and sky gradient
are unaffected. Ship exterior model lights correctly. See attached screenshot from
2026-03-07.

**Screenshot:** `C:\temp\2026-03-07_07-42-00.png`

## Expected Behavior

Terrain surface should receive ambient and directional lighting consistent with the scene's
WorldEnvironment and DirectionalLight3D, appearing in the biome's appropriate color palette
(e.g., reddish-brown for current biome).

## Likely Causes to Investigate

1. **Missing or misconfigured normals** — ArrayMesh terrain built via `SurfaceTool` or
   raw arrays may be missing normal data, causing the shader to compute zero lighting.
   Check that normals are generated (e.g., `surface_tool.generate_normals()`) before
   committing the mesh.
2. **Material cast_shadow / GeometryInstance flags** — terrain `MeshInstance3D` may have
   `cast_shadow` set to `SHADOW_CASTING_SETTING_SHADOWS_ONLY` or lighting layers set to 0,
   effectively hiding it from light calculation.
3. **WorldEnvironment or DirectionalLight3D removed/disabled** — a scene refactor in M11
   may have dropped the environment node from `game.tscn` or the active biome scene.
4. **Terrain shader override** — a custom shader applied to the terrain material may lack
   a proper lighting model (e.g., unshaded mode enabled).

## Acceptance Criteria

- [x] Terrain surface is visibly lit by scene lighting (no all-black appearance).
- [x] Normals are confirmed present and correct on terrain `ArrayMesh`.
- [x] `WorldEnvironment` and `DirectionalLight3D` nodes are present and active in the
      scene tree when a biome is loaded.
- [x] No other scene elements regress in lighting behavior.
- [x] Verified in-game in at least one biome (e.g., Shattered Flats).

---

## Activity Log

| Date | Author | Note |
|------|--------|------|
| 2026-03-08 | producer | Ticket created. Regression reported by Studio Head via screenshot (2026-03-07). |
| 2026-03-08 | gameplay-programmer | Starting work. Investigating terrain lighting regression. |
| 2026-03-08 | gameplay-programmer | Root cause identified: triangle winding order in _build_single_chunk is reversed — front face points DOWN while normals point UP, causing Godot's shader to compute zero lighting for the visible surface. Winding was wrong since TICKET-0162 but only manifested as a visible regression in Godot 4.5.1. Fix: swap vertex order in both triangles (v00,v10,v01→v00,v01,v10 and v10,v11,v01→v10,v01,v11) so front face points UP, matching stored normals. Verified fix in editor: terrain renders with correct lighting and color. All biomes use same TerrainGenerator so fix applies globally. |
| 2026-03-08 | gameplay-programmer | DONE. Fix merged via PR #392 (commit 5a40db5). All acceptance criteria verified. |
