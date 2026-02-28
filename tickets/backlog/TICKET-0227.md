---
id: TICKET-0227
title: "Feature — Atmospheric lighting: reduce harsh shadows via simulated sky diffusion"
type: FEATURE
status: OPEN
priority: P2
owner: technical-artist
created_by: producer
created_at: 2026-02-28
updated_at: 2026-02-28
milestone: "M9"
phase: "TBD"
depends_on: []
blocks: []
tags: [lighting, atmosphere, shadows, environment, visual-quality, m9]
---

## Summary

The current biome lighting uses a harsh directional sun with no atmospheric diffusion, producing extreme high-contrast shadows that are uncomfortable to play in. Real-world planetary lighting (even on alien worlds with atmospheres) scatters light through the sky, filling shadows with ambient blue/grey light and softening shadow edges. The lighting should be tuned to approximate this effect.

## Acceptance Criteria

- [ ] Shadow harshness is visibly reduced in all three biomes (Shattered Flats, Rock Warrens, Debris Field) and in TestWorld
- [ ] Shadow-filled areas receive meaningful ambient fill light — no pure-black areas during daytime
- [ ] The ambient sky contributes directional fill (simulating atmospheric scattering) rather than a flat ambient color
- [ ] The overall color palette remains alien/sci-fi — do not make it look like a generic Earth daytime scene
- [ ] Performance impact is acceptable on the development machine (no significant FPS drop)
- [ ] Changes apply globally via the WorldEnvironment resource — not hardcoded per-biome

## Implementation Notes

- In Godot 4, the primary levers are on the `Environment` resource attached to the `WorldEnvironment` node:
  - **`ambient_light_source`**: set to `SKY` (not `COLOR`) so the sky contributes directional ambient bounce rather than a flat uniform fill
  - **`ambient_light_energy`**: increase from default to raise overall shadow brightness
  - **`sky_contribution`**: tune the sky's contribution weight to shadow fill
  - **`DirectionalLight3D.shadow_opacity`** or **`light_indirect_energy`**: reduce shadow darkness without removing shadows entirely
  - **`DirectionalLight3D` angular distance**: a larger angular diameter on the sun softens shadow penumbras
- A `ProceduralSkyMaterial` with a warm horizon and blue zenith will naturally produce Earth-like atmospheric gradient fills when `ambient_light_source = SKY`
- Consider enabling **SDFGI** (Signed Distance Field Global Illumination) or **Screen Space Indirect Lighting** if performance allows — these produce realistic multi-bounce fill at low cost in Godot 4.4+
- Target feel: midday overcast-to-clear on a dusty alien world — shadows visible and directional but not black; horizon haze tinting fills low-angle surfaces

## Activity Log

- 2026-02-28 [producer] Created — Studio Head reported lighting too harsh during M8 playtest; deferred to M9 visual pass
