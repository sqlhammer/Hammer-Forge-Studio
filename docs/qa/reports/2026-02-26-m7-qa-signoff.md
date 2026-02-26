# QA Test Results — M7: Ship Interior + Scene Architecture Overhaul

**Ticket:** TICKET-0130
**Tester:** qa-engineer
**Test Date:** 2026-02-26
**Godot Version:** 4.5.1 stable (headless)

---

## Executive Summary

**M7 QA SIGN-OFF: CONDITIONAL — PENDING 1 BUGFIX**

457 of 480 tests pass across 24 of 25 test suites. One test suite (`test_scanner_unit.gd`, 23 tests) fails to parse due to a stale reference to `Scanner.LAYER_INTERACTABLE`, which was removed during TICKET-0144 (PhysicsLayers centralization) but the test was not updated. BUGFIX ticket TICKET-0151 filed.

A secondary process issue (missing `physics_layers.gd.uid` file) was discovered and resolved by regenerating the Godot class cache via `--import`. BUGFIX ticket TICKET-0150 filed for the missing UID commit.

**All loaded tests pass (457/457, 100%)**. No P0 bugs found. One P1 regression (TICKET-0151) blocks full suite execution. The milestone cannot close until TICKET-0151 is resolved and the full test suite (expected 480 tests) passes with zero failures.

---

## Unit Test Results

**Total: 457 passed, 0 failed, 0 skipped (of 457 loaded)**
**1 suite failed to load: test_scanner_unit (23 tests) — parse error**

| Suite | Tests | Result | Notes |
|-------|-------|--------|-------|
| TestAutomationHubUnit | 19 | ALL PASS | Regression — no changes |
| TestBatteryBarUnit | 12 | ALL PASS | M7 amber warning tier tests included |
| TestCollisionCoverageUnit | 33 | ALL PASS | Updated to use PhysicsLayers constants |
| TestCompassBarUnit | 15 | ALL PASS | M7 centering fix included |
| TestDepositRegistryUnit | 17 | ALL PASS | Regression — no changes |
| TestDepositUnit | 20 | ALL PASS | Regression — no changes |
| TestDroneAgentUnit | 15 | ALL PASS | Regression — no changes |
| TestDroneProgramUnit | 10 | ALL PASS | Regression — no changes |
| TestFabricatorUnit | 19 | ALL PASS | Regression — no changes |
| TestHeadLampUnit | 17 | ALL PASS | Regression — no changes |
| TestInputManagerUnit | 11 | ALL PASS | Regression — no changes |
| TestInventoryUnit | 34 | ALL PASS | Regression — no changes |
| TestMiningMinigameUnit | 13 | ALL PASS | Regression — no changes |
| TestMiningUnit | 26 | ALL PASS | Regression — no changes |
| TestModuleDefsUnit | 12 | ALL PASS | Regression — no changes |
| TestModuleManagerUnit | 25 | ALL PASS | Regression — no changes |
| TestRecyclerUnit | 28 | ALL PASS | Regression — no changes |
| TestResourceDefsUnit | 15 | ALL PASS | Regression — no changes |
| TestScannerThirdPersonUnit | 8 | ALL PASS | Regression — no changes |
| **TestScannerUnit** | **23** | **FAIL TO LOAD** | **Parse error: Scanner.LAYER_INTERACTABLE removed in TICKET-0144** |
| TestShipInteriorUnit | 16 | ALL PASS | M7 zone management tests |
| TestShipStateUnit | 30 | ALL PASS | Regression — no changes |
| TestSpareBatteryUnit | 10 | ALL PASS | Regression — no changes |
| TestSuitBatteryUnit | 32 | ALL PASS | Regression — no changes |
| TestTechTreeUnit | 20 | ALL PASS | Regression — no changes |

---

## M7 Findings

### P1 — Blocking Sign-Off

| Finding | System | Description | Disposition |
|---------|--------|-------------|-------------|
| TICKET-0151 | test_scanner_unit.gd | Parse error: `Scanner.LAYER_INTERACTABLE` removed in TICKET-0144 but test not updated. 23 tests cannot execute. | Blocking sign-off — BUGFIX ticket filed |

### P2 — Known Issues, Acceptable After Fix

| Finding | System | Description | Disposition |
|---------|--------|-------------|-------------|
| TICKET-0150 | physics_layers.gd | Missing `.gd.uid` sidecar file. Fresh checkouts require `--import` to register PhysicsLayers class. | Known issue — BUGFIX ticket filed |

### P3 — Minor Observations, Non-Blocking

