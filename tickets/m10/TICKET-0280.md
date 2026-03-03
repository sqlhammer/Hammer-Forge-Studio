---
id: TICKET-0280
title: "M10 Feel — Ship boarding requires aiming at ship exterior mesh (D-034)"
type: TASK
status: IN_PROGRESS
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-03-03
updated_at: 2026-03-03
milestone: "M10"
phase: "Implementation"
depends_on: []
blocks: [TICKET-0285]
tags: [interaction, feel, ship, raycast]
---

## Summary

The ship boarding interact trigger currently fires regardless of where the player is aiming —
it is possible to "enter" the ship while facing away from it or through opaque geometry. Add
a raycast check against the ship's exterior mesh collision shape so boarding only triggers
when the player is pointing at a physical surface of the ship.

---

## Acceptance Criteria

- [x] A raycast is performed from the player camera when `interact` is pressed near the ship
- [x] The raycast target must be the ship exterior mesh's collision shape — not a trigger volume
- [x] If the raycast does not hit the ship, the boarding transition does not fire
- [x] Boarding still works correctly when the player is facing the ship at any reasonable angle
- [x] No regression: all other interact targets (machines, deposits, items) are unaffected

---

## Implementation Notes

The ship exterior mesh already has a collision shape in the scene. The raycast should use
the same camera-forward ray used by the existing interaction prompt system (`deposit.gd`
and related), with the ship's collision layer as the target filter.

Ensure the raycast max distance is generous enough that the player doesn't need to press
against the hull to board — the current trigger zone range is the right reference point.

---

## Handoff Notes

**What was implemented:**
- Added `_is_aiming_at_ship()` raycast method to `DebugShipBoardingHandler` that casts from camera forward against `PhysicsLayers.ENVIRONMENT` and verifies the hit collider is a descendant of a node in the "ship" group
- Gated the boarding transition on `_is_aiming_at_ship()` — interact near the ship now requires pointing at the hull
- Extended `setup()` signature with optional `camera` and `ship_exterior` parameters (defaults to null for backward compat)
- Updated `GameWorld._setup_ship_boarding()` to pass camera and ship references to the handler
- Ray length is 30m (generous vs. the ~25m enter zone half-extent)

**Scripts modified:**
- `game/scripts/gameplay/debug_ship_boarding_handler.gd`
- `game/scripts/gameplay/game_world.gd`

**Known limitations:**
- If camera reference is null (graceful degradation), boarding falls back to proximity-only (no raycast gate)
- The raycast targets `PhysicsLayers.ENVIRONMENT` layer — any ENVIRONMENT geometry between the camera and the ship will block the check. This is correct behavior (can't board through walls).

---

## Activity Log

- 2026-03-03 [producer] Created ticket — M10 feel: ship boarding raycast (D-034)
- 2026-03-03 [gameplay-programmer] Starting work — adding camera-forward raycast to ship boarding handler
