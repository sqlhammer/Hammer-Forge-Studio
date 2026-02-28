---
id: TICKET-0214
title: "Feature — Ship marker persistently visible on compass at all times"
type: FEATURE
status: IN_PROGRESS
priority: P2
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-28
updated_at: 2026-02-28
milestone: "M8"
phase: "QA"
depends_on: []
blocks: []
tags: [feature, compass, ship, navigation, hud, m8-qa]
---

## Summary

The ship has no marker on the compass. Players cannot determine the ship's direction without visually spotting it, which is difficult in large biomes. The ship should have a persistent compass marker visible at all times (not ping-dependent), so players can always navigate back to the ship.

## Acceptance Criteria

- [ ] A persistent ship marker is always visible on the compass HUD, indicating the bearing to the ship
- [ ] The marker is visually distinct from deposit ping markers (different icon or color — e.g., use a ship icon or white/amber instead of teal)
- [ ] The marker shows the distance to the ship when the player is facing within the distance cone (consistent with deposit marker behavior)
- [ ] The marker does not require a ping — it is always present from the moment the biome loads
- [ ] The marker updates correctly as the ship repositions between biomes
- [ ] Fix does not affect existing deposit ping markers
- [ ] Full test suite passes with no new failures

## Implementation Notes

- `CompassBar` currently only renders deposit ping markers from `_ping_markers`; add a separate `_ship_target: Node3D` reference and draw it in `_draw_ping_markers()` (or a new `_draw_ship_marker()` method) using the same `_bearing_to_screen_x()` helper
- Add a `set_ship_target(ship: Node3D)` method to `CompassBar` so `GameHUD` or the scene controller can pass the ship node reference after biome load
- Recommended icon: load `icon_hud_compass_center.svg` variant or a distinct ship SVG; if no ship icon exists, use a distinct color (e.g., `Color("#F59E0B")` amber) with the existing triangle polygon fallback
- Wire the ship reference in `GameHUD.setup()` or wherever the biome scene initializes the compass

## Activity Log

- 2026-02-28 [producer] Created — Studio Head requested during M8 playtest
- 2026-02-28 [gameplay-programmer] IN_PROGRESS — Starting work
