---
id: TICKET-0005
title: "Integrate player scene with all core mechanics"
type: TASK
status: OPEN
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-21
updated_at: 2026-02-21
milestone: "M1"
depends_on: [TICKET-0003, TICKET-0004]
blocks: [TICKET-0006]
tags: [integration, player-scene]
---

## Summary
Create a master player scene that integrates the first-person controller, third-person view system, and input manager. Implement mode-switching between first-person and third-person views. Scene must be testable and ready for gameplay iteration.

## Acceptance Criteria
- [ ] Master player scene created at `res://player/player.tscn` (root node: Node3D)
- [ ] First-person controller scene instanced and set as child
- [ ] Third-person view system scene instanced and set as child
- [ ] Input binding defined for toggling between views (e.g., Tab or Menu button)
- [ ] View-switching logic implemented and working smoothly
- [ ] Both views functional when switching
- [ ] Scene is independently testable from Godot editor
- [ ] All code follows `docs/engineering/coding-standards.md`
- [ ] Scene is ready to be integrated into a full game level

## Implementation Notes
- Create a controller script at `res://player/PlayerManager.gd` to handle view switching
- Use signals for view-change events
- Ensure smooth transitions between first-person and third-person
- Both controllers should be enabled/disabled on switch, not destroyed
- Consider adding a visual indicator of current mode
- Document the scene structure and architecture

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-21 [producer] Created ticket; depends on TICKET-0003, TICKET-0004
