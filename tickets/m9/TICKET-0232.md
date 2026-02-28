---
id: TICKET-0232
title: "Root Game: Create game root scene with debug-mode routing; set as project main scene"
type: TASK
status: OPEN
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-28
updated_at: 2026-02-28
milestone: "M9"
phase: "Root Game"
depends_on: [TICKET-0231]
blocks: [TICKET-0233, TICKET-0234]
tags: [root-game, game-scene, routing, project-settings]
---

## Summary

Create the root `game` scene — the project's new main scene. It acts as a router: in debug builds it instantiates and adds `DebugLauncher` as a child; in release builds it loads the `MainMenu` scene. This is the single entry point for the entire game.

## Acceptance Criteria

- [ ] New script `game/scripts/gameplay/game.gd` with `class_name Game extends Node`.
- [ ] New scene `game/scenes/gameplay/game.tscn` using `Game` as its script.
- [ ] In `_ready()`:
  - If `OS.is_debug_build()` is `true`: instantiate `DebugLauncher` (preloaded from `res://scenes/debug/debug_launcher.tscn`) and add it as a child.
  - Else: call `get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")`.
- [ ] `game.tscn` is set as the project's **Main Scene** in `project.godot` (`application/run/main_scene`).
- [ ] `Global.log()` call in `_ready()` noting which path is taken (debug vs release).
- [ ] No other scenes (test_world, debug_launcher) are referenced in `project.godot` as the main scene.

## Implementation Notes

- `OS.is_debug_build()` returns `true` when running from the Godot editor or from a debug export. This is the correct check for "are we in debug mode."
- The debug path adds `DebugLauncher` as a child of `Game` (rather than changing the scene) so that `Game` remains the current scene root throughout the debug session. When the user clicks Launch in the debug launcher, the launcher frees itself and the game scene then loads the main menu.
- The release path uses `change_scene_to_file()` to replace `Game` with `MainMenu` — a clean transition with no lingering `Game` node.
- `project.godot` edit: find the `[application]` section and update `run/main_scene` to `"res://scenes/gameplay/game.tscn"`. Verify no other keys reference the old main scene.
- Confirm the debug_launcher scene path is `res://scenes/debug/debug_launcher.tscn` before writing the preload.

## Activity Log

- 2026-02-28 [producer] Created ticket — game root scene and project entry point for Root Game phase
