---
id: TICKET-0169
title: "Fuel consumption HUD — low-fuel warning, tank gauge display"
type: FEATURE
status: DONE
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "M8"
phase: "Gameplay"
depends_on: [TICKET-0158, TICKET-0165]
blocks: []
tags: [hud, fuel, warning, gauge, m8-gameplay]
---

## Summary

Implement the persistent fuel gauge HUD element. Displays the ship's current fuel level at all times. Shows a low-fuel warning state at ≤25% and a distinct empty state at 0. Follows the wireframe from TICKET-0165.

## Acceptance Criteria

- [x] Fuel gauge visible in HUD at all times (not only inside ship)
- [x] Gauge updates in real time when fuel changes (listens to `FuelSystem.fuel_changed` signal)
- [x] Three visual states: normal (>25%), low-fuel warning (≤25%, amber — consistent with battery warning), empty (0%, distinct color/icon)
- [x] Low-fuel warning state triggered by `FuelSystem.fuel_low` signal
- [x] Empty state triggered by `FuelSystem.fuel_empty` signal
- [x] HUD positioned per TICKET-0165 wireframe — no overlap with compass, battery bar, or other HUD elements
- [x] Unit tests cover: normal state, low-fuel threshold transition, empty state, signal-driven updates
- [x] Full test suite passes

## Implementation Notes

- Follow the battery bar implementation as a reference for signal-driven HUD updates and color state transitions
- Fuel gauge should use the same visual language as the battery bar for consistency (bar fill, color tiers)

## Handoff Notes

FuelGauge HUD element implemented and integrated into GameHUD. Key files and API:

**Scripts:**
- `game/scripts/ui/fuel_gauge.gd` — FuelGauge class, custom-drawn bar with icon + progress + label
- `game/scripts/ui/game_hud.gd` — Updated with `_fuel_gauge` reference and `get_fuel_gauge()` getter

**Scene:**
- `game/scenes/ui/fuel_gauge.tscn` — Standalone scene wrapping FuelGauge Control
- Added as child of HUDRoot in `game/scenes/ui/game_hud.tscn`

**Signal connections (automatic in _ready):**
- `FuelSystem.fuel_changed` → `_on_fuel_changed(current, maximum)`
- `FuelSystem.fuel_low` → `_on_fuel_low()`
- `FuelSystem.fuel_empty` → `_on_fuel_empty()`

**Public API:**
- `set_fuel_level(current: float, maximum: float)` — manual update method
- `get_percent_text() -> String` — returns formatted "XX%" string

**Visual states:**
- Full (100%): Green #4ADE80
- Normal (26–99%): Teal #00D4AA
- Low (1–25%): Amber #FFB830 with pulse animation
- Empty (0%): Coral #FF6B5A with flash animation (3s then 50% opacity hold)

**Positioning:** Bottom-center, 32px from bottom edge, centered horizontally

**Note:** GDScript UIDs pending Godot filesystem scan (MCP unavailable this wave).

## Activity Log

- 2026-02-27 [producer] Created — M8 Gameplay phase
- 2026-02-27 [gameplay-programmer] Starting work — implementing fuel gauge HUD with signal-driven updates, three visual states, and unit tests
- 2026-02-27 [gameplay-programmer] DONE — commit eb827df, PR https://github.com/sqlhammer/Hammer-Forge-Studio/pull/156 (merged). Implemented FuelGauge (fuel_gauge.gd), fuel_gauge.tscn, integrated into game_hud.tscn/gd, 22 unit tests in test_fuel_gauge_unit.gd. GDScript UIDs pending Godot filesystem scan (no MCP access this wave).
