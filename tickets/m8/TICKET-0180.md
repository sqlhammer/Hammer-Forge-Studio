---
id: TICKET-0180
title: "Debug scene — biome spawn selector and begin-wealthy toggle"
type: FEATURE
status: IN_PROGRESS
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

- [ ] Debug scene loadable from Godot editor (`res://game/scenes/debug/debug_launcher.tscn`)
- [ ] Simple 2D menu UI with:
  - Biome selector — dropdown or button list of all registered biomes (populated from BiomeRegistry)
  - "Begin Wealthy" checkbox/toggle
  - "Launch" button
- [ ] On launch: loads selected biome, spawns player and ship at that biome's spawn point
- [ ] Begin Wealthy: if enabled, adds 200× of every resource defined in the resource registry to player inventory on spawn (Scrap Metal, Metal, Cryonite, Fuel Cell, Spare Battery, and any others registered)
- [ ] Begin Wealthy state indicated clearly in HUD during play session (e.g., "[DEBUG]" label)
- [ ] Debug scene is **editor-only** — not accessible from the game's main menu in normal play
- [ ] Adding new resources to the registry automatically includes them in the begin-wealthy grant (no hardcoded list)
- [ ] Unit tests cover: biome list populated from registry, begin-wealthy grants correct quantities for all registered resources
- [ ] Full test suite passes

## Implementation Notes

- This scene is a quality-of-life tool for Studio Head and QA — keep it simple and functional, not polished
- "Editor-only" enforcement: the scene can simply not be linked from any in-game menu; no need for compile flags
- Resource grant should iterate the resource registry dynamically so it never needs manual updating as new resources are added
- Begin-wealthy quantity (200) should be a constant at the top of the script, not a magic number buried in code

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created — M8 Gameplay phase
- 2026-02-27 [gameplay-programmer] Starting work — building debug launcher scene with biome selector, begin-wealthy toggle, and unit tests
