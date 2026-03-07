---
id: TICKET-0342
title: "VERIFY — BUG fix: Ship does not clip into terrain mesh on biome load (TICKET-0314)"
type: TASK
status: TODO
priority: P1
owner: play-tester
created_by: producer
created_at: 2026-03-07
updated_at: 2026-03-07
milestone: "M11"
phase: "QA"
depends_on: [TICKET-0314]
blocks: []
tags: [verify, bug, ship, terrain-clipping, biome-load]
---

## Summary

Verify that the ship spawns on or above terrain (not clipping through it) when loading any
biome, after the fix in TICKET-0314.

---

## Acceptance Criteria

- [ ] Visual verification: Loading each biome (Shattered Flats, Rock Warrens, Debris Field)
      — the ship is visibly resting on or above the terrain surface, not embedded in it
- [ ] Visual verification: The ship's landing struts or base is visible above the terrain;
      no part of the ship geometry intersects the ground mesh
- [ ] Visual verification: Boarding the ship is possible (interact prompt appears when
      aiming at hull) — ship is reachable
- [ ] State dump: No quantitative assertions required; check for ERROR-free console
- [ ] Unit test suite: zero failures across all tests
- [ ] No runtime errors during any verification scenario

---

## Handoff Notes

(Leave blank until verification is complete.)

---

## Activity Log

- 2026-03-07 [producer] Created VERIFY ticket for TICKET-0314 — BUG: Ship clips into terrain fix
