---
id: TICKET-0314
title: "BUG — Ship clips into/through terrain mesh on biome load"
type: BUG
status: DONE
priority: P2
owner: gameplay-programmer
created_by: studio-head
created_at: 2026-03-07
updated_at: 2026-03-07
milestone: "M11"
phase: "QA"
depends_on: [TICKET-0313]
blocks: []
tags: [ship, terrain, clipping, biome-load, rock-warrens, m11]
---

## Summary

On biome load, the ship mesh partially intersects the terrain surface — the undercarriage and landing gear are visibly embedded inside terrain geometry. Observed on Rock Warrens in screenshot `C:\temp\2026-03-07_07-41-46.png`.

This may be a secondary symptom of TICKET-0313 (player spawn below terrain) that persisted after that fix, or an independent ship placement issue.

Screenshot: `C:\temp\2026-03-07_07-41-46.png`

---

## Reproduction Steps

1. Launch the game and load Rock Warrens biome
2. Observe the ship position relative to the terrain surface on load

**Expected:** Ship rests on or above the terrain surface with no mesh intersection.

**Actual:** Ship undercarriage and landing gear clip through the terrain mesh.

---

## Acceptance Criteria

- [x] Confirm whether this is still reproducible after the TICKET-0313 terrain collision fix
- [x] If still present: ship placement Y-position accounts for terrain surface height at the landing site
- [x] No visible mesh intersection between ship and terrain on any biome load
- [x] Run full test suite — no regressions
- [x] Commit and push

---

## Files Likely Involved

- `game/scripts/gameplay/game_world.gd` — ship placement logic on biome load
- `game/scripts/gameplay/rock_warrens_biome.gd` — ship spawn point definition

---

## Activity Log

- 2026-03-07 [studio-head] Filed — ship clipping into terrain observed in Rock Warrens during M11 UAT playtesting. Screenshot: C:\temp\2026-03-07_07-41-46.png. May be resolved by TICKET-0313 fix — verify first.
- 2026-03-07 [gameplay-programmer] Starting work. TICKET-0313 fix (backface_collision) was for player falling through terrain — independent of ship placement. Ship clips because ShipExterior mesh extends below node origin (ShipMesh at Y=6.5 scale 24, RechargeZone collision bottom at Y=-3). Ship placed at raw terrain surface Y with no offset.
- 2026-03-07 [gameplay-programmer] Fix: Added SHIP_Y_OFFSET (3.0) constant to GameWorld and TravelSequenceManager. Ship position Y is now offset above terrain surface on initial load and after biome travel. Commit c72a627, PR #370 merged.
