---
id: TICKET-0327
title: "VERIFY — Scene-First remediation: GameWorld persistent system nodes (TICKET-0298)"
type: TASK
status: TODO
priority: P1
owner: play-tester
created_by: producer
created_at: 2026-03-07
updated_at: 2026-03-07
milestone: "M11"
phase: "QA"
depends_on: [TICKET-0298]
blocks: []
tags: [verify, scene-first, game-world]
---

## Summary

Verify that all game world systems function correctly after the Scene-First refactor of
game_world.gd (6 persistent system node groups moved to .tscn) in TICKET-0298.

---

## Acceptance Criteria

- [ ] Visual verification: Game world loads correctly from DebugLauncher — player, terrain,
      ship, and HUD are all present
- [ ] Visual verification: All game world systems respond normally — scanner pings fire,
      deposits are minable, inventory functions, ship is boardable
- [ ] State dump: PLAYER_POS.y > -5 (player is on terrain, not fallen through); BATTERY and
      FUEL values are valid non-zero numbers
- [ ] Unit test suite: zero failures across all tests
- [ ] No runtime errors during any verification scenario

---

## Handoff Notes

(Leave blank until verification is complete.)

---

## Activity Log

- 2026-03-07 [producer] Created VERIFY ticket for TICKET-0298 — Scene-First: GameWorld persistent nodes
