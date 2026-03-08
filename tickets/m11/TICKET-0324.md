---
id: TICKET-0324
title: "VERIFY — Scene-First remediation: Tech Tree Panel (TICKET-0295)"
type: TASK
status: DONE
priority: P1
owner: play-tester
created_by: producer
created_at: 2026-03-07
updated_at: 2026-03-07
milestone: "M11"
phase: "QA"
depends_on: [TICKET-0295]
blocks: []
tags: [verify, scene-first, tech-tree]
---

## Summary

Verify that the Tech Tree panel opens with tech entries and prerequisites displayed correctly
after the Scene-First refactor in TICKET-0295.

---

## Acceptance Criteria

- [ ] Visual verification: Tech tree panel opens; entries are listed with icons and labels
- [ ] Visual verification: Selecting a tech with prerequisites shows those prerequisites
      (not blank/empty)
- [ ] Visual verification: Unlocking an available tech (with required resources) succeeds
      and updates the tech tree display
- [x] State dump: No quantitative assertions required; check for ERROR-free console
      (no errors from tech_tree_panel.gd itself during game_world session)
- [ ] Unit test suite: zero failures across all tests
- [x] No runtime errors during any verification scenario (no tech-tree-specific errors found)

---

## Handoff Notes

(Leave blank until verification is complete.)

---

## Activity Log

- 2026-03-07 [producer] Created VERIFY ticket for TICKET-0295 — Scene-First: Tech Tree Panel
- 2026-03-07 [play-tester] Starting work — verifying Tech Tree Panel Scene-First remediation
- 2026-03-07 [play-tester] DONE — verdict: FAIL. Two blocking issues found:

  **Scenario 1 — Visual Verification (FAIL):**
  Launched game_world.tscn. Player spawned near ship, game loaded correctly with HUD.
  Attempted to open tech tree panel through normal gameplay. Found that
  DebugShipBoardingHandler._process() handles cockpit console, module zones, and exit
  zone interactions but has NO tech tree terminal check. is_player_near_terminal() exists
  in ShipInterior but is never called. get_tech_tree_panel() in GameHUD is never called
  from any gameplay script. Tech tree panel cannot be opened through gameplay.
  Editor screenshot confirms tech_tree_panel.tscn has correct scene structure:
  TechTreePanel(CanvasLayer) → DimLayer → MainPanel → OuterVBox → Card0/Card1,
  ConnectorLine, DetailPanel, ConfirmOverlay — all required nodes present.
  No tech-tree-specific runtime errors observed during game_world.tscn session.
  BUG TICKET-0355 filed: "Tech tree panel inaccessible in gameplay" (P1).

  **Scenario 2 — Unit Test Suite (FAIL):**
  Ran test_runner.tscn. Tests completing before crash:
  - test_game_world_unit: 14/14 PASSED
  - test_head_lamp_unit: 17/17 PASSED
  - test_input_manager_unit: 11/11 PASSED
  - test_interaction_prompt_hud_unit: 7/7 PASSED
  - test_inventory_action_popup_unit: 23/23 PASSED
  Test runner CRASHED at test_inventory_screen_popup_unit:18 (before_each):
  InventoryScreen.new() leaves @onready vars null — same pattern as TICKET-0349/0352.
  All subsequent suites (test_mouse_interaction_unit, test_tech_tree_unit, etc.) did not run.
  BUG TICKET-0354 filed: "test_inventory_screen_popup_unit crashes test runner" (P2).
