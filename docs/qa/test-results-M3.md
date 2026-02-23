# QA Test Results — M3: Scan / Mine Gameplay Loop

**Ticket:** TICKET-0031
**Tester:** qa-engineer
**Test Date:** 2026-02-23
**Godot Version:** 4.5.1 stable (Vulkan 1.4.325, Forward+)
**Hardware:** NVIDIA GeForce RTX 4070 Laptop GPU

---

## Executive Summary

**M3 QA SIGN-OFF: APPROVED**

All 193 unit tests pass across 9 test suites. Three new test suites added (Scanner: 23, Mining: 23, CompassBar: 15). One P1 bugfix applied during QA (class_name/autoload conflict blocking all autoload singletons). One pre-existing P2 issue identified (battery bar polygon rendering). Test world loads and runs without fatal errors or runtime crashes.

---

## Unit Test Results

**Total: 193 passed, 0 failed, 0 skipped**

| Suite | Tests | Result | Notes |
|-------|-------|--------|-------|
| TestCompassBarUnit | 15 | **NEW — ALL PASS** | Marker management, dedup, capacity, depletion cleanup, bearing math |
| TestDepositUnit | 20 | **ALL PASS** | Updated for P1 extract() Dictionary return |
| TestDepositRegistryUnit | 17 | **ALL PASS** | Updated for DepositRegistryType class_name |
| TestInputManagerUnit | 11 | **ALL PASS** | Regression suite from M1 |
| TestInventoryUnit | 34 | **ALL PASS** | Updated DEFAULT_STACK_SIZE constant |
| TestMiningUnit | 26 | **ALL PASS** | Extraction data flow, inventory integration, battery drain |
| TestResourceDefsUnit | 15 | **ALL PASS** | Regression suite from M3 Phase 1 |
| TestScannerUnit | 23 | **ALL PASS** | Constants, scan state machine, registry ping, analysis |
| TestSuitBatteryUnit | 32 | **ALL PASS** | Updated for SuitBatteryType class_name |

### New Test Coverage (M3)

**TestScannerUnit (23 tests):**
- Scanner constants (PING_RANGE, PING_COOLDOWN, ANALYSIS_DURATION, etc.)
- Deposit scan state machine (UNDISCOVERED → PINGED → ANALYZED)
- Signal emissions (scan_state_changed)
- Idempotency (re-ping, re-analyze are no-ops)
- Registry ping simulation (range filtering, depleted exclusion)
- Analysis summary structure and content

**TestMiningUnit (26 tests):**
- Mining constants (EXTRACTION_DURATION, EXTRACTION_AMOUNT, ranges)
- Extract() Dictionary return (P1 bugfix verification)
- Extract → inventory integration (stacking, overflow, full inventory)
- Battery drain calculations (per-cycle cost, can_mine threshold)
- Complete mining flow simulation (extract + add + drain)
- Edge cases (deposit depletion, battery depletion mid-mining)

**TestCompassBarUnit (15 tests):**
- Constants (MARKER_PERSIST_TIME, MAX_MARKERS, DISTANCE_CONE_DEG, COMPASS_WIDTH)
- Marker add tracking (single, multiple deposits)
- Deduplication (same deposit added twice is no-op)
- Capacity enforcement (MAX_MARKERS limit respected)
- Marker removal (correct deposit removed, unknown deposit is no-op)
- Depletion cleanup (depleted deposits auto-removed, active deposits preserved)
- Bearing-to-screen-x calculation (center, left edge, right edge, 360-degree wrapping)

---

## Bugfixes Applied During QA

### P1: class_name / Autoload Singleton Conflict (TICKET-0032)

**Root Cause:** Scripts with `class_name SuitBattery` and `class_name DepositRegistry` conflicted with their autoload singleton names. Godot resolved the identifier as the class type instead of the singleton instance, causing all autoload calls to fail with "Cannot call non-static function" errors and autoloads resolving to `<null>`.

**Fix:** Renamed class_name declarations to avoid collision:
- `suit_battery.gd`: `class_name SuitBattery` → `class_name SuitBatteryType`
- `deposit_registry.gd`: `class_name DepositRegistry` → `class_name DepositRegistryType`

