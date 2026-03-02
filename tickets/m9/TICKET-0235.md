---
id: TICKET-0235
title: "Root Game: QA Gate and Phase Sign-Off"
type: QA
status: OPEN
priority: P1
owner: qa-engineer
created_by: producer
created_at: 2026-02-28
updated_at: 2026-02-28
milestone: "M9"
phase: "Root Game"
depends_on: [TICKET-0229, TICKET-0230, TICKET-0231, TICKET-0232, TICKET-0233, TICKET-0234]
blocks: []
tags: [root-game, qa, tests]
---

## Summary

Write unit tests for all new systems introduced in the Root Game phase, then validate the full test suite passes with zero failures.

## New Systems to Test

### Global startup params (TICKET-0229)
- `Global.starting_biome` defaults to `"shattered_flats"`.
- `Global.starting_inventory` defaults to `{}`.
- Both properties accept assignment and retain new values.

### GameWorld (TICKET-0230)
- `GameWorld` reads `Global.starting_biome` and instantiates the correct biome.
- `GameWorld` applies `Global.starting_inventory` — items are present in `PlayerInventory` after `_ready()` completes.
- An empty `Global.starting_inventory` results in no inventory items granted.
- Game state is reset before inventory is applied (clean slate).

### MainMenu (TICKET-0231)
- `MainMenu` scene instantiates without errors.
- A `Button` node named `"PlayButton"` (or equivalent) is present after `_ready()`.
- Pressing the button calls `get_tree().change_scene_to_file(...)` with the correct path (`res://scenes/gameplay/game_world.tscn`).

### DebugLauncher post-refactor (TICKET-0233)
- `DebugLauncher.get_biome_entries()` still returns entries for all registered biomes.
- `Global.starting_biome` is set to the selected biome ID when the biome selector changes.
- `Global.starting_inventory` is populated with one full stack per resource when begin-wealthy is toggled ON.
- `Global.starting_inventory` is reset to `{}` when begin-wealthy is toggled OFF.
- `DebugLauncher` no longer has `grant_wealthy_resources()`, `_launch()`, or `_build_debug_world()` methods.

## Acceptance Criteria

- [ ] New test file `game/tests/test_game_startup_unit.gd` created covering Global params, MainMenu, and DebugLauncher behavior listed above.
- [ ] New test file `game/tests/test_game_world_unit.gd` (or extend existing world tests) covering GameWorld startup behavior.
- [ ] All new tests pass.
- [ ] Full test suite passes with zero failures (`res://addons/hammer_forge_tests/test_runner.tscn`).
- [ ] Test count is greater than the count at the start of the Root Game phase (new tests are additive).
- [ ] Phase Gate Summary report posted to `docs/studio/reports/`.

## Activity Log

- 2026-02-28 [producer] Created ticket — QA gate for Root Game phase
