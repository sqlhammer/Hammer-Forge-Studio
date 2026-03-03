---
id: TICKET-0280
title: "M10 Feel — Ship boarding requires aiming at ship exterior mesh (D-034)"
type: TASK
status: OPEN
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

- [ ] A raycast is performed from the player camera when `interact` is pressed near the ship
- [ ] The raycast target must be the ship exterior mesh's collision shape — not a trigger volume
- [ ] If the raycast does not hit the ship, the boarding transition does not fire
- [ ] Boarding still works correctly when the player is facing the ship at any reasonable angle
- [ ] No regression: all other interact targets (machines, deposits, items) are unaffected

---

## Implementation Notes

The ship exterior mesh already has a collision shape in the scene. The raycast should use
the same camera-forward ray used by the existing interaction prompt system (`deposit.gd`
and related), with the ship's collision layer as the target filter.

Ensure the raycast max distance is generous enough that the player doesn't need to press
against the hull to board — the current trigger zone range is the right reference point.

---

## Handoff Notes

(Leave blank until handoff occurs.)

---

## Activity Log

- 2026-03-03 [producer] Created ticket — M10 feel: ship boarding raycast (D-034)
