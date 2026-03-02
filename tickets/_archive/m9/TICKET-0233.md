---
id: TICKET-0233
title: "Root Game: Refactor DebugLauncher — set startup params, hand off to Main Menu"
type: REFACTOR
status: DONE
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-28
updated_at: 2026-03-02
milestone: "M9"
phase: "Root Game"
depends_on: [TICKET-0229, TICKET-0231, TICKET-0232]
blocks: [TICKET-0234, TICKET-0220]
tags: [root-game, debug-launcher, refactor, begin-wealthy]
---

## Summary

Refactor `DebugLauncher` so it no longer builds or launches game worlds directly. Its two interactive controls (biome selector, begin-wealthy toggle) now write to `Global.starting_biome` and `Global.starting_inventory`. The Launch button transitions to the `MainMenu` scene and frees the debug launcher. All direct world-building code is removed.

Additionally, the begin-wealthy inventory set is revised: instead of a flat 200 of each resource, it grants **one full stack** of each resource/material (i.e., `ResourceDefs.get_stack_size(resource_type)` quantity per type).

## Acceptance Criteria

### Biome Selector
- [x] The `OptionButton` still lists all registered biomes from `BiomeRegistry` (unchanged).
- [x] When the selected biome changes (or on init), `Global.starting_biome` is set to the selected biome ID.
- [x] Default selection remains Shattered Flats (index 0, ID `"shattered_flats"`), matching `Global.starting_biome`'s default.

### Begin Wealthy
- [x] The `CheckBox` still exists with label `"Begin Wealthy (1× full stack, all resources)"` (label updated to reflect new quantity).
- [x] When the checkbox is toggled ON, `Global.starting_inventory` is populated: for each `ResourceDefs.ResourceType` (excluding `NONE`), set `Global.starting_inventory[resource_type] = ResourceDefs.get_stack_size(resource_type)`.
- [x] When toggled OFF, `Global.starting_inventory` is reset to `{}`.
- [x] `Global.starting_inventory` is updated immediately on toggle, not deferred to Launch.

### Launch Button
- [x] Button label remains `"LAUNCH"`.
- [x] On press: call `get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")`. The `Game` root scene is still the scene root; this call replaces the current scene — use `get_tree().current_scene = ...` / `queue_free()` pattern if `change_scene_to_file` is not viable from a child node. Coordinate with TICKET-0232 implementation to confirm the correct transition API from a child node context.
- [x] The launcher frees itself (or is freed as part of the transition) — it does not persist after the main menu loads.
- [x] No world-building, no `PlayerInventory` mutation, no scene construction in the launch handler — those happen in `GameWorld._ready()`.

### Code Removal
- [x] `_launch()`, `_build_debug_world()`, `_create_biome_instance()`, `_initialize_biome()`, `_get_spawn_positions()`, `_add_environment()`, `_setup_gameplay()`, `_setup_ship_boarding()`, `_add_debug_overlay()` are all removed (this logic now lives in `GameWorld`).
- [x] `grant_wealthy_resources()` static method is removed (inventory is now set via `Global.starting_inventory`, not applied directly in the launcher).
- [x] `_BIOME_SCRIPTS` const is removed (no longer needed in the launcher; moved to `GameWorld`).
- [x] `BEGIN_WEALTHY_QUANTITY` and `DEFAULT_PURITY` constants are removed.
- [x] `INTERIOR_Y_OFFSET` constant is removed.
- [x] `get_biome_entries()` static method is kept — it remains useful.
- [x] `_status_label` is removed (no launch errors to display).

### Constraints
- [x] `debug_launcher.gd` must still compile with zero parse errors after removal of the dead code.
- [x] The debug_launcher scene (`debug_launcher.tscn`) requires no structural changes — it is still a `Control` node with the launcher script.

## Implementation Notes

- The `_on_launch_pressed()` handler is now a 2-line function: set the transition in motion, free self.
- Because `DebugLauncher` is a child of `Game` (added in TICKET-0232), calling `get_tree().change_scene_to_file()` from a child node will work if called on the scene tree root. Alternatively, emit a signal to `Game` asking it to perform the transition. Coordinate with TICKET-0232 implementation.
- One clean approach: emit `signal launch_requested` from the launcher; `Game._ready()` connects to it and performs the `change_scene_to_file()` transition.
- `Global.starting_inventory` is populated as `{ ResourceDefs.ResourceType.IRON: 100, ResourceDefs.ResourceType.CRYONITE: 50, ... }` where each value equals `ResourceDefs.get_stack_size(type)`.

## Activity Log

- 2026-02-28 [producer] Created ticket — DebugLauncher refactor for Root Game phase
- 2026-03-01 [gameplay-programmer] Starting work — all dependencies DONE (0229, 0231, 0232)
- 2026-03-02 [gameplay-programmer] DONE — refactored debug_launcher.gd (519→159 lines). Removed all world-building logic. Biome selector writes Global.starting_biome, begin-wealthy toggle writes Global.starting_inventory with full-stack quantities, Launch transitions to main_menu.tscn. Commit: 53c57f6, PR: #254. Note: test_debug_launcher_unit.gd references removed APIs (grant_wealthy_resources, BEGIN_WEALTHY_QUANTITY) — QA will update via TICKET-0234/0235.
