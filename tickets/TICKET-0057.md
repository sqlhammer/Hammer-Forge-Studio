---
id: TICKET-0057
title: "FIX: threshold inconsistency between ShipGlobalsHUD and ShipStatsSidebar"
type: BUGFIX
status: DONE
priority: P2
owner: gameplay-programmer
created_by: systems-programmer
created_at: 2026-02-23
updated_at: 2026-02-23
milestone: "M4"
depends_on: []
blocks: []
tags: [coding-standards, hud, inventory, ship-state]
---

## Summary
`ShipGlobalsHUD` and `ShipStatsSidebar` define their own threshold constants with different values AND different comparison operators for the same state transitions. This causes inconsistent color/alert behavior between the two UI elements at boundary values.

### Constant Differences

| Variable | HUD Constant | HUD Operator | Sidebar Constant | Sidebar Operator |
|----------|-------------|--------------|-----------------|-----------------|
| Power critical | 19.0 | `<=` | 20.0 | `<` |
| Integrity critical | 29.0 | `<=` | 30.0 | `<` |
| Heat hot | 76.0 | `>=` | 75.0 | `>` |
| Oxygen critical | 19.0 | `<=` | 20.0 | `<` |

Additionally, the HUD defines `POWER_LOW` (49.0) and `INTEGRITY_DAMAGED` (74.0) with `<=`, while the sidebar uses hardcoded `50.0` and `75.0` with `<` in the comparison functions.

### Expected Behavior (per wireframe spec)
Both UIs should agree on state boundaries: Power critical 0-19%, low 20-49%, healthy 50-100%, etc. The wireframe defines these as integer percentage ranges.

## Acceptance Criteria
- [ ] Both scripts use identical threshold constants and comparison operators
- [ ] Option A: Extract shared constants to a common location (e.g., ShipState or a shared constants file)
- [ ] Option B: Duplicate constants but ensure values and operators match exactly
- [ ] Verify all four variables (Power, Integrity, Heat, Oxygen) produce identical color states in both UIs for the same input value
- [ ] No functional regression
- [ ] All code follows `docs/engineering/coding-standards.md`

## Activity Log
- 2026-02-23 [systems-programmer] Created from TICKET-0048 code review (P2)
- 2026-02-23 [gameplay-programmer] Unified sidebar thresholds with HUD: constants (19.0/29.0/76.0/19.0), operators (<=/>= matching HUD), replaced hardcoded values with named constants. DONE
