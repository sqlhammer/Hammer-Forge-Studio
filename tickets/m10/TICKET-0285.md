---
id: TICKET-0285
title: "M10 QA — Phase gate sign-off"
type: TASK
status: DONE
priority: P1
owner: qa-engineer
created_by: producer
created_at: 2026-03-03
updated_at: 2026-03-03
milestone: "M10"
phase: "QA"
depends_on: [TICKET-0276, TICKET-0277, TICKET-0278, TICKET-0279, TICKET-0280, TICKET-0281, TICKET-0282, TICKET-0283, TICKET-0284, TICKET-0286]
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
- [x] Full test suite executed — 107 tests passed across 5 suites; P3 finding (pre-existing headless OOM in terrain test) documented and deferred
- [x] UAT sign-off document produced and saved to
      `docs/studio/reports/2026-03-03-m10-uat-signoff.md`
- [x] UAT document covers all 13 M10 UAT items with step-by-step test instructions
- [x] Phase Gate Summary report posted to `docs/studio/reports/2026-03-03-m10-qa-gate.md`
- [x] This ticket marked DONE — Studio Head then reviews UAT doc and grants final sign-off

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

---

## Handoff Notes

- UAT sign-off document: `docs/studio/reports/2026-03-03-m10-uat-signoff.md` — 13 features, all pending Studio Head review
- Phase Gate Summary: `docs/studio/reports/2026-03-03-m10-qa-gate.md`
- Test run: 107/107 passed (5 suites: automation_hub, battery_bar, collision_coverage, compass_bar, cryonite); test_debris_field_biome_unit OOM crash documented as P3 finding (pre-existing headless limitation, not a M10 regression)
- All 10 M10 implementation tickets DONE; 6 deferred items resolved (D-001, D-007, D-015, D-033, D-034, D-035)
- Studio Head must review and approve UAT doc before milestone can close; Producer then runs milestone-close checklist

---

## Activity Log

- 2026-03-03 [producer] Created ticket — M10 QA phase gate sign-off
- 2026-03-03 [producer] Added TICKET-0286 to depends_on and UAT coverage (D-007 respawn)
- 2026-03-03 [qa-engineer] Starting work — all M10 dependencies confirmed DONE; running test suite and producing UAT sign-off document
