---
id: TICKET-0228
title: "Bugfix — Ship compass marker never appears: set_ship_target not called in debug_launcher"
type: BUGFIX
status: IN_PROGRESS
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-28
updated_at: 2026-02-28
milestone: "M8"
phase: "QA"
depends_on: []
blocks: []
tags: [bugfix, compass, hud, ship-marker, debug-launcher, m8-qa]
---

## Summary

The ship compass marker (amber triangle) never appears during debug-launched biome sessions. Investigation confirms that `hud.set_ship_target(ship)` is never called in `debug_launcher.gd`, so `CompassBar._ship_target` remains `null` and `_draw_ship_marker()` exits immediately every frame.

## Reproduction Log

```
[3563] CompassBar: player or ship_target not found
[3567] CompassBar: player or ship_target not found
[3576] CompassBar: player or ship_target not found
```

`CompassBar: ship target set` is never logged, confirming `set_ship_target` is never reached.

## Root Cause

`debug_launcher.gd:_setup_gameplay()` calls `hud.setup(camera, first_person, scanner, mining)` but omits the follow-up call to `hud.set_ship_target(ship)`.

The analogous path in `test_world.gd` does this correctly:

```gdscript
# test_world.gd:281
_hud.set_ship_target(_ship_exterior)
```

`debug_launcher.gd` already retrieves the ship node at line 219 (`world.get_node_or_null("Ship")`), so the reference is available — it simply isn't passed to the HUD.

## Fix

The fix belongs inside `CompassBar` (or `GameHUD`), not in the calling scenes. Do not patch `debug_launcher.gd` or `test_world.gd`.

**Approach:**

1. In `CompassBar._ready()` (or `GameHUD._ready()`), scan the scene tree for a node in group `"ship"` (or by class/name) and call `set_ship_target()` if found.
2. Add a signal (e.g., `ship_spawned(ship: Node3D)`) on the ship scene or a relevant autoload. `CompassBar` connects to it and updates `_ship_target` whenever a new ship enters the world.
3. Add a `ship_position_changed` signal on the ship for future use — the HUD can connect to it to update the marker position reactively rather than polling every frame.

External callers (`debug_launcher.gd`, `test_world.gd`) should require no changes. The `set_ship_target` public method may be removed once the self-wiring is in place.

## Acceptance Criteria

- [x] Launching any biome via the debug launcher shows the amber ship marker on the compass from the first frame
- [x] `CompassBar: ship target set` is logged during debug session startup
- [x] The edge-clamped arrow behaviour (TICKET-0214) continues to work correctly
- [x] No regression in `test_world.gd` ship marker behaviour
- [ ] Full test suite passes with no new failures

## Design Note

`test_world.gd` and `debug_launcher.gd` should not be responsible for wiring the ship target into the HUD — that is a setup concern that belongs inside the HUD itself. The correct architecture is:

1. **On `_ready`** — `CompassBar` (or `GameHUD`) searches the scene tree for an existing ship node and sets `_ship_target` if found.
2. **Signal listener** — The HUD listens for a "ship entered world" signal (e.g., on the ship itself or a global autoload) so it self-registers when a ship spawns at any point during a session.
3. **Ship movement signals** — A signal on the ship (e.g., `ship_position_changed`) allows the HUD to react to ship movement in the future without polling.

This approach eliminates the need for any external caller to call `set_ship_target`, prevents race conditions, removes the need for deferred timers, and keeps a clean separation of concerns between the HUD and the scenes that instantiate it.

The `set_ship_target` public method can be removed or kept as a fallback, but it should not be the primary wiring mechanism.

## Activity Log

- 2026-02-28 [producer] Created — Studio Head confirmed `set_ship_target` never called via debug log inspection
- 2026-02-28 [studio-head] Added design note — HUD should self-wire to ship via _ready scan + signal listener; external callers should not own this setup
- 2026-02-28 [gameplay-programmer] Starting work — implementing self-wiring in CompassBar
