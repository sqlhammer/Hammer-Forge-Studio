---
id: TICKET-0119
title: "Bugfix — Fabricator module collision box undersized on Z-axis (fails AABB coverage)"
type: BUGFIX
status: TODO
priority: P2
owner: gameplay-programmer
created_by: qa-engineer
created_at: 2026-02-25
updated_at: 2026-02-25
milestone: ""
phase: ""
depends_on: []
blocks: []
tags: [bugfix, collision, fabricator, test-failure]
---

## Summary
The fabricator module's collision/interaction box is undersized on the Z-axis. The collision coverage test (`test_collision_coverage_unit.gd`) reports Z-axis AABB coverage of **0.83**, which falls below the **0.85** threshold. The box dimensions are `Vector3(2.0, 1.2, 1.0)` but the mesh extends slightly beyond the 1.0m Z extent.

## Reproduction
1. Run the collision coverage test suite via `test_runner.tscn`
2. Observe `fabricator_module_aabb_coverage` fails:
   ```
   FAIL: fabricator_module_aabb_coverage -- fabricator_module Z-axis coverage 0.83 below threshold 0.85
   ```

## Root Cause
The fabricator's BoxShape3D Z-dimension (`1.0m`) was set from the SOP estimate but does not account for the actual mesh AABB on that axis. The mesh extends ~0.2m beyond the collision box on Z.

## Fix
Increase the fabricator collision box Z-dimension from `1.0` to approximately `1.2` (exact value should be validated against the mesh AABB to reach >= 0.85 coverage).

### Files to update

1. **`game/scripts/levels/test_world.gd`** — two locations:
   - Line 535: `_add_interaction_area(mesh_node, Vector3(2.0, 1.2, 1.0))` — update Z
   - Line 539: `_place_module_fallback("FabricatorModule", Vector3(2.0, 1.2, 1.0), ...)` — update Z

2. **`game/tests/test_collision_coverage_unit.gd`** — one location:
   - Line 182: `_create_box_collision(root, Vector3(2.0, 1.2, 1.0), ...)` — update Z to match

Both the game code and test harness must use the same dimensions.

## Acceptance Criteria
- [ ] `fabricator_module_aabb_coverage` test passes (Z-axis coverage >= 0.85)
- [ ] All 16 collision coverage tests pass
- [ ] No visual regression — fabricator collision box still fits the mesh without overshooting significantly
- [ ] Game code and test harness use the same collision dimensions
- [ ] All code follows `docs/engineering/coding-standards.md`

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-25 [qa-engineer] Created ticket from collision test run — 15/16 passed, fabricator Z-axis coverage 0.83 < 0.85
