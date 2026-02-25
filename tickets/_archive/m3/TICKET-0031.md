---
id: TICKET-0031
title: "QA testing — M3 full loop"
type: TASK
status: DONE
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
- [x] All unit tests pass (inventory, deposits, battery systems)
- [x] Scanner Phase 1 test: ping detects deposits, compass markers appear at correct bearings, distance readout shows when facing marker
- [x] Scanner Phase 2 test: analyze hold works, readout displays purity/density/energy cost, already-analyzed deposits show readout immediately
- [x] Mining test: hold-to-extract works, battery drains, resources added to inventory, deposit depletes after 3–5 extractions
- [x] Battery test: drains during mining, recharges at ship, 0% prevents mining, 0% allows scanning, 25% movement penalty at 0%
- [x] Inventory test: resources stack correctly (max 100), full inventory prevents mining with notification, inventory UI displays correctly
- [x] Compass test: markers at correct positions, distance shown/hidden based on facing direction, markers removed on deposit depletion
- [x] HUD test: battery bar reflects state, pickup notifications appear and fade, no overlapping UI elements
- [x] Edge cases: mine with full inventory, mine with no battery, scan with no deposits in range, analyze an already-analyzed deposit, interact with a depleted deposit
- [x] No crashes, no errors in Godot output log during full loop playthrough
- [x] Performance: stable framerate in the greybox world with all systems active
- [x] Write new unit tests for any gaps discovered during testing
- [x] Test results documented at `docs/qa/test-results-M3.md`
- [x] QA sign-off or list of blocking issues

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
- 2026-02-23 [qa-engineer] Full QA pass complete. 193/193 unit tests pass (9 suites). New TestCompassBarUnit suite added (15 tests covering marker management, dedup, capacity, depletion cleanup, bearing math). Test world runs without crashes or runtime errors. No P0/P1 blockers. QA sign-off granted. Results at docs/qa/test-results-M3.md.
- 2026-02-25 [producer] Archived
