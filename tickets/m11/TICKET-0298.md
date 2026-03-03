---
id: TICKET-0298
title: "M11 Scene-First remediation — GameWorld persistent system nodes (game_world.gd)"
type: TASK
status: OPEN
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-03-03
updated_at: 2026-03-03
milestone: "M11"
phase: "Remediation"
depends_on: []
blocks: []
tags: [standards, scene-first, remediation, game-world]
---

## Summary

Move all persistent system nodes created via `.new()` in `game_world.gd` into the `game_world.tscn` scene, and convert CanvasLayer overlays to scene children.

---

## Acceptance Criteria

- [ ] `game_world.gd` lines 74–87: move WorldEnvironment and DirectionalLight3D to `game_world.tscn` as scene children; remove `.new()` construction
- [ ] `game_world.gd` lines 225–244: move Scanner and Mining system nodes to `game_world.tscn`; remove `.new()` construction
- [ ] `game_world.gd` lines 231–237: move ResourceWheelLayer CanvasLayer + ResourceTypeWheel to `game_world.tscn` (CANVAS_LAYER_NEW violation)
- [ ] `game_world.gd` lines 272–282: move ShipEnterZone + CollisionShape3D + BoxShape3D to `game_world.tscn`; remove `.new()` construction
- [ ] `game_world.gd` lines 303–323: move DebugShipBoardingHandler and TravelSequenceManager to `game_world.tscn`; remove `.new()` construction
- [ ] `game_world.gd` lines 373–385: move DebugOverlay CanvasLayer + Label to `game_world.tscn` (CANVAS_LAYER_NEW/LAYOUT_IN_READY violation)
- [ ] Replace all programmatic node creation with `@onready var` references; verify game world loads and all systems initialize correctly

---

## Implementation Notes

See audit report `docs/studio/reports/2026-03-03-m11-gdscript-audit.md` Section 2 rows for `game_world.gd`. Priority 3 in Section 5 (HIGH blast radius, MEDIUM effort). Be careful to preserve initialization order — some systems may depend on others being ready.

---

## Handoff Notes

(Leave blank until handoff occurs.)

---

## Activity Log

- 2026-03-03 [producer] Created ticket — Phase 2 remediation from M11 GDScript audit report (TICKET-0290)
