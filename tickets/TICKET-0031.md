---
id: TICKET-0031
title: "QA testing — M3 full loop"
type: TASK
status: OPEN
priority: P1
owner: qa-engineer
created_by: producer
created_at: 2026-02-22
updated_at: 2026-02-23
milestone: "M3"
depends_on: [TICKET-0030]
blocks: []
tags: [qa, testing, milestone-gate]
---

## Summary
Full QA pass on the M3 scan/mine loop. Test the complete player experience: spawn at ship, scan for deposits, navigate via compass, analyze a deposit, mine it, collect resources, manage battery, check inventory, and repeat until deposits are depleted. This is the milestone gate — M3 cannot close without QA sign-off.

## Acceptance Criteria
- [ ] All unit tests pass (inventory, deposits, battery systems)
- [ ] Scanner Phase 1 test: ping detects deposits, compass markers appear at correct bearings, distance readout shows when facing marker
- [ ] Scanner Phase 2 test: analyze hold works, readout displays purity/density/energy cost, already-analyzed deposits show readout immediately
- [ ] Mining test: hold-to-extract works, battery drains, resources added to inventory, deposit depletes after 3–5 extractions
- [ ] Battery test: drains during mining, recharges at ship, 0% prevents mining, 0% allows scanning, 25% movement penalty at 0%
- [ ] Inventory test: resources stack correctly (max 100), full inventory prevents mining with notification, inventory UI displays correctly
- [ ] Compass test: markers at correct positions, distance shown/hidden based on facing direction, markers removed on deposit depletion
- [ ] HUD test: battery bar reflects state, pickup notifications appear and fade, no overlapping UI elements
- [ ] Edge cases: mine with full inventory, mine with no battery, scan with no deposits in range, analyze an already-analyzed deposit, interact with a depleted deposit
- [ ] No crashes, no errors in Godot output log during full loop playthrough
- [ ] Performance: stable framerate in the greybox world with all systems active
- [ ] Write new unit tests for any gaps discovered during testing
- [ ] Test results documented at `docs/qa/test-results-M3.md`
- [ ] QA sign-off or list of blocking issues

## Implementation Notes
- Test in the greybox world (TICKET-0029)
- Run the full test suite from `game/addons/hammer_forge_tests/` before manual testing
- Reference `docs/design/systems/meaningful-mining.md` for expected behavior
- Reference `docs/design/systems/player-suit.md` for battery behavior
- If blocking issues are found: create BUG tickets, assign to the appropriate programmer, do not sign off
- QA sign-off is required before M3 can be marked Complete in `docs/studio/milestones.md`

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-22 [producer] Created ticket
- 2026-02-23 [producer] Unit tests for Phase 1 data layer systems landed in PR #9 (118 test cases across 5 suites). Full QA pass (manual scan/mine loop, edge cases, framerate, sign-off) still pending on TICKET-0030 code review completion.
