---
id: TICKET-0007
title: "QA test player controller and mechanics"
type: TASK
status: OPEN
priority: P1
owner: qa-engineer
created_by: producer
created_at: 2026-02-21
updated_at: 2026-02-21
milestone: "M1"
depends_on: [TICKET-0006]
blocks: []
tags: [qa-testing, player-mechanics]
---

## Summary
QA Engineer tests the player controller, input system, and view-switching mechanics. Verify that both first-person and third-person modes work as designed, input is responsive, and the scene is ready for gameplay development.

## Acceptance Criteria
- [ ] First-person movement (WASD) responsive and smooth
- [ ] First-person camera control (mouse/gamepad) working in all directions
- [ ] Third-person orbit camera working in both axes
- [ ] View-switching (Tab/Menu) transitions smoothly without errors
- [ ] Gamepad input recognized and functional (if gamepad available)
- [ ] No crashes or errors in debug log during extended play
- [ ] Physics working: gravity, collision, no clipping through ground
- [ ] Input is not duplicated or missed during mode switches
- [ ] Performance acceptable (no frame stutters in both views)
- [ ] Scene runs standalone and integrates into test level
- [ ] All test cases documented in `docs/qa/test-results-M1.md`

## Implementation Notes
- Test with both keyboard and gamepad if available
- Verify performance with 60 FPS target
- Check for edge cases: rapid input, mode switching during movement, etc.
- Document any bugs found as new BUG tickets
- QA sign-off required before M1 milestone can close

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-21 [producer] Created ticket; depends on TICKET-0006
