---
id: TICKET-0317
title: "BUG — Ship spawns with extreme tilt/roll on biome load"
type: BUG
status: OPEN
priority: P2
owner: gameplay-programmer
created_by: studio-head
created_at: 2026-03-07
updated_at: 2026-03-07
milestone: "M11"
phase: "QA"
depends_on: [TICKET-0316]
blocks: []
tags: [ship, terrain, rotation, biome-load, spawn, m11]
---

## Summary

On biome load, the ship spawns with an extreme roll/tilt — the ship is rotated roughly 90° or more from level, with its underside facing the camera. The terrain and sky are visible in correct orientations, confirming the world is loaded normally; the ship rotation alone is wrong.

Screenshot: `C:\temp\2026-03-07_10-05-12.png`

---

## Reproduction Steps

1. Launch the game and load any biome
2. Observe the ship orientation on spawn

**Expected:** Ship sits upright and level on the terrain surface (zero roll, zero pitch).

**Actual:** Ship is severely tilted — rolled ~90° or more — making it appear nearly sideways or inverted from the player's perspective.

---

## Acceptance Criteria

- [ ] Identify where ship rotation/basis is set during biome load or travel sequence
- [ ] Ensure ship rotation is reset to upright (identity basis / zero roll+pitch) on every biome load
- [ ] Ship sits level on all three biomes (Shattered Flats, Rock Warrens, Debris Field)
- [ ] No regression on ship Y-offset fix from TICKET-0314
- [ ] Run full test suite — no regressions
- [ ] Commit and push

---

## Files Likely Involved

- `game/scripts/gameplay/game_world.gd` — ship placement and rotation on biome load
- `game/scripts/gameplay/travel_sequence_manager.gd` — ship transform during biome travel
- `game/scenes/gameplay/` — ship scene root transform

---

## Activity Log

- 2026-03-07 [studio-head] Filed — ship spawning with extreme tilt observed during M11 UAT playtesting. Screenshot: C:\temp\2026-03-07_10-05-12.png. Ship appears rolled ~90°+ from level; world orientation is correct. Likely ship rotation is not being reset to upright on biome load.
