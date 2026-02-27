---
id: TICKET-0208
title: "Bugfix — Debug launcher world has no ShipEnterZone; boarding impossible from debug launch"
type: BUGFIX
status: TODO
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "M8"
phase: "QA"
depends_on: []
blocks: []
tags: [bugfix, debug-launcher, ship, boarding, enter-zone, m8-qa]
---

## Summary

The debug launcher builds its own minimal `DebugWorld` containing a raw `ship_exterior.tscn` node. It does not use `TestWorld` and never calls `_setup_ship_interior()`. As a result, no `ShipEnterZone` is ever created in a debug-launched session — the player cannot board the ship regardless of proximity.

The fix from TICKET-0207 (initial placement of the boarding zone) was applied to `test_world.gd` only. It has no effect here because `TestWorld` is never instantiated by the debug launcher.

## Steps to Reproduce

1. Launch any biome via `res://game/scenes/debug/debug_launcher.tscn`
2. Walk up to the ship and stand against the hull
3. Observe: no "Enter Ship" prompt, E does nothing, no boarding zone collision shape visible in debug view

## Expected Behavior

The ship boarding zone exists and functions correctly in debug-launched sessions, identical to normal gameplay. The player can board the ship from any side of the hull.

## Acceptance Criteria

- [ ] "Enter Ship" prompt appears when the player is near the ship hull in a debug-launched session
- [ ] Pressing E successfully boards the ship from a debug launch
- [ ] Boarding zone collision shape is visible centered on the ship hull in debug collision view
- [ ] Fix applies for all three biomes (Shattered Flats, Rock Warrens, Debris Field)
- [ ] Normal TestWorld boarding flow is unaffected
- [ ] Full test suite passes with no new failures

## Implementation Notes

**Root cause:** `debug_launcher.gd:_build_debug_world()` constructs a bare `Node3D` scene with a biome, a player, and `ship_exterior.tscn`. It never calls `_setup_ship_interior()` or creates a `ShipEnterZone`. `TestWorld._setup_ship_interior()` is the only place this zone is created.

**Recommended fix:** After the world enters the scene tree and the ship is positioned (i.e., after line 221 `ship.position = ship_pos` in `_launch()`), create and attach a `ShipEnterZone` to the world in `_setup_gameplay()` or in `_launch()` directly. The zone setup can be extracted from `TestWorld._setup_ship_interior()` into a shared static helper, or simply duplicated inline in the debug launcher with the ship's known position applied immediately (no need for `_on_travel_sequence_completed` repositioning since the debug launcher does not support biome travel).

Minimal inline approach in `_launch()` after ship is positioned:
```gdscript
# Attach a full-hull boarding zone to the ship (mirrors TestWorld._setup_ship_interior logic)
var enter_zone := ShipEnterZone.new()
enter_zone.collision_layer = 0
enter_zone.collision_mask = PhysicsLayers.PLAYER
var col := CollisionShape3D.new()
var shape := BoxShape3D.new()
shape.size = Vector3(28.0, 14.0, 50.0)
col.shape = shape
col.position = Vector3(0.0, 4.5, 0.0)   # local offset — zone is a child of ship
enter_zone.add_child(col)
ship.add_child(enter_zone)               # child of ship so it follows automatically
enter_zone.body_entered.connect(...)     # connect to begin_enter_ship handler
```

Making the zone a child of the ship node avoids any repositioning concern entirely.

## Activity Log

- 2026-02-27 [producer] Created — Studio Head confirmed boarding broken in debug launcher after TICKET-0207 fix; root cause confirmed: debug launcher never creates ShipEnterZone
