---
id: TICKET-0142
title: "Bugfix — cockpit status displays floating in center of room instead of wall-mounted"
type: BUGFIX
status: IN_PROGRESS
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-26
updated_at: 2026-02-26
milestone: "M7"
phase: "QA"
depends_on: []
blocks: [TICKET-0130]
tags: [cockpit, ship-interior, status-displays, bugfix, p1]
---

## Summary

The diegetic ship status displays (Power, Integrity, Heat, O2) are floating unsupported in the middle of the cockpit floor rather than being mounted flush against the wall. The panel is free-standing and visually disconnected from the ship geometry.

## Steps to Reproduce

1. Launch the game
2. Enter the ship
3. Walk forward into the cockpit area

## Expected Behavior

The status display panel is positioned flat against the cockpit wall, appearing as a wall-mounted screen or panel integrated into the ship's interior geometry.

## Actual Behavior

The status display panel is positioned in the center of the cockpit room, floating above the floor with no wall contact. It appears as a free-standing object in empty space.

## Acceptance Criteria

- [x] Status display panel is flush against the cockpit wall (back wall or appropriate side wall)
- [x] Panel faces the player naturally when standing in the cockpit
- [x] Panel does not clip into the wall geometry — correctly surface-aligned

## Implementation Notes

- The node's `Transform3D` position in the scene is incorrect — adjust `position` and `rotation` to place it against the intended cockpit wall
- Identify the target wall in `ship_interior.tscn` and snap the display panel to it
- Rotation should face inward so the screen surface is visible to the player

## Activity Log

- 2026-02-26 [producer] Created — placement defect found during M7 QA review
- 2026-02-26 [gameplay-programmer] IN_PROGRESS — Starting work. Displays at Z=-9 need to move to Z=-11.85 (back wall behind CockpitConsole).
