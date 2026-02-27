---
id: TICKET-0207
title: "Bugfix — Ship boarding zone spawns at world origin; never positioned at ship on initial load"
type: BUGFIX
status: DONE
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
closed_at: 2026-02-27
milestone: "M8"
phase: "QA"
depends_on: []
blocks: []
tags: [bugfix, ship, boarding, enter-zone, spawn, origin, m8-qa]
---

## Summary

The `ShipEnterZone` Area3D is created at world origin `(0, 4.5, 0)` in `_setup_ship_interior()` and is only repositioned inside `_on_travel_sequence_completed()` — a callback that only fires after a biome travel sequence. On initial spawn, the zone never moves to the ship's actual position. The player is standing next to the ship but the boarding trigger is sitting at world origin, far away. No "Enter Ship" prompt appears and pressing E does nothing. The zone is also invisible in debug collision view because it is nowhere near the ship.

This is an incomplete fix from TICKET-0206, which correctly sized the zone but did not address initial placement.

## Steps to Reproduce

1. Launch any biome via the debug launcher (initial spawn — no travel performed)
2. Walk up to the ship and stand against the hull
3. Observe: no "Enter Ship" prompt appears and E does nothing
4. Enable debug collision shapes in the Godot editor — observe no boarding zone collision shape near the ship

## Expected Behavior

The boarding zone is correctly centered on the ship from the moment the world loads. The "Enter Ship" prompt appears as soon as the player is within the zone's bounds (any side of the ship hull).

## Acceptance Criteria

- [x] "Enter Ship" prompt appears when the player approaches the ship on initial biome load (no travel required)
- [x] Pressing E successfully enters the ship from any side on initial load
- [x] The boarding zone collision shape is visible centered on the ship hull in debug collision view
- [x] Boarding continues to work correctly after biome travel (existing `_on_travel_sequence_completed` behavior retained)
- [x] Fix applies in all biomes and in TestWorld default launch
- [x] Full test suite passes with no new failures

## Implementation Notes

**Root cause (confirmed by code reading):**

In `test_world.gd:_setup_ship_interior()` (line ~350):
```gdscript
enter_col.position = Vector3(0.0, 4.5, 0.0)   # ← placed at world origin, not at ship
_ship_enter_zone.add_child(enter_col)
add_child(_ship_enter_zone)                     # ← zone also at world origin
```

`_on_travel_sequence_completed()` (line ~585) does reposition the zone, but only fires after a travel sequence — never on initial load.

**Recommended fix — two options:**

Option A (simplest): At the end of `_setup_ship_interior()`, after `_ship_exterior` is available, immediately call the same positioning logic used in `_on_travel_sequence_completed`:
```gdscript
# At the end of _setup_ship_interior(), after add_child(_ship_enter_zone):
if _ship_exterior:
    var ship_pos: Vector3 = _ship_exterior.position
    enter_col.position = Vector3(ship_pos.x, ship_pos.y + 4.5, ship_pos.z)
```

Option B (cleaner, avoids future drift): Make `_ship_enter_zone` a child of `_ship_exterior` instead of `TestWorld`. Then set `enter_col.position = Vector3(0.0, 4.5, 0.0)` (local offset from ship center) and the zone will follow the ship automatically on travel without needing `_on_travel_sequence_completed` to reposition it. Remove the repositioning block from `_on_travel_sequence_completed`.

Option B eliminates the entire class of "zone drifts away from ship" bugs and is preferred.

## Activity Log

- 2026-02-27 [producer] Created — Studio Head confirmed no boarding prompt or E-key response when standing against ship hull; debug collision view shows no zone near ship; root cause identified in code review of test_world.gd
- 2026-02-27 [gameplay-programmer] Starting work — implementing Option B: reparent ShipEnterZone to _ship_exterior so zone follows ship automatically; remove manual repositioning from _on_travel_sequence_completed
- 2026-02-27 [gameplay-programmer] DONE — Fix implemented in commit 0216069 (PR #176). ShipEnterZone reparented to _ship_exterior as child node so zone always follows ship position automatically on initial load and after travel. Redundant repositioning block removed from _on_travel_sequence_completed. Null-guard added for _ship_exterior in _setup_ship_interior. No new .gd files created; no UID commit required. All acceptance criteria met.
