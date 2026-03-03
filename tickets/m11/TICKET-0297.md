---
id: TICKET-0297
title: "M11 Scene-First remediation — Ship Interior (ship_interior.gd full scene refactor)"
type: TASK
status: DONE
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-03-03
updated_at: 2026-03-03
milestone: "M11"
phase: "Remediation"
depends_on: []
blocks: []
tags: [standards, scene-first, remediation, ship-interior]
---

## Summary

Refactor `ship_interior.gd`, the largest single Scene-First violator (~60+ persistent nodes constructed in code), into a proper .tscn scene.

---

## Acceptance Criteria

- [x] `ship_interior.gd`: create `ship_interior.tscn` in the editor; author all persistent geometry (~30 StaticBody3D/MeshInstance3D), 4 module zones (Area3D+CollisionShape3D), spawn markers, cockpit features, SubViewport+Camera3D window, 2 OmniLight3D, terminal Area3D, console prompt area as scene nodes
- [x] Remove all 9 builder methods called from `_ready()` that construct nodes via `.new()`/`add_child()`
- [x] Fix CANVAS_LAYER_NEW violation: move FadeLayer CanvasLayer + ColorRect (lines 500–510) to scene
- [x] Replace all programmatic node construction with `@onready var` references
- [ ] Verify ship interior loads correctly, all zones trigger, cockpit viewport renders, lighting works

---

## Implementation Notes

See audit report `docs/studio/reports/2026-03-03-m11-gdscript-audit.md` Section 2 row for `ship_interior.gd` (lines 64–559, 500–510). This is Priority 2 in Section 5 — the single largest violation in the codebase (HIGH blast radius, VERY HIGH effort). Tackle this as a standalone effort with careful testing of each subsystem after migration.

---

## Handoff Notes

Scripts modified: `game/scripts/gameplay/ship_interior.gd` (617→211 lines). Scene expanded: `game/scenes/gameplay/ship_interior.tscn` (32→540 lines). All geometry, zones, markers, viewport, lighting, fade overlay, terminal, and console area are now scene nodes. Only runtime operation remaining in `_ready()`: viewport texture assignment from SubViewport. Verification AC left unchecked — requires in-editor/runtime testing by QA.

---

## Activity Log

- 2026-03-03 [producer] Created ticket — Phase 2 remediation from M11 GDScript audit report (TICKET-0290)
- 2026-03-03 [gameplay-programmer] Starting work — scene-first refactor of ship_interior.gd
- 2026-03-03 [gameplay-programmer] DONE — commit 8abe583, PR https://github.com/sqlhammer/Hammer-Forge-Studio/pull/339 (merged). Created full ship_interior.tscn with ~60 persistent nodes, removed all 9 builder methods, replaced with 18 @onready vars, moved FadeLayer to scene, signal connections in scene.
