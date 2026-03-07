---
id: TICKET-0320
title: "VERIFY — Scene-First remediation: Ship Machine Panels (TICKET-0291)"
type: TASK
status: DONE
priority: P1
owner: play-tester
created_by: producer
created_at: 2026-03-07
updated_at: 2026-03-07T16:00:00
milestone: "M11"
phase: "QA"
depends_on: [TICKET-0291]
blocks: []
tags: [verify, scene-first, recycler, fabricator, automation-hub]
---

## Summary

Verify that the Recycler panel, Fabricator panel, and Automation Hub panel all open and
function correctly after the Scene-First refactor in TICKET-0291.

---

## Acceptance Criteria

- [x] Visual verification: Recycler panel opens when interacting with the Recycler in the ship
      interior — grid and controls are visible and correctly laid out (screenshot verified 2026-03-07)
- [x] Visual verification: Fabricator panel opens with a populated recipe list; input
      requirements display correctly (not blank) — 3 recipes shown with costs (screenshot verified 2026-03-07)
- [x] Visual verification: Automation Hub panel opens without errors (screenshot verified 2026-03-07)
- [x] State dump: No ERROR lines in console during panel open/close for any of the three panels (verified 2026-03-07)
- [x] Unit test suite: zero failures across all tests — 1009/1009 passed (headless run 2026-03-07)
- [x] No runtime errors during any verification scenario (verified 2026-03-07)

---

## Handoff Notes

All three panels verified via Godot MCP runtime testing:

- **Recycler Panel**: Opens with correct layout — title, status ("Ready"), input/output slots with icons, recipe label ("3 Scrap Metal → 1 Metal (5s)"), progress bar, Start/Collect buttons, feedback area, close button. No runtime errors.
- **Fabricator Panel**: Opens with populated recipe list (3 recipes: Spare Battery, Head Lamp, Fuel Cell) across categories (COMPONENTS, EQUIPMENT, OTHER). Auto-selects first recipe with detail view showing input (Metal x10), output (Spare Battery x1), "Have: 0 Metal" label. Cost labels visible on all rows. No runtime errors.
- **Automation Hub Panel**: Opens with two-column layout — left: Drone Program config (Deposit Type, Min Purity, Tool Tier, Extraction Radius slider, Priority), right: Active Drones status (0/2). Pool stats displayed. ACTIVATE DRONES and Close buttons visible. No runtime errors.

Console log confirmed zero ERROR lines across all three panel open scenarios. Only pre-existing warnings (Vulkan driver fallback, enum cast hints) appeared — none related to the panels.

---

## Activity Log

- 2026-03-07 [producer] Created VERIFY ticket for TICKET-0291 — Scene-First: Ship Machine Panels
- 2026-03-07 [play-tester] Starting work — static structural analysis of refactored panels + headless unit test run. Godot MCP not available in this session; visual/interactive verification requires Godot MCP tools.

### Static Structural Analysis (PASS)

**recycler_panel.gd / recycler_panel.tscn**
- 18 `@onready` vars present; `_build_ui()` removed; `_ready()` calls only `_apply_styles()`, `_connect_signals()`, and sets recipe label text — no LAYOUT_IN_READY violations
- `.tscn` root is `CanvasLayer` with `layer = 3`, `visible = false` set in scene file (not in `_ready()`) — correct scene-first pattern
- Node tree includes `DimRect`, `DimLayer`, `Center`, and all expected UI nodes with `unique_name_in_owner = true` for `@onready` resolution

**fabricator_panel.gd / fabricator_panel.tscn**
- 24 `@onready` vars present; `_build_ui()` removed; `_ready()` calls `_recipe_ids = FabricatorDefs.get_all_recipe_ids()`, `_apply_styles()`, `_populate_recipe_list()`, `_connect_signals()`
- Dynamic row arrays (`_recipe_rows`, `_recipe_row_labels`, etc.) are properly typed as `Array[PanelContainer]`, `Array[Label]` — the three untyped Array vars from the audit are fixed
- `_build_recipe_row()` retained as expected (dynamic per-recipe rows)

**automation_hub_panel.gd / automation_hub_panel.tscn**
- 18 `@onready` vars present; `_build_ui()` removed; `_ready()` calls only `_apply_styles()`, `_connect_signals()` — minimal and clean
- `_build_drone_card()` retained as expected (dynamic per-drone cards)

All three scripts: `layer`, `visible`, `process_mode` properties moved to scene files — LAYOUT_IN_READY pattern eliminated.

### Unit Tests (PASS)

Headless run via `Godot_v4.5.1-stable_win64.exe --headless`:
- **Results: 1009 passed, 0 failed, 0 skipped — ALL PASSED**
- Exit-time resource leak warnings (RID leaks, gdaimcp capture not registered) are headless-mode artifacts, not game logic errors

### Remaining Verification (BLOCKED — see TICKET-0347)

Visual panel open/close verification and state dump (runtime ERROR check) require Godot MCP tools (`play_scene`, `simulate_input`, `get_running_scene_screenshot`, `get_godot_errors`) which are not available in this session. Re-dispatch through orchestrator with Tier 3 MCP configured.

- 2026-03-07 [play-tester] BLOCKED — see TICKET-0347
- 2026-03-07 [play-tester] UNBLOCKED — Godot MCP tools available. Ran visual verification for all three panels via runtime test scenes. All panels open correctly with expected layouts. Zero ERROR lines in console. All acceptance criteria satisfied. Marking DONE.