| Finding | System | Description | Disposition |
|---------|--------|-------------|-------------|
| OBS-01 | ship_interior.gd | Signal `placement_zone_interacted` declared (line 9) but never emitted. API is incomplete but no consumers depend on it currently. | Known issue, acceptable for milestone. Recommend addressing in M8. |
| OBS-02 | interaction_prompt_hud.gd | Group-based detection (`interaction_prompt_source`) relies on scene setup convention. No validation or warning if group is empty. | Known issue, acceptable for milestone. |
| OBS-03 | Autoload duplication | Recycler, Fabricator, AutomationHub registered as autoloads AND have scene wrappers. Architectural debt noted in TICKET-0113 handoff. | Deferred — documented for M8+ |

---

## Code Review Verification

All M7 systems reviewed during code review (TICKET-0129: APPROVED WITH MINOR NOTES):
- Ship interior layout: 24m x 12m, 4 module zones, vestibule/corridor/machine room/cockpit
- Cockpit: console + 4 diegetic status displays + exterior viewport
- Scene architecture: 7 refactoring tickets complete, all scenes standalone
- Interaction prompt HUD: raycast + area-based detection
- Battery bar amber warning: 3-tier color states (full/warning/critical)
- PhysicsLayers core class: centralized constants

---

## M7 Bugfix Tickets Verified

All 5 pre-dependency BUGFIX tickets verified DONE:

| Ticket | Title | Status | Verification |
|--------|-------|--------|--------------|
| TICKET-0139 | Inventory ship status icons misaligned | DONE | Fix committed (d6923c5) — size_flags_vertical added |
| TICKET-0140 | HUD compass not centered | DONE | Fix committed (d2484dc) — anchors set to center |
| TICKET-0141 | Ship machines pre-placed at start | DONE | Fix committed (d2fd579) — static instances removed |
| TICKET-0142 | Cockpit displays floating in center | DONE | Fix committed (dca63f4) — moved to Z=-11.85 (back wall) |
| TICKET-0143 | Viewport renders flat color | DONE | Fix committed (8d8ea87) — SubViewport + Camera3D approach |

---

## Manual Testing Status

Manual testing was performed via code review and scene file analysis (headless environment — no Godot MCP playtest tools available). Visual/interaction testing requires in-editor playtest with MCP tools.

### Ship Interior (Code Review)
- [x] 4 module zones defined with correct 2x2 grid positions
- [x] Entry/exit fade transitions implemented (FADE_DURATION=0.3s)
- [x] Room dimensions correct (CEILING_HEIGHT=3.0, CORRIDOR_WIDTH=4.0)
- [ ] Walk-through collision testing — requires in-editor playtest

### Machine Room (Code Review)
- [x] Module zones support place/remove/query API
- [x] All 4 zones start empty (TICKET-0141 verified)
- [x] Teal floor pad markings in zone geometry
- [ ] Module interaction panels — requires in-editor playtest

### Cockpit (Code Review)
- [x] CockpitConsole placed at (0, 0, -11.5)
- [x] 4 status displays positioned at Z=-11.85 (back wall, TICKET-0142 verified)
- [x] SubViewport approach for exterior viewport (TICKET-0143 verified)
- [ ] Real-time display updates — requires in-editor playtest

### Refactored Scenes (Code Review)
- [x] Ship exterior: standalone scene, instanced in test_world.gd
- [x] Deposits: standalone scene, generated via DepositRegistry
- [x] Machines: standalone scenes, instanced in ship_interior.tscn
- [x] Tools: standalone scenes (hand_drill.tscn, scanner.tscn)
- [x] Carriables: standalone scenes (spare_battery.tscn, head_lamp.tscn)
- [x] Mining drone: standalone scene, instanced via DroneManager
- [x] UI panels/HUD: all extracted to standalone subscenes in game_hud.tscn

### New Features (Code Review)
- [x] InteractionPromptHUD: raycast + area detection implemented
- [x] Hold action thick border: KEY_BADGE_BORDER_HOLD_WIDTH defined
- [x] Persistent controls panel: implemented in HUD
- [x] Battery bar amber tier: 3-state color logic (full/warning/critical)

---

## Regression Checklist

All M1-M6 test suites continue to pass (zero regressions in loaded suites). Cross-milestone stability confirmed. The only regression is the scanner_unit parse error introduced by TICKET-0144.

---

## QA Sign-Off Decision

**CONDITIONAL APPROVAL** — pending resolution of:
1. **TICKET-0151 (P1):** test_scanner_unit.gd parse error must be fixed and all 480 tests must pass
2. **TICKET-0150 (P2):** physics_layers.gd.uid must be committed (process compliance)

Once TICKET-0151 is resolved and the full test suite passes (480/480), QA sign-off is granted. Studio Head final approval required before milestone close.
