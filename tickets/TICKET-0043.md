---
id: TICKET-0043
title: "Greybox ship interior scene"
type: TASK
status: OPEN
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-23
updated_at: 2026-02-23
milestone: "M4"
milestone_gate: "M3"
depends_on: [TICKET-0042]
blocks: [TICKET-0044]
tags: [ship, interior, scene, greybox]
---

## Summary
Build a minimal greybox ship interior scene. The player can enter the ship from the exterior, walk around inside, and interact with module placement zones. No art polish — greybox collision geometry only. This scene will be replaced in M6 (Ship Interior buildout).

## Acceptance Criteria
- [ ] Ship interior scene created at `game/scenes/gameplay/ship_interior.tscn` (or equivalent)
- [ ] Player can enter from the ship exterior via an interact or trigger zone
- [ ] Player can exit back to the exterior
- [ ] Walkable interior floor with correct collision
- [ ] At least one module placement zone — interactable area where the player installs modules
- [ ] Player spawns/positions correctly on enter and exit
- [ ] Scene is independently runnable and testable in isolation
- [ ] No art assets required — greybox geometry only
- [ ] No Godot editor errors or warnings

## Implementation Notes
- Reference the interior layout wireframe from TICKET-0042
- Entry/exit: a doorway trigger or interact prompt on the ship exterior — keep it simple
- Module placement zone: a visible marker or highlighted floor area — does not need to be polished
- Interior dimensions should match the ship exterior scale established in M2 assets
- The M6 milestone (Ship Interior) will replace this with a fully designed cockpit and machine room

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-23 [producer] Created ticket