**Impact:** All gameplay scripts using `SuitBattery.*` and `DepositRegistry.*` now correctly resolve to the autoload singletons. Test files use `SuitBatteryType` and `DepositRegistryType` for class-level operations (.new(), constants).

### P2: test_world.gd TONE_MAP_ACES Deprecation

**Root Cause:** `Environment.TONE_MAP_ACES` renamed to `Environment.TONE_MAPPER_ACES` in Godot 4.5.

**Fix:** Updated `test_world.gd:62` to use the new constant name.

### Test File Updates

- `test_deposit_unit.gd`: Updated extract() assertions for Dictionary return pattern
- `test_deposit_unit.gd`: Updated serialize test for `scan_state` key (replaces `is_analyzed`)
- `test_inventory_unit.gd`: Updated `MAX_STACK_SIZE` → `DEFAULT_STACK_SIZE` (5 occurrences)
- `test_deposit_registry_unit.gd`: Updated to use `DepositRegistryType` for .new() and constants
- `test_suit_battery_unit.gd`: Updated to use `SuitBatteryType` for .new() and constants

---

## Manual QA: Test World

### Scene Load & Initialization

| # | Check | Result | Notes |
|---|-------|--------|-------|
| 1 | Test world scene loads | **PASS** | No fatal errors on load |
| 2 | Player spawns at ship | **PASS** | Position (0, 0, 8) near ship |
| 3 | Deposits generated procedurally | **PASS** | 8-12 deposits placed via DepositRegistry |
| 4 | Scanner system initializes | **PASS** | Scanner.new() + setup() completes |
| 5 | Mining system initializes | **PASS** | Mining.new() + setup() completes |
| 6 | HUD initializes | **PASS** | GameHUD and InventoryScreen created |
| 7 | Mouse captured for first-person | **PASS** | MOUSE_MODE_CAPTURED on _ready |

### Pre-existing Warnings (Non-blocking)

| ID | Warning | File | Severity | Notes |
|----|---------|------|----------|-------|
| W01 | `!is_inside_tree()` on global_position access | deposit_registry.gd:95 | P3 | Deposits not yet in tree during generation |
| W02 | Invalid polygon triangulation | battery_bar.gd:126 | P2 | Battery icon polygon drawing fails |
| W03 | Invalid UID references in player.tscn | player.tscn | P3 | Falls back to text paths, no functional impact |
| W04 | Unused variable warnings | HUD/UI scripts | P3 | Code style, no functional impact |

---

## Findings Summary

### P1 Findings (Fixed)

| ID | Finding | Status |
|----|---------|--------|
| M3-F01 | class_name/autoload conflict breaks all autoload singletons | **FIXED** — class_names renamed |
| M3-F02 | TONE_MAP_ACES deprecated in Godot 4.5 | **FIXED** — updated to TONE_MAPPER_ACES |

### P2 Findings (Non-blocking)

| ID | Finding | Recommendation |
|----|---------|----------------|
| M3-F03 | Battery bar polygon triangulation fails | File BUG ticket for UI programmer to fix _draw_battery_icon() polygon data |

### P3 Findings (Informational)

| ID | Finding | Recommendation |
|----|---------|----------------|
| M3-F04 | Deposits access global_position before being in scene tree | Refactor generate_m3_deposits to defer position assignment, or use local position |
| M3-F05 | Invalid UID references in player.tscn | Re-save player.tscn in Godot editor to refresh UIDs |
| M3-F06 | Multiple unused variable warnings in HUD/UI scripts | Code review cleanup pass |

---

## Blocker Assessment

- **P0 bugs:** 0
- **P1 bugs:** 0 (2 found and fixed during QA)
- **P2 findings:** 1 (battery bar polygon — cosmetic only)
- **P3 findings:** 3 (non-functional, documented for cleanup)

Per QA protocol: no P0 or P1 bugs remain open. P2 finding is cosmetic and does not affect gameplay. All 178 unit tests pass. Test world loads and runs without crashes.

