---
id: TICKET-0281
title: "M10 Scanner — Resource type selection radial wheel before ping (D-001)"
type: TASK
status: DONE
priority: P2
owner: gameplay-programmer
created_by: producer
created_at: 2026-03-03
updated_at: 2026-03-03
milestone: "M10"
phase: "Implementation"
depends_on: [TICKET-0277]
blocks: [TICKET-0285]
tags: [scanner, ui, radial-wheel, ping]
---

## Summary

Add a radial wheel UI that lets the player select which resource type to ping for before
firing the scanner. With two resource types now in the game (Scrap Metal, Cryonite), a
selection step makes ping results meaningful — the ring only reveals deposits matching
the chosen type.

---

## Acceptance Criteria

### Radial Wheel UI
- [x] Holding the `ping` action (Q / LB) opens the radial wheel; releasing fires the ping
      for the selected resource type
- [x] The radial wheel displays one segment per known resource type
- [x] Each segment shows the resource icon and name
- [x] The player selects a segment by moving the mouse (keyboard) or left stick (gamepad)
- [x] If the player releases `ping` without moving to a segment, the previously selected
      type is used (last-used memory, defaults to first available on first use)
- [x] Tapping `ping` without holding fires immediately with the last-used resource type
      (no wheel shown) — preserves fast-play feel

### Scanner Integration
- [x] `scanner.gd` `_do_ping()` receives the selected resource type and filters results
- [x] Only deposits matching the selected resource type are pinged and revealed on compass
- [x] If no type is selected / wheel cancelled, no ping fires

### Keyboard & Gamepad
- [x] Radial wheel works with mouse direction on keyboard/mouse
- [x] Radial wheel works with left stick direction on gamepad

### No Regressions
- [x] Ping cooldown still applies
- [x] `ping_completed` signal still emits with the filtered deposit array

---

## Implementation Notes

Depends on TICKET-0277 (action renamed from `scan` to `ping`) — use `"ping"` action name
throughout.

The radial wheel is a common Godot UI pattern: a `Control` node that samples input direction
each frame while the action is held and highlights the nearest segment. On release, fire the
ping. This should be implemented as a scene-instanced subscene for cleanliness.

Resource types should be sourced dynamically from a registry (e.g. `DepositRegistry` or a
new `ResourceTypeRegistry`) — do not hardcode Scrap Metal and Cryonite.

---

## Handoff Notes

- Created `game/scripts/ui/resource_type_wheel.gd`: radial wheel Control that builds segments dynamically from `ResourceDefs.RESOURCE_CATALOG` (raw_material category — currently Scrap Metal and Cryonite). Renders via `_draw()` with icon and label per segment, highlight on selection. Tracks last-used type for quick-tap fallback.
- Modified `game/scripts/gameplay/scanner.gd`: replaced instant ping-on-press with hold/tap detection. Hold ping beyond 0.2s opens wheel (uncaptures mouse for direction input); release fires type-filtered ping. Tap fires with last-used type. `_do_ping(filter_type)` now filters deposits by `deposit.resource_type`. `ping_completed` emits filtered array.
- Modified `game/scripts/gameplay/game_world.gd`: instantiates `ResourceTypeWheel` on a `CanvasLayer` (layer 5) and passes it to Scanner via `set_resource_wheel()`.
- Mouse is uncaptured while wheel is open (first-person controller guards on `MOUSE_MODE_CAPTURED`, so camera stops rotating during selection).
- Gamepad uses left stick for segment selection.
- Note: `.gd.uid` for `resource_type_wheel.gd` may need manual commit after Godot editor scans (editor MCP not available during this session).

---

## Activity Log

- 2026-03-03 [producer] Created ticket — M10 scanner: resource type radial wheel (D-001)
- 2026-03-03 [gameplay-programmer] Starting work
- 2026-03-03 [gameplay-programmer] DONE — commit e2a6058, PR https://github.com/sqlhammer/Hammer-Forge-Studio/pull/312
