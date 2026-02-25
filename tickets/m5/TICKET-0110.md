---
id: TICKET-0110
title: "Bugfix — Fabricator and Automation Hub cannot be installed despite meeting resource and power requirements"
type: BUGFIX
status: TODO
priority: P1
owner: systems-programmer
created_by: producer
created_at: 2026-02-25
updated_at: 2026-02-25
milestone: "M5"
phase: "QA"
depends_on: []
blocks: []
tags: [bugfix, fabricator, automation-hub, module-manager, critical]
---

## Summary
The module installation menu shows "Cannot install — check resources and power" for both the Fabricator and Automation Hub, even when the player has sufficient resources and power available. The UI correctly shows the requirements are met (e.g., "Cost: 20 Metal (have 23)" and "Power: 10 / 20 available") but installation is still refused.

## Screenshots
- Fabricator: Cost 20 Metal (have 23), Power 10/20 available — **Cannot install**
- Automation Hub: Cost 30 Metal (have 37), Power 15/20 available — **Cannot install**

## Reproduction
1. Collect at least 20 Metal and ensure ship power is sufficient
2. Open the module install menu
3. Select Fabricator (Tier 1)
4. Observe — "Cannot install — check resources and power" despite meeting all listed requirements
5. Same result for Automation Hub

## Root Cause (Suspected)
The installation validation logic is likely checking a different condition than what is displayed:
- Power check may compare against total ship power rather than available power (or vice versa)
- Resource check may be reading from the wrong inventory slot or using the wrong resource type key
- The tech tree unlock check (`TechTree.is_unlocked()`) may be failing silently — the module may require a tech tree node to be unlocked before it can be installed, and that unlock has not happened yet
- There may be a mismatch between the resource type string used in the cost definition and the key in the inventory

## Fix
- Trace the install validation path in `ModuleManager` (or equivalent) and identify the exact condition causing the refusal
- Confirm whether a tech tree unlock is a prerequisite for installation and whether that check is surfaced in the UI
- If the tech tree is the blocker, either fix the unlock flow or add a clear "Requires unlock: [node name]" message in the UI
- If it is a resource/power comparison bug, fix the comparison logic
- Ensure the UI error message accurately reflects the actual blocking condition

## Acceptance Criteria
- [ ] Fabricator can be installed when the player has ≥ 20 Metal and sufficient power
- [ ] Automation Hub can be installed when prerequisites are met
- [ ] If a tech tree unlock is required, the UI displays that requirement clearly (not just "check resources and power")
- [ ] No regression on modules that were previously installable

## Activity Log
- 2026-02-25 [producer] Created from UAT feedback. Critical — blocks fabricator and drone automation progression entirely. Screenshots confirm displayed requirements are met but install is refused.
