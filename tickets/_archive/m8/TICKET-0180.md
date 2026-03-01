---
id: TICKET-0180
title: "Debug scene — biome spawn selector and begin-wealthy toggle"
type: FEATURE
status: DONE
priority: P2
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "M8"
phase: "Gameplay"
depends_on: [TICKET-0157, TICKET-0159]
blocks: []
tags: [debug, tooling, biome, spawn, m8-gameplay]
---

## Summary

A dedicated debug scene for Studio Head playtesting. Provides a simple menu UI that lets the user select which biome to spawn the player and ship into, and toggle "begin wealthy" mode which pre-fills the inventory with at least 200 of every known game resource. Skips resource gathering so other systems (navigation, crafting, fuel, travel) can be tested in isolation.

## Acceptance Criteria

- [x] Debug scene loadable from Godot editor (`res://game/scenes/debug/debug_launcher.tscn`)
- [x] Simple 2D menu UI with:
  - Biome selector — dropdown or button list of all registered biomes (populated from BiomeRegistry)
  - "Begin Wealthy" checkbox/toggle
  - "Launch" button
- [x] On launch: loads selected biome, spawns player and ship at that biome's spawn point
- [x] Begin Wealthy: if enabled, adds 200× of every resource defined in the resource registry to player inventory on spawn (Scrap Metal, Metal, Cryonite, Fuel Cell, Spare Battery, and any others registered)
- [x] Begin Wealthy state indicated clearly in HUD during play session (e.g., "[DEBUG]" label)
- [x] Debug scene is **editor-only** — not accessible from the game's main menu in normal play
- [x] Adding new resources to the registry automatically includes them in the begin-wealthy grant (no hardcoded list)
- [x] Unit tests cover: biome list populated from registry, begin-wealthy grants correct quantities for all registered resources
- [ ] Full test suite passes (pending QA engineer run)

## Implementation Notes

- This scene is a quality-of-life tool for Studio Head and QA — keep it simple and functional, not polished
- "Editor-only" enforcement: the scene can simply not be linked from any in-game menu; no need for compile flags
- Resource grant should iterate the resource registry dynamically so it never needs manual updating as new resources are added
- Begin-wealthy quantity (200) should be a constant at the top of the script, not a magic number buried in code

## Handoff Notes

**Files created:**
- `game/scripts/gameplay/debug_launcher.gd` — DebugLauncher class (Control), builds UI programmatically
- `game/scenes/debug/debug_launcher.tscn` — Minimal 2D scene wrapping the DebugLauncher
- `game/tests/test_debug_launcher_unit.gd` — 14 unit tests for biome list + begin-wealthy

**Public API (for testing):**
- `DebugLauncher.get_biome_entries() -> Array[Dictionary]` — returns [{id, display_name}] from BiomeRegistry
- `DebugLauncher.grant_wealthy_resources() -> Dictionary` — grants BEGIN_WEALTHY_QUANTITY of each resource, returns {ResourceType: quantity_granted}
- `DebugLauncher.BEGIN_WEALTHY_QUANTITY: int = 200` — constant for grant quantity

**Known limitations:**
- Inventory has 15 slots; 200x of every resource may not all fit (Spare Battery stack_size=1). Resources are granted in catalog order; overflow is handled gracefully.
- Biome API inconsistencies (different method names across biomes) are handled via duck-typing in `_get_spawn_positions()` and `_initialize_biome()`.
- UID sidecar files pending — Godot editor was not available during implementation wave.

## Activity Log

- 2026-02-27 [producer] Created — M8 Gameplay phase
- 2026-02-27 [gameplay-programmer] Starting work — building debug launcher scene with biome selector, begin-wealthy toggle, and unit tests
- 2026-02-27 [gameplay-programmer] DONE — commit 9099115 (merge), PR https://github.com/sqlhammer/Hammer-Forge-Studio/pull/158. Files: game/scripts/gameplay/debug_launcher.gd, game/scenes/debug/debug_launcher.tscn, game/tests/test_debug_launcher_unit.gd. UID sidecar pending (Godot editor unavailable).
