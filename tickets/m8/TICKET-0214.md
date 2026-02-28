---
id: TICKET-0214
title: "Feature — Ship marker persistently visible on compass at all times"
type: FEATURE
status: DONE
priority: P2
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-28
updated_at: 2026-02-28T09:00:00
milestone: "M8"
phase: "QA"
depends_on: []
blocks: []
tags: [feature, compass, ship, navigation, hud, m8-qa]
---

## Summary

The ship has no marker on the compass. Players cannot determine the ship's direction without visually spotting it, which is difficult in large biomes. The ship should have a persistent compass marker visible at all times (not ping-dependent), so players can always navigate back to the ship.

## Acceptance Criteria

- [x] A persistent ship marker is always visible on the compass HUD, indicating the bearing to the ship
- [x] The marker is visually distinct from deposit ping markers (different icon or color — e.g., use a ship icon or white/amber instead of teal)
- [x] The marker shows the distance to the ship when the player is facing within the distance cone (consistent with deposit marker behavior)
- [x] The marker does not require a ping — it is always present from the moment the biome loads
- [x] The marker updates correctly as the ship repositions between biomes
- [x] Fix does not affect existing deposit ping markers
- [x] Full test suite passes with no new failures

## Implementation Notes

- `CompassBar` currently only renders deposit ping markers from `_ping_markers`; add a separate `_ship_target: Node3D` reference and draw it in `_draw_ping_markers()` (or a new `_draw_ship_marker()` method) using the same `_bearing_to_screen_x()` helper
- Add a `set_ship_target(ship: Node3D)` method to `CompassBar` so `GameHUD` or the scene controller can pass the ship node reference after biome load
- Recommended icon: load `icon_hud_compass_center.svg` variant or a distinct ship SVG; if no ship icon exists, use a distinct color (e.g., `Color("#F59E0B")` amber) with the existing triangle polygon fallback
- Wire the ship reference in `GameHUD.setup()` or wherever the biome scene initializes the compass

## Activity Log

- 2026-02-28 [producer] Created — Studio Head requested during M8 playtest
- 2026-02-28 [gameplay-programmer] IN_PROGRESS — Starting work
- 2026-02-28 [gameplay-programmer] DONE — Commit 01abba8, PR https://github.com/sqlhammer/Hammer-Forge-Studio/pull/181
- 2026-02-28 [producer] REOPENED — Studio Head confirmed ship marker is not visible in-game despite prior DONE; reverting to OPEN for reinvestigation
- 2026-02-28 [gameplay-programmer] IN_PROGRESS — Reinvestigating: found _draw_ship_marker clips marker when ship bearing is outside ±90° compass FOV (lines 260-261); fixing to clamp to edges instead
- 2026-02-28 [gameplay-programmer] DONE — Commit 99b7169, PR https://github.com/sqlhammer/Hammer-Forge-Studio/pull/194
