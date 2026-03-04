# M11 Phase Gate QA Report — 2026-03-04

**Milestone:** M11 — GDScript Standards Compliance & Remediation
**Phase:** QA Phase Gate (TICKET-0304)
**QA Engineer:** qa-engineer
**Report Date:** 2026-03-04
**Gate Status:** ❌ BLOCKED — 3 test failures remain (see details below)

---

## Test Suite Results

**Run Date/Time:** 2026-03-04 15:30:46
**Test Runner:** `res://addons/hammer_forge_tests/test_runner.tscn` (headless)
**Report File:** `user://test_reports/test_report_2026-03-04 15-30-46.json`

| Metric        | Result |
|---------------|--------|
| Total Tests   | 1000   |
| Passed        | 997    |
| Failed        | **3**  |
| Skipped       | 0      |

### Failing Tests

All 3 failures are in `test_scene_properties_unit` — HUD anchor preset assertions:

| Test Name | Suite | Expected | Actual | Root Cause |
|-----------|-------|----------|--------|------------|
| `game_hud_compass_bar_anchors_preset` | test_scene_properties_unit | 5 (CENTER_TOP) | 0 (TOP_LEFT) | Base scene anchor_* props reset stored_layout_preset |
| `game_hud_mining_progress_anchors_preset` | test_scene_properties_unit | 8 (CENTER) | 0 (TOP_LEFT) | Base scene anchor_* props reset stored_layout_preset |
| `game_hud_mining_minigame_overlay_anchors_preset` | test_scene_properties_unit | 8 (CENTER) | 0 (TOP_LEFT) | Base scene anchor_* props reset stored_layout_preset |

**Analysis:** TICKET-0307 (gameplay-programmer) removed the redundant `anchor_*` overrides from the three *instance* nodes in `game_hud.tscn`, which was the correct partial fix. However, the **base scene** files (`compass_bar.tscn`, `mining_progress.tscn`, `mining_minigame_overlay.tscn`) still contain explicit `anchor_left`, `anchor_right`, etc. properties stored after `anchors_preset`. When Godot instantiates these base scenes, those explicit anchor properties reset `stored_layout_preset` to 0 (PRESET_NONE/TOP_LEFT). The `anchors_preset = 5/8` override in `game_hud.tscn` is then applied on top, but may still be overridden by the base scene's stored anchor values depending on Godot 4.5's load order.

**TICKET-0307 has been reopened** (status: OPEN) and reassigned to gameplay-programmer with detailed re-test notes. The fix must also be applied to the base scene .tscn files.

---

## Phase 2 Ticket Verification

All Phase 2 implementation tickets (TICKET-0291–TICKET-0303) confirmed DONE:

| Ticket | Title | Status |
|--------|-------|--------|
| TICKET-0291 | M11 Scene-First — Ship Machine Panels (recycler, fabricator, automation_hub) | ✅ DONE |
| TICKET-0292 | M11 Scene-First — Navigation Console and Module Placement UI | ✅ DONE |
| TICKET-0293 | M11 Scene-First — Inventory Screen and Inventory Action Popup | ✅ DONE |
| TICKET-0294 | M11 Scene-First — HUD Readout components (scanner, ship_globals, ship_stats) | ✅ DONE |
| TICKET-0295 | M11 Scene-First — Tech Tree Panel | ✅ DONE |
| TICKET-0296 | M11 Scene-First — Main Menu | ✅ DONE |
| TICKET-0297 | M11 Scene-First — Ship Interior (60+ persistent nodes) | ✅ DONE |
| TICKET-0298 | M11 Scene-First — GameWorld persistent system nodes | ✅ DONE |
| TICKET-0299 | M11 Scene-First — Ship Status Display and Travel Fade Layer | ✅ DONE |
| TICKET-0300 | M11 Scene-First — HUD layout properties set in _ready() (8 files) | ✅ DONE |
| TICKET-0301 | M11 Standards — Fix direct Input.is_action_just_pressed() bypass | ✅ DONE |
| TICKET-0302 | M11 Standards — Add element types to Array declarations (6 files) | ✅ DONE |
| TICKET-0303 | M11 Standards — Fix single-# docstrings to ## format (3 files) | ✅ DONE |

---

## QA Phase Bug Fixes (TICKET-0305 through TICKET-0310)

Six regressions identified during QA testing and fixed by implementing agents:

