---
id: TICKET-0234
title: "Root Game: Deprecate TestWorld — remove files and update affected tests"
type: TASK
status: OPEN
priority: P1
owner: qa-engineer
created_by: producer
created_at: 2026-02-28
updated_at: 2026-02-28
milestone: "M9"
phase: "Root Game"
depends_on: [TICKET-0230, TICKET-0232, TICKET-0233]
blocks: [TICKET-0235]
tags: [root-game, test-world, deprecation, tests, qa]
---

## Summary

`TestWorld` (`game/scenes/levels/test_world.tscn` + `game/scripts/levels/test_world.gd`) is superseded by `GameWorld` (TICKET-0230). This ticket removes the TestWorld files and updates all tests that referenced them. Each affected test must be updated to either:

- **Option A (preferred):** Instantiate the specific node/system under test directly (no world scene required) — appropriate for unit tests.
- **Option B:** Drive through the game scene and main menu to load GameWorld — appropriate only for integration tests that genuinely require a full world.

## Files to Delete

- `game/scenes/levels/test_world.tscn`
- `game/scripts/levels/test_world.gd`

Confirm no other scripts import or `preload` these files before deleting.

## Tests to Update

The following test files currently reference `TestWorld` or `test_world.tscn` and must be updated:

| Test File | Reference Type | Recommended Fix |
|-----------|---------------|-----------------|
| `game/tests/test_collision_coverage_unit.gd` | Instantiates TestWorld to test collision shapes | Instantiate biome node and ship exterior directly using their own scenes/scripts |
| `game/tests/test_debris_field_biome_unit.gd` | Instantiates TestWorld to test debris field biome | Instantiate `DebrisFieldBiome` node directly |
| `game/tests/test_rock_warrens_biome_unit.gd` | Instantiates TestWorld to test Rock Warrens biome | Instantiate `RockWarrensBiome` node directly |
| `game/tests/test_world_boundary_unit.gd` | Tests world boundary via TestWorld | Instantiate world boundary node(s) directly |
| `game/tests/m8_phase_gate_regression_template.gd` | Template referencing TestWorld | Update template to reference GameWorld or remove the TestWorld-specific references |

## Acceptance Criteria

- [ ] `game/scenes/levels/test_world.tscn` is deleted.
- [ ] `game/scripts/levels/test_world.gd` is deleted.
- [ ] All five test files above compile with zero parse errors after the update.
- [ ] All tests that previously passed continue to pass after the refactor (no regressions introduced by the migration).
- [ ] No remaining references to `TestWorld` or `test_world.tscn` exist anywhere in `game/tests/` or `game/scripts/`.
- [ ] `grep -r "TestWorld\|test_world" game/tests/ game/scripts/` returns zero results.

## Implementation Notes

- For `test_collision_coverage_unit.gd`: read how it uses TestWorld — it likely instantiates the scene and then checks collision shapes on child nodes. Replace the TestWorld instantiation with direct instantiation of the relevant scenes (`ship_exterior.tscn`, a biome scene, or a resource node scene).
- For biome unit tests: the biome scripts are `Node3D`-based and can be instantiated directly. Call `generate()` / `build_scene()` as appropriate (same as `DebugLauncher._initialize_biome()` did).
- For `test_world_boundary_unit.gd`: if it tests boundary walls, those can be instantiated directly. If the boundary is part of a larger scene, create a minimal test scene or instantiate the boundary node class.
- Do not rewrite test logic — only change how the scene/node under test is obtained. Keep assertions and test structure identical where possible.
- After updates, run the full test suite to confirm no regressions.

## Activity Log

- 2026-02-28 [producer] Created ticket — TestWorld deprecation and test migration for Root Game phase
