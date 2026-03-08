---
id: TICKET-0341
title: "VERIFY — BUG fix: Player spawns on solid terrain in all biomes on biome load (TICKET-0313)"
type: TASK
status: IN_PROGRESS
priority: P1
owner: play-tester
created_by: producer
created_at: 2026-03-07
updated_at: 2026-03-07
milestone: "M11"
phase: "QA"
depends_on: [TICKET-0313]
blocks: []
tags: [verify, bug, player-spawn, biome-load, terrain]
---

## Summary

Verify that the player spawns on solid terrain (not below/inside the terrain mesh) when
loading any biome, after the root-cause fix in TICKET-0313.

---

## Acceptance Criteria

- [ ] Visual verification: Loading Shattered Flats — player appears on solid ground, not
      clipping through or falling below the terrain mesh
- [ ] Visual verification: Loading Rock Warrens — same as above
- [ ] Visual verification: Loading Debris Field — same as above
- [ ] State dump: PLAYER_POS.y > 0.0 and PLAYER_ON_FLOOR = true immediately after biome load
- [ ] Unit test suite: zero failures across all tests
- [ ] No runtime errors during any verification scenario (specifically no
      "move_and_slide called before _ready" or terrain collision errors)

---

## Handoff Notes

(Leave blank until verification is complete.)

---

## Activity Log

- 2026-03-07 [producer] Created VERIFY ticket for TICKET-0313 — BUG: Player spawn below terrain
- 2026-03-07 [play-tester] Starting work — verifying TICKET-0313 fix across all three biomes
