---
id: TICKET-0049
title: "QA testing — M4 full loop"
type: TASK
status: OPEN
priority: P1
owner: qa-engineer
created_by: producer
created_at: 2026-02-23
updated_at: 2026-02-23
milestone: "M4"
depends_on: [TICKET-0048]
blocks: []
tags: [qa, testing, milestone-gate]
---

## Summary
Full QA pass on the M4 ship infrastructure loop. Test the complete player experience: enter the ship, review ship global variables, install the Recycler, queue a Scrap Metal → Metal job, collect Metal output, and verify ship stats are visible in the inventory screen. This is the milestone gate — M4 cannot close without QA sign-off.

## Acceptance Criteria
- [ ] All unit tests pass across M1–M4 systems
- [ ] Ship entry/exit test: player can enter and exit the ship interior without errors
- [ ] Ship globals test: Power, Integrity, Heat, Oxygen display correctly in the HUD when inside the ship; hidden when outside
- [ ] Ship stats sidebar test: all four global variables visible on the inventory screen when outside the ship
- [ ] Module install test: player can interact with placement zone, see Recycler in catalog with cost, install it with sufficient Scrap Metal, and be blocked with feedback when resources are insufficient
- [ ] Recycler panel test: panel opens on interact, player can queue Scrap Metal → Metal job, progress updates, Metal appears in output slot on completion, collect adds Metal to inventory
- [ ] Persistence test: installed Recycler persists after leaving and re-entering the ship
- [ ] Power constraint test: Recycler power draw does not exceed baseline; overload is blocked with clear feedback
- [ ] Edge cases: interact with empty placement zone, attempt install with zero Scrap Metal, collect output with full inventory, close Recycler panel mid-job
- [ ] No crashes, no errors in Godot output log during full loop playthrough
- [ ] Performance: stable framerate with all M4 systems active
- [ ] Write new unit tests for any gaps discovered during testing
- [ ] Test results documented at `docs/qa/test-results-M4.md`
- [ ] QA sign-off or list of blocking issues

## Implementation Notes
- Test in the greybox world extended with the ship interior (TICKET-0043)
- Run the full test suite from `game/addons/hammer_forge_tests/` before manual testing
- Reference `docs/design/systems/mobile-base.md` for expected ship variable behavior
- If blocking issues are found: create BUG tickets, assign to the appropriate programmer, do not sign off
- QA sign-off is required before M4 can be marked Complete in `docs/studio/milestones.md`

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-23 [producer] Created ticket
