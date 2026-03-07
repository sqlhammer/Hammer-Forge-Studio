---
id: TICKET-0346
title: "VERIFY — BUG fix: Player spawn-below-terrain regression resolved (TICKET-0318)"
type: TASK
status: TODO
priority: P1
owner: play-tester
created_by: producer
created_at: 2026-03-07
updated_at: 2026-03-07
milestone: "M11"
phase: "QA"
depends_on: [TICKET-0318]
blocks: []
tags: [verify, bug, player-spawn, regression, biome-load]
---

## Summary

Verify the regression fix in TICKET-0318 — confirm the player consistently spawns on solid
terrain in all biomes with no below-terrain errors, including the specific regression path
that was reintroduced after TICKET-0317.

---

## Acceptance Criteria

- [ ] Visual verification: Travel to Shattered Flats — player spawns on terrain, not below
      it; no visible terrain clip or falling through the floor
- [ ] Visual verification: Travel to Rock Warrens — same result
- [ ] Visual verification: Travel to Debris Field — same result
- [ ] Visual verification: Travel between biomes multiple times (at least 2 round-trips)
      to confirm consistency — spawn is correct every time, not just the first load
- [ ] State dump: PLAYER_POS.y > 0.0 and PLAYER_ON_FLOOR = true after each biome load
- [ ] Unit test suite: zero failures across all tests
- [ ] No runtime errors during any verification scenario

---

## Handoff Notes

(Leave blank until verification is complete.)

---

## Activity Log

- 2026-03-07 [producer] Created VERIFY ticket for TICKET-0318 — BUG: Player spawn regression fix
