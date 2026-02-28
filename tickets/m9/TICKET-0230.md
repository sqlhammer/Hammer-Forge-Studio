---
id: TICKET-0230
title: "Root Game: Create GameWorld scene — world-building extracted from DebugLauncher"
type: TASK
status: OPEN
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-28
updated_at: 2026-02-28
milestone: "M9"
phase: "Root Game"
depends_on: [TICKET-0229]
blocks: [TICKET-0231, TICKET-0234]
tags: [root-game, game-world, scene, refactor]
---

## Summary

Extract the world-building logic currently embedded in `DebugLauncher._launch()` / `_build_debug_world()` into a standalone `GameWorld` scene and script. This scene becomes the actual gameplay scene — when Play is pressed in the main menu, it transitions to `GameWorld`, which reads `Global.starting_biome` and `Global.starting_inventory` to configure itself.

`TestWorld` (`game/scenes/levels/test_world.tscn` + `game/scripts/levels/test_world.gd`) is superseded by this scene. TestWorld deprecation (file deletion + test updates) is handled in TICKET-0234; this ticket focuses only on creating the new scene.

## Acceptance Criteria

- [ ] New script `game/scripts/gameplay/game_world.gd` with `class_name GameWorld extends Node3D`.
- [ ] New scene `game/scenes/gameplay/game_world.tscn` using `GameWorld` as its script.
- [ ] On `_ready()`, `GameWorld` reads `Global.starting_biome` and uses it to instantiate the correct biome (Shattered Flats, Rock Warrens, or Debris Field) — same biome instantiation logic as `DebugLauncher._create_biome_instance()`.
- [ ] On `_ready()`, `GameWorld` reads `Global.starting_inventory`. If non-empty, it calls `PlayerInventory.add_item()` for each entry (resource_type → quantity). Empty dict = no grants.
- [ ] Environment lighting setup (sky, sun, ambient) matches what `DebugLauncher._add_environment()` currently produces.
- [ ] Ship exterior is instantiated at the biome's ship spawn position.
- [ ] Player is instantiated at the biome's player spawn position.
- [ ] Scanner, Mining, GameHUD, and ShipBoarding are set up — identical to `DebugLauncher._setup_gameplay()` and `_setup_ship_boarding()`.
- [ ] Mouse is captured on load (`Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)`).
- [ ] `Global.log()` calls at key steps (biome loaded, inventory applied, scene ready).
- [ ] `GameWorld` does **not** depend on `DebugLauncher` at all — no references to the launcher.

## Implementation Notes

- Move `_build_debug_world()`, `_add_environment()`, `_create_biome_instance()`, `_initialize_biome()`, `_get_spawn_positions()`, `_setup_gameplay()`, `_setup_ship_boarding()` logic out of `debug_launcher.gd` into `game_world.gd`. The functions can be inlined or kept as private helpers.
- The biome ID → script mapping (`_BIOME_SCRIPTS` const) should move to `GameWorld` (or reference `BiomeRegistry` — whichever is cleaner).
- `game_world.tscn` is a minimal scene file — the scene tree is built programmatically in `_ready()` as it currently is in `DebugLauncher`.
- `NavigationSystem.current_biome` should be set to `Global.starting_biome` when the world loads (mirrors what `DebugLauncher._launch()` does).
- Game state reset (`PlayerInventory.clear_all()`, `NavigationSystem.reset()`, `FuelSystem.reset_to_full()`, `ShipState.reset()`) happens in `GameWorld._ready()` before applying `starting_inventory`, so the inventory grant is always applied to a clean state.
- The debug overlay (`[DEBUG]` label) from `DebugLauncher._add_debug_overlay()` can be preserved: add it if `Global.starting_inventory` is non-empty (indicates a modified debug session).

## Activity Log

- 2026-02-28 [producer] Created ticket — extract world-building from DebugLauncher into proper GameWorld scene
