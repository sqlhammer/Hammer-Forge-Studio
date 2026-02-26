# QA Test Results — M7: Ship Interior + Scene Architecture Overhaul

**Ticket:** TICKET-0130
**Tester:** qa-engineer
**Test Date:** 2026-02-26
**Godot Version:** 4.5.1 stable (headless)

---

## Executive Summary

**M7 QA SIGN-OFF: CONDITIONAL — PENDING TICKET-0151**

457/457 loaded tests pass (100%). One test suite (test_scanner_unit, 23 tests) fails to parse due to stale `Scanner.LAYER_INTERACTABLE` reference removed in TICKET-0144. BUGFIX TICKET-0151 filed (P1). Once resolved, expected total is 480 tests.

Secondary process issue: missing `physics_layers.gd.uid` — TICKET-0150 filed (P2).

---

## Unit Test Results

**457 passed, 0 failed, 0 skipped (24 of 25 suites loaded)**

| Suite | Tests | Status |
|-------|-------|--------|
| TestAutomationHubUnit | 19 | PASS |
| TestBatteryBarUnit | 12 | PASS |
| TestCollisionCoverageUnit | 33 | PASS |
| TestCompassBarUnit | 15 | PASS |
| TestDepositRegistryUnit | 17 | PASS |
| TestDepositUnit | 20 | PASS |
| TestDroneAgentUnit | 15 | PASS |
| TestDroneProgramUnit | 10 | PASS |
| TestFabricatorUnit | 19 | PASS |
| TestHeadLampUnit | 17 | PASS |
| TestInputManagerUnit | 11 | PASS |
| TestInventoryUnit | 34 | PASS |
| TestMiningMinigameUnit | 13 | PASS |
| TestMiningUnit | 26 | PASS |
| TestModuleDefsUnit | 12 | PASS |
| TestModuleManagerUnit | 25 | PASS |
| TestRecyclerUnit | 28 | PASS |
| TestResourceDefsUnit | 15 | PASS |
| TestScannerThirdPersonUnit | 8 | PASS |
| **TestScannerUnit** | **23** | **FAIL TO LOAD** |
| TestShipInteriorUnit | 16 | PASS |
| TestShipStateUnit | 30 | PASS |
| TestSpareBatteryUnit | 10 | PASS |
| TestSuitBatteryUnit | 32 | PASS |
| TestTechTreeUnit | 20 | PASS |

---

## Bugs Filed

| Ticket | Severity | Title |
|--------|----------|-------|
| TICKET-0151 | P1 | test_scanner_unit.gd parse error: Scanner.LAYER_INTERACTABLE removed |
| TICKET-0150 | P2 | Missing UID file for physics_layers.gd |
