# Regression Test Checklist

**Owner:** qa-engineer
**Status:** Active
**Last Updated:** 2026-02-26 (M7)

> Execute this checklist at the end of every milestone before QA sign-off. Add new items as systems are implemented. Mark each item Pass / Fail / N/A.

---

## How to Use

1. Copy this checklist into a new file: `docs/qa/reports/YYYY-MM-DD-regression.md`
2. Execute each test in a fresh game run
3. Mark results: Pass / Fail (file BUG ticket) / N/A
4. Attach the completed checklist to the milestone sign-off report

---

## Core Systems

| # | Test | Expected Result | Result |
|---|------|-----------------|--------|
| 1 | Game launches without errors | No errors in Godot output log | |
| 2 | Save and load completes successfully | Game state restored after load | |
| 3 | Input actions respond correctly | All mapped inputs trigger expected behavior | |
| 4 | Full test suite passes headlessly | All test suites load and pass with zero failures | |

---

## Gameplay — Scanning & Mining (M3)

| # | Test | Expected Result | Result |
|---|------|-----------------|--------|
| 5 | Scanner ping detects deposits in range | Deposits within 80m transition to PINGED | |
| 6 | Scanner analysis completes on pinged deposit | 2.5s hold completes analysis, summary available | |
| 7 | Hand drill extracts resources from analyzed deposit | Battery drains, inventory receives items | |
| 8 | Mining minigame functions correctly | Line-tracing mechanic works per design | |
| 9 | Depleted deposits excluded from ping | Fully extracted deposits not found in range | |

---

## Gameplay — Ship Infrastructure (M4)

| # | Test | Expected Result | Result |
|---|------|-----------------|--------|
| 10 | Ship globals initialize correctly | Power=100, Integrity=100, Heat=50, O2=100 | |
| 11 | Module install/remove lifecycle works | Modules install with power draw, remove cleanly | |
| 12 | Recycler processes scrap metal | 3 Scrap Metal -> 1 Metal in 5.0s | |
| 13 | Power capacity prevents overload | Module rejected if draw exceeds available | |

---

## Gameplay — Processing & Crafting (M5)

| # | Test | Expected Result | Result |
|---|------|-----------------|--------|
| 14 | Fabricator crafts items from recipes | Correct inputs consumed, output produced | |
| 15 | Automation Hub deploys mining drones | Drones assigned to deposits, auto-mine | |
| 16 | Tech tree unlock progression works | Prerequisites enforced, costs deducted | |

---

## Gameplay — Ship Interior (M7)

| # | Test | Expected Result | Result |
|---|------|-----------------|--------|
| 17 | Player enters ship via entry zone | Fade transition, spawn in vestibule | |
| 18 | Player exits ship from vestibule | Fade transition, return to exterior | |
| 19 | Ship interior walkthrough collision-free | Vestibule -> machine room -> corridor -> cockpit | |
| 20 | All 4 module zones start empty | No machines pre-placed at game start | |
| 21 | Module zones accept machine placement | place_module_in_zone positions correctly | |
| 22 | Cockpit console visible and positioned | At (0, 0, -11.5) in cockpit | |
| 23 | Cockpit status displays on back wall | 4 displays at Z=-11.85, show ship globals | |
| 24 | Cockpit viewport shows exterior | SubViewport renders outside world | |

---

## Scene Architecture (M7)

| # | Test | Expected Result | Result |
|---|------|-----------------|--------|
| 25 | Ship exterior loads as instanced scene | Standalone scene, collision intact | |
| 26 | Resource deposits spawn as instanced scenes | Generated via DepositRegistry, scan/mine works | |
| 27 | Machine scenes are standalone | Recycler, Fabricator, AutomationHub standalone | |
| 28 | Tool scenes are standalone | Hand drill, Scanner standalone scenes | |
| 29 | Carriable scenes are standalone | Spare Battery, Head Lamp standalone | |
| 30 | Mining drone standalone scene | CharacterBody3D, DroneManager instances | |
| 31 | All UI panels extracted to subscenes | game_hud.tscn instances all HUD elements | |

---

## UI (M7)

| # | Test | Expected Result | Result |
|---|------|-----------------|--------|
| 32 | Interaction prompt appears on aim | Raycast detects interactable, prompt shows | |
| 33 | Interaction prompt hides when not aiming | No prompt when no target in range | |
| 34 | Hold actions show thick key badge border | Visual distinction for hold vs press | |
| 35 | Compass bar centered at top | Horizontally centered, all labels visible | |
| 36 | Battery bar shows amber warning | Intermediate levels show amber color state | |
| 37 | Inventory ship status icons aligned | Icons vertically centered with bars | |
| 38 | Persistent controls panel visible | Q Ping, I Inventory in bottom-right | |

---

## Audio

_[Add test cases here as audio systems are implemented]_

---

## Performance

_[Add frame rate and memory targets here once established]_
