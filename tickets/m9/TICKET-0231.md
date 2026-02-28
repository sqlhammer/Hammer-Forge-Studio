---
id: TICKET-0231
title: "Root Game: Create Main Menu scene with Play button"
type: TASK
status: OPEN
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-28
updated_at: 2026-02-28
milestone: "M9"
phase: "Root Game"
depends_on: [TICKET-0229, TICKET-0230]
blocks: [TICKET-0232, TICKET-0233]
tags: [root-game, main-menu, ui, scene]
---

## Summary

Create the game's main menu — a minimal `Control`-based scene with a single "Play" button. When Play is pressed, the game transitions to `GameWorld` (`game/scenes/gameplay/game_world.tscn`), which reads `Global.starting_biome` and `Global.starting_inventory` to configure itself. The main menu is the final step in the launch flow for both normal play and debug play.

## Acceptance Criteria

- [ ] New script `game/scripts/ui/main_menu.gd` with `class_name MainMenu extends Control`.
- [ ] New scene `game/scenes/ui/main_menu.tscn` using `MainMenu` as its script.
- [ ] Scene displays a single "Play" `Button` centered on screen.
- [ ] Button label is exactly `"Play"`.
- [ ] Pressing Play transitions to `res://scenes/gameplay/game_world.tscn` via `get_tree().change_scene_to_file()`.
- [ ] The main menu UI is built programmatically in `_ready()` (no editor-placed nodes required beyond the root Control) — consistent with `DebugLauncher` style.
- [ ] Background uses dark color matching the game's aesthetic (consistent with `DebugLauncher`'s `#1a1a2e` background).
- [ ] `Global.log()` call when Play is pressed.
- [ ] No dependency on `DebugLauncher` — the main menu is unaware of how parameters were set.

## Implementation Notes

- The main menu does **not** reset game state or apply inventory — that happens in `GameWorld._ready()`. The main menu's only job is to present the Play button and trigger the scene transition.
- Keep the UI minimal for this phase — no title logo, no settings menu, no credits. Those can be added in a future milestone.
- The scene path for GameWorld is `res://scenes/gameplay/game_world.tscn`.
- `change_scene_to_file()` is the correct method for deferred scene transitions in Godot 4.

## Activity Log

- 2026-02-28 [producer] Created ticket — main menu scene for Root Game phase
