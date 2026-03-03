---
id: TICKET-0285
title: "M10 QA — Phase gate sign-off"
type: TASK
status: IN_PROGRESS
priority: P1
owner: qa-engineer
created_by: producer
created_at: 2026-03-03
updated_at: 2026-03-03
milestone: "M10"
phase: "QA"
depends_on: [TICKET-0276, TICKET-0277, TICKET-0278, TICKET-0279, TICKET-0280, TICKET-0281, TICKET-0282, TICKET-0283, TICKET-0284, TICKET-0286, TICKET-0287, TICKET-0288]
blocks: []
tags: [qa, sign-off, phase-gate]
---

## Summary

QA phase gate for M10 — Input & Feel Refinement. All implementation tickets must be DONE
before this ticket is dispatched. QA Engineer runs the full test suite, produces the UAT
sign-off document, and marks this ticket DONE to unblock M11 kickoff.

---

## Acceptance Criteria

- [x] All M10 implementation tickets (TICKET-0276 through TICKET-0284, TICKET-0286) are DONE
- [ ] TICKET-0287 (radial wheel centering bug) is DONE — **BLOCKING**
- [ ] TICKET-0288 (compass distance cone) is DONE — **BLOCKING**
- [x] Full test suite executed — 107 tests passed across 5 suites; P3 finding (pre-existing headless OOM in terrain test) documented and deferred
- [x] UAT sign-off document produced and saved to
      `docs/studio/reports/2026-03-03-m10-uat-signoff.md` (covers items 1–13; items 14–15 to be added after TICKET-0287/0288 complete)
- [ ] UAT document updated to cover all 15 M10 UAT items with step-by-step test instructions
- [x] Phase Gate Summary report posted to `docs/studio/reports/2026-03-03-m10-qa-gate.md`
- [ ] This ticket marked DONE — Studio Head then reviews UAT doc and grants final sign-off

---

## UAT Coverage Required

The UAT sign-off document must include testable steps for:

1. **Gamepad interact (X button)** — press X to board ship, interact with machines, pick up items
2. **Gamepad jump (A button)** — press A to jump in first-person
3. **Gamepad ping (LB)** — press LB to fire scanner ping
4. **Gamepad use_item (A button)** — press A to use item in inventory context
5. **Gamepad toggle_head_lamp (RB)** — press RB to toggle headlamp
6. **Gamepad use_tool (RT hold)** — hold RT to mine a deposit
7. **HUD button labels** — confirm HUD shows correct gamepad glyphs (X, A, LB, RB, RT) after device switch
8. **Ship boarding raycast** — confirm boarding only triggers when aiming at ship hull
9. **Scanner radial wheel** — hold Q/LB, select resource type, release to ping
10. **Animated ping ring** — confirm ring expands and compass markers appear progressively
11. **Orchestrator --max-turns** — confirm `budget_usd` is gone and `--max-turns` is dispatched correctly
12. **D-007 follow-up** — confirm producer ticket outcome is recorded
13. **Resource node respawn** — mine a deposit to depletion, confirm it disappears; wait
    (or reduce config timer) and confirm it respawns; confirm deep nodes are unaffected;
    confirm compass ping does not show depleted nodes
14. **Ping radial wheel centering** — confirm wheel renders at screen center, not upper-left
15. **Compass distance cone** — confirm resource distance label only appears when the marker
    is within 3× the ping icon width of compass center; confirm ship distance label is unchanged

---

## Handoff Notes

- UAT sign-off document (partial): `docs/studio/reports/2026-03-03-m10-uat-signoff.md` — covers 13/15 UAT items; items 14 (TICKET-0287) and 15 (TICKET-0288) must be added after those tickets complete
- Phase Gate Summary (draft): `docs/studio/reports/2026-03-03-m10-qa-gate.md` — status BLOCKED pending TICKET-0287 and TICKET-0288
- Test run: 107 tests passed across 5 suites; P3 finding (headless OOM, pre-existing) documented
- All original M10 implementation tickets (0276–0284, 0286) DONE; gate blocked by TICKET-0287 (P1 BUG) and TICKET-0288 (P2 TASK)

---

## Activity Log

- 2026-03-03 [producer] Created ticket — M10 QA phase gate sign-off
- 2026-03-03 [producer] Added TICKET-0286 to depends_on and UAT coverage (D-007 respawn)
- 2026-03-03 [producer] Added TICKET-0287 to depends_on and UAT coverage (radial wheel centering bug)
- 2026-03-03 [producer] Added TICKET-0288 to depends_on and UAT coverage (compass distance cone)
- 2026-03-03 [qa-engineer] Starting work — original M10 dependencies (0276–0284, 0286) confirmed DONE; running test suite and producing UAT sign-off document
- 2026-03-03 [qa-engineer] BLOCKED — discovered remote has TICKET-0287 (P1 BUG, OPEN) and TICKET-0288 (P2 TASK, OPEN) blocking this ticket; produced partial UAT doc (13/15 items) and draft Phase Gate Summary; cannot mark DONE until TICKET-0287 and TICKET-0288 are DONE; returning to IN_PROGRESS