---

## QA Sign-Off

**M3 Milestone: Scan / Mine Gameplay Loop — APPROVED**

All M3 systems (Scanner, Mining, Battery, Inventory, Deposits, HUD, Compass) have unit test coverage and pass. Three new test suites added covering 64 tests for Scanner, Mining, and CompassBar. One P1 autoload conflict identified, root-caused, and fixed. Test world runs without fatal errors or runtime crashes. Total test count: 193 (up from 118 at M3 start).

Signed: **qa-engineer**
Date: **2026-02-23**

---

## Regression: InputManager Refactor (TICKET-0051)

**Ticket:** TICKET-0051
**Tester:** qa-engineer
**Test Date:** 2026-02-23
**Scope:** Verify no regressions from TICKET-0033 (scanner direct Input API), TICKET-0034 (InputManager mouse button registration), TICKET-0035 (runtime InputMap centralization)

### Code Review — InputManager Routing

| # | Check | Result | Notes |
|---|-------|--------|-------|
| 1 | scanner.gd uses InputManager for all input | **PASS** | `InputManager.is_action_just_pressed("scan")` (line 82), `InputManager.is_action_pressed("interact")` (line 96). Zero direct Input API calls. |
| 2 | mining.gd uses InputManager for all input | **PASS** | `InputManager.is_action_pressed("use_tool")` (line 65). Zero direct Input API calls. Zero runtime InputMap modifications. |
| 3 | inventory_screen.gd uses correct input pattern | **PASS** | Event-based `_input()` method (line 49-73) using `event.is_action_pressed()` — correct for UI overlays. Only `Input.set_mouse_mode()` for UI control. Zero runtime InputMap modifications. |
| 4 | Zero InputMap modifications in gameplay scripts | **PASS** | `grep -r "InputMap\.(add_action\|action_add_event\|erase_action)" game/scripts/` returns zero matches. All InputMap setup is centralized in `InputManager._setup_input_actions()`. |
| 5 | Zero direct Input.is_action_* in gameplay scripts | **PASS** | `grep -r "Input\.is_action_(pressed\|just_pressed)" game/scripts/` returns zero matches. All input queries route through InputManager. |
| 6 | InputManager registers all required actions | **PASS** | `scan`, `interact`, `use_tool`, `inventory_toggle` + all movement/camera actions registered in `_setup_input_actions()`. Mouse button (MOUSE_BUTTON_LEFT for use_tool) correctly registered via TICKET-0034. |

### Unit Test Execution

**Result: BLOCKED**

The full test suite cannot execute due to M4 autoload parse errors (unrelated to InputManager refactor):
- `module_manager.gd` fails to parse: `ShipState` autoload identifier not resolved (TICKET-0052)
- `recycler.gd` fails to parse: `is_processing()` overrides `Node.is_processing()` (TICKET-0053)
- Cascade: both autoloads fail to instantiate, blocking ALL scene loading including the test runner

These are M4 data layer bugs committed in TICKET-0039/0040/0041, not caused by the InputManager refactor.

### Bugs Filed

| Ticket | Title | Priority | Assigned |
|--------|-------|----------|----------|
| TICKET-0052 | module_manager.gd ShipState parse error | P1 | systems-programmer |
| TICKET-0053 | recycler.gd is_processing() override | P1 | systems-programmer |

### Regression Assessment

**InputManager refactor code changes: PASS** — All input routing is correct. Scanner, mining, and inventory scripts properly use InputManager. Zero direct Input API calls remain in gameplay scripts. Zero runtime InputMap modifications outside InputManager.

**Test suite execution: BLOCKED** — Cannot verify runtime behavior due to unrelated M4 parse errors. TICKET-0052 and TICKET-0053 must be resolved before test execution can confirm pass.

**Recommendation:** Resolve TICKET-0052 and TICKET-0053, then re-run full test suite to confirm all 193+ tests still pass. The InputManager refactor itself introduces no code-level regressions based on static analysis.

Signed: **qa-engineer**
Date: **2026-02-23**
