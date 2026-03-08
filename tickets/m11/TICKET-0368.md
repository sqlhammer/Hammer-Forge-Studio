---
id: TICKET-0368
title: "VERIFY — OOM crash fix in test_procedural_terrain_unit / terrain_generator headless run (TICKET-0367)"
type: TASK
status: DONE
priority: P2
owner: play-tester
created_by: producer
created_at: 2026-03-08
updated_at: 2026-03-08
milestone: "M11"
phase: "QA"
depends_on: [TICKET-0367]
blocks: []
tags: [auto-created]
---

## Summary

Verify that test_procedural_terrain_unit runs to completion headlessly without crashing after the TICKET-0367 OOM fix.

## Acceptance Criteria

- [x] Visual verification: The full headless test suite runs past test_procedural_terrain_unit without a process crash or SIGILL signal
- [x] State dump: All test suites registered after test_procedural_terrain_unit execute and report results (none skipped due to crash)
- [x] Unit test suite: zero failures across all tests
- [x] No runtime errors during any verification scenario

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-03-08 [conductor] Created via orchestration wave 53
- 2026-03-08 [play-tester] Starting work — verifying OOM crash fix from TICKET-0367 by running full headless test suite
- 2026-03-08 [play-tester] DONE — PASS. Ran full headless test suite (Godot 4.5.1 stable, Windows Server 2025, 49 suites).

  **Fix Confirmed in Source Code (terrain_generator.gd):**
  The TICKET-0367 fix (commit e3547be, PR #391) replaced the SurfaceTool-based `_assemble_full_mesh`
  with a two-pass approach: Pass 1 counts total vertices and collision faces; Pass 2 fills
  pre-sized PackedVector3Array instances by index (single allocation each, zero reallocation).
  ArrayMesh.add_surface_from_arrays() replaces SurfaceTool to eliminate the secondary ~22-28 MB
  internal buffer. This eliminates the heap fragmentation that caused OOM after 20+ consecutive
  generate() calls.

  **Key Criterion — test_procedural_terrain_unit:**
  `[228715] --- Suite: test_procedural_terrain_unit --- 26/26 passed`
  NO OOM crash. NO SIGILL (signal 4). NO "Parameter mem is null" error. All 26 tests including
  `_test_unresolvable_request_produces_warning` (the crash trigger at line 502) completed
  successfully. Criterion: PASS.

  **All suites after test_procedural_terrain_unit executed (none skipped due to crash):**
  - test_recycler_unit — 28/28 passed
  - test_resource_defs_unit — 15/15 passed
  - test_resource_respawn_unit — 26/26 passed
  - test_rock_warrens_biome_unit — 16/16 passed
  - test_scanner_third_person_unit — 8/8 passed
  - test_scanner_unit — 23/23 passed
  - test_scene_properties_unit — 38/38 passed
  - test_ship_interior_unit — 16/16 passed
  - test_ship_state_unit — 30/30 passed
  - test_spare_battery_unit — 10/10 passed
  - test_suit_battery_unit — 32/32 passed
  - test_tech_tree_unit — 20/20 passed
  - test_travel_sequence_unit — 20/20 passed
  - test_world_boundary_unit — 54/54 passed
  All 14 suites after terrain ran to completion. Criterion: PASS.

  **Full Test Suite Results — 49/49 suites, zero failures:**
  test_automation_hub_unit 19/19, test_battery_bar_unit 12/12, test_collision_coverage_unit 33/33,
  test_compass_bar_unit 15/15, test_cryonite_unit 28/28, test_debris_field_biome_unit 25/25,
  test_debug_launcher_unit 6/6, test_deep_resource_node_scene 14/14, test_deep_resource_node_unit 27/27,
  test_deposit_registry_unit 17/17, test_deposit_unit 20/20, test_drone_agent_unit 15/15,
  test_drone_program_unit 10/10, test_dropped_item_unit 19/19, test_fabricator_unit 19/19,
  test_fuel_gauge_unit 23/23, test_fuel_system_unit 44/44, test_game_startup_unit 20/20,
  test_game_world_unit 14/14, test_head_lamp_unit 17/17, test_input_manager_unit 11/11,
  test_interaction_prompt_hud_unit 7/7, test_inventory_action_popup_unit 23/23,
  test_inventory_screen_popup_unit 14/14, test_inventory_unit 39/39, test_m8_tdd_foundation_gate 5/5,
  test_mining_minigame_unit 13/13, test_mining_unit 26/26, test_module_defs_unit 12/12,
  test_module_manager_unit 25/25, test_mouse_interaction_unit 13/13,
  test_navigation_console_unit 15/15, test_navigation_system_unit 36/36,
  test_player_jump_unit 11/11, **test_procedural_terrain_unit 26/26**,
  test_recycler_unit 28/28, test_resource_defs_unit 15/15, test_resource_respawn_unit 26/26,
  test_rock_warrens_biome_unit 16/16, test_scanner_third_person_unit 8/8,
  test_scanner_unit 23/23, test_scene_properties_unit 38/38, test_ship_interior_unit 16/16,
  test_ship_state_unit 30/30, test_spare_battery_unit 10/10, test_suit_battery_unit 32/32,
  test_tech_tree_unit 20/20, test_travel_sequence_unit 20/20, test_world_boundary_unit 54/54.
  Criterion: PASS.

  **No Runtime Errors:** No OOM, SIGILL, CrashHandler, or process crash. Only pre-existing
  infrastructure errors (Vulkan→D3D12 fallback, audio driver fallback) and expected test
  scenario messages (GameWorld biome not found, SignalSpy async warnings) — none related to
  terrain generation. Criterion: PASS.

  **Overall Verdict: PASS** — TICKET-0367 OOM fix confirmed working. test_procedural_terrain_unit
  completes with 26/26 passed; all 49 suites run to completion with zero failures.
