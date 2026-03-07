---
id: TICKET-0345
title: "VERIFY — BUG fix: Ship spawns level (no extreme tilt/roll) on biome load (TICKET-0317)"
type: TASK
status: TODO
priority: P1
owner: play-tester
created_by: producer
created_at: 2026-03-07
updated_at: 2026-03-07
milestone: "M11"
phase: "QA"
depends_on: [TICKET-0317]
blocks: []
tags: [verify, bug, ship, spawn-tilt, biome-load]
---

## Summary

Verify that the ship spawns with a level orientation (no extreme tilt or roll) when loading
any biome, after the fix in TICKET-0317.

---

## Acceptance Criteria

- [ ] Visual verification: Loading each biome — the ship appears level or at a small natural
      slope angle; it is not visibly tilted at an extreme angle or rolled sideways
- [ ] Visual verification: The ship's boarding ramp or entry point is accessible from
      a standing position on the terrain
- [ ] State dump: No quantitative assertions required; check for ERROR-free console
- [ ] Unit test suite: zero failures across all tests
- [ ] No runtime errors during any verification scenario

---

## Handoff Notes

(Leave blank until verification is complete.)

---

## Activity Log

- 2026-03-07 [producer] Created VERIFY ticket for TICKET-0317 — BUG: Ship extreme tilt/roll on spawn