| Ticket | Priority | Title | Status | Notes |
|--------|----------|-------|--------|-------|
| TICKET-0305 | P2 | Ship boarding ContextualPrompt shows when not aiming at hull | ✅ DONE | Synced _aim_valid with prompt display |
| TICKET-0306 | **P1** | tech_tree_defs.gd get_prerequisites() returns empty (Array[String] type mismatch) | ✅ DONE | Critical tech tree fix; changed to untyped interim var |
| TICKET-0307 | P2 | HUD CompassBar/MiningProgress/MiningMinigameOverlay anchor presets reset to 0 | 🔴 OPEN | Fix incomplete — re-test failed; base scene anchor_* properties not addressed |
| TICKET-0308 | P2 | InventoryActionPopup visible by default and not found as child | ✅ DONE | Corrected popup visibility and signal routing |
| TICKET-0309 | P2 | NavigationConsole._biome_node_ids missing debris_field | ✅ DONE | Corrected biome discovery logic |
| TICKET-0310 | P2 | compass_bar._on_tree_node_added infinite loop during terrain generation | ✅ DONE | Added is_inside_tree() guard |

---

## M11 Full Scope Summary

M11 addressed GDScript standards compliance violations identified in the audit report (`docs/studio/reports/2026-03-03-m11-gdscript-audit.md`), which found 65 violations across 31 files.

### Work Completed

**Scene-First Refactorings (TICKET-0291–TICKET-0300):** 13+ scripts refactored from programmatic UI construction (`_build_ui()` / `_ready()` layout code) to proper `.tscn`-first scenes with `@onready` references. This addressed 44 SCENE_FIRST and LAYOUT_IN_READY violations across the following systems:
- Ship machine panels: recycler, fabricator, automation_hub
- Navigation console, module placement UI
- Inventory screen, inventory action popup
- HUD readout components: scanner, ship_globals, ship_stats_sidebar
- Tech tree panel
- Main menu
- Ship interior (largest refactoring: 60+ persistent nodes)
- GameWorld persistent system nodes (6 groups)
- Ship status display, travel fade layer
- HUD layout properties: 8 components corrected

**Standards Remediations (TICKET-0301–TICKET-0303):**
- Input bypass fix: Added `InputManager.is_action_just_pressed_unsuppressed()` to handle always-active actions
- Array type annotations: Added element types to 6 files
- Docstring format: Corrected 3 files from single-`#` to `##` format

### Scripts Remediated

Key scripts modified during M11:
`recycler_panel.gd`, `fabricator_panel.gd`, `automation_hub_panel.gd`, `navigation_console.gd`, `module_placement_ui.gd`, `inventory_screen.gd`, `inventory_action_popup.gd`, `scanner_readout.gd`, `ship_globals_hud.gd`, `ship_stats_sidebar.gd`, `tech_tree_panel.gd`, `main_menu.gd`, `ship_interior.gd`, `game_world.gd`, `ship_status_display.gd`, `travel_sequence_manager.gd`, `game_hud.gd`, `interaction_prompt_hud.gd`, `resource_type_wheel.gd`, `mining_minigame_overlay.gd`, `compass_bar.gd`, `battery_bar.gd`, `fuel_gauge.gd`, `mining_progress.gd`, `input_manager.gd`, `collision_probe.gd`, `terrain_generator.gd`, `mining_minigame_overlay.gd`, `tech_tree_defs.gd`, `debug_ship_boarding_handler.gd`, `game.gd`, `ship_enter_zone.gd`

---

## Gate Decision

**Status: ❌ BLOCKED**

The M11 Phase Gate QA sign-off CANNOT be granted because:

1. **Test suite has 3 failing tests** — Acceptance criteria require zero failures. The 3 failing tests are in `test_scene_properties_unit` for HUD anchor presets.
2. **TICKET-0307 fix was ineffective** — The gameplay-programmer's fix (commit b552175) removed redundant anchor overrides from `game_hud.tscn` instance nodes but did not address the root cause in the base scene .tscn files. TICKET-0307 has been reopened and reassigned to gameplay-programmer.

**Required to unblock:**
- gameplay-programmer must fix TICKET-0307 by removing redundant `anchor_*` properties from `compass_bar.tscn`, `mining_progress.tscn`, and `mining_minigame_overlay.tscn` (or use a different anchoring approach that survives scene instantiation)
- All 3 failing tests must pass
- QA re-test must confirm zero failures

**P2 and P3 Findings Log:**

- 2026-03-04 [qa-engineer] FINDING [P2]: game_hud.tscn HUDRoot/CompassBar, MiningProgress, MiningMinigameOverlay — anchors_preset returns 0 at runtime despite fix in TICKET-0307. Disposition: blocking sign-off (test failure). Tracked in TICKET-0307 (OPEN).

---

*Report generated by qa-engineer as part of TICKET-0304 M11 QA Phase Gate.*
