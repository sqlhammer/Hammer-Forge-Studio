---
id: TICKET-0206
title: "Bugfix — Ship boarding zone should cover full collision hull, not a single entry point"
type: BUGFIX
status: DONE
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27T00:00:00
milestone: "M8"
phase: "QA"
depends_on: []
blocks: []
tags: [bugfix, ship, boarding, collision, enter-zone, m8-qa]
---

## Summary

The ship entry zone is a single small trigger area at one location on the ship hull. Players cannot find it without knowing exactly where it is. The boarding interaction should fire whenever the player is colliding with or in close proximity to any part of the ship's collision hull — the ship should be boardable from any side the player can physically touch.

## Steps to Reproduce

1. Launch any biome via the debug launcher
2. Walk toward the ship and make contact with the hull
3. Observe: no boarding prompt or interaction fires unless the player happens to find the specific entry trigger zone

## Expected Behavior

Any time the player is physically colliding with or within a small proximity threshold of the ship's collision body, the boarding interaction becomes available and the player can enter the ship. The ship is effectively its own entry zone.

## Acceptance Criteria

- [x] Player can initiate boarding from any point where they are in contact with or near the ship's collision hull (within a small clearance, e.g. 1–2m)
- [x] The old single-point `ShipEnterZone` trigger is replaced or extended to cover the full ship footprint
- [x] Boarding prompt appears correctly when the player is near the ship from any direction
- [x] No double-trigger or boarding loop when the player is already inside the ship
- [x] Fix applies in all biomes (Shattered Flats, Rock Warrens, Debris Field) and in TestWorld
- [x] Full test suite passes with no new failures

## Implementation Notes

- The current approach places a single `Area3D` / `CollisionShape3D` as a trigger at one specific location on the ship (fixed by TICKET-0203 for Y height, but the footprint issue remains)
- Preferred approach: replace the point trigger with an `Area3D` that wraps the full ship collision AABB — use a `BoxShape3D` or `SphereShape3D` slightly larger than the ship's bounding box so any approach triggers it
- Alternative: drive boarding availability from proximity distance to the ship node's global position (e.g., `player.global_position.distance_to(ship.global_position) < BOARD_DISTANCE`) rather than a trigger zone — simpler and direction-agnostic
- Either way, ensure the "already aboard" state prevents re-triggering the boarding flow when the player is inside the ship scene

## Activity Log

- 2026-02-27 [producer] Created — Studio Head reported during final M8 playtest review
- 2026-02-27 [gameplay-programmer] Starting work — replacing single-point ShipEnterZone with full-hull boarding zone
- 2026-02-27 [gameplay-programmer] DONE — commit 87d3c39, PR https://github.com/sqlhammer/Hammer-Forge-Studio/pull/175. Replaced 12×6×10m entrance-only trigger with 28×14×50m hull-wrapping BoxShape3D. Updated travel callback to reposition zone at hull center. No new scripts created.
