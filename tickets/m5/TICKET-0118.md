---
id: TICKET-0118
title: "Bugfix — Ship interior supports only 2 module zones; Automation Hub has nowhere to be placed"
type: BUGFIX
status: DONE
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-25
updated_at: 2026-02-25
milestone: "M5"
phase: "QA"
depends_on: []
blocks: []
tags: [bugfix, ship-interior, module-zones, automation-hub, blocking]
---

## Summary
The ship interior greybox (`ship_interior.gd`) hard-codes exactly two module placement zones (Zone A and Zone B). With the Recycler occupying zone 0 and the Fabricator occupying zone 1, `get_first_empty_zone()` returns -1 when the player attempts to place the Automation Hub. The hub is never placed in the world and cannot be tested.

This is distinct from TICKET-0110 (which fixed the module *installation* validation gate). The Automation Hub can now be installed via the module manager, but the ship interior has no physical slot to render it.

## Root Cause
In `game/scripts/gameplay/ship_interior.gd`:

- `_zone_occupied: Array[bool] = [false, false]` — capped at 2
- `_zone_module_nodes: Array[Node3D] = [null, null]` — capped at 2
- `_build_module_zones()` iterates `range(2)` — only 2 zone markers and `Area3D` triggers built
- `place_module_in_zone()` uses `ZONE_A_CENTER if zone_index == 0 else ZONE_B_CENTER` — index 2 maps to Zone B incorrectly
- No `ZONE_C_CENTER` constant exists

## Fix

### 1. Add Zone C and rebalance positions
The bay is 10 units wide (`BAY_WIDTH = 10.0`) and zone size is 3 units (`ZONE_SIZE = 3.0`). Three zones at x = -3.0, 0.0, +3.0 fit cleanly with 0.5 units of margin on each side:

```gdscript
const ZONE_A_CENTER := Vector3(-3.0, 0.0, -1.0)
const ZONE_B_CENTER := Vector3(0.0, 0.0, -1.0)
const ZONE_C_CENTER := Vector3(3.0, 0.0, -1.0)
```

### 2. Update zone arrays to size 3
```gdscript
var _zone_occupied: Array[bool] = [false, false, false]
var _zone_module_nodes: Array[Node3D] = [null, null, null]
```

### 3. Update `_build_module_zones()` to iterate over 3 zones
Replace the hardcoded zone center lookup with an array lookup so the loop generalises:
```gdscript
var zone_centers: Array[Vector3] = [ZONE_A_CENTER, ZONE_B_CENTER, ZONE_C_CENTER]
for i: int in range(3):
    ...
```

### 4. Update `place_module_in_zone()` to use array lookup
Replace the `if zone_index == 0 else` branch with:
```gdscript
var zone_centers: Array[Vector3] = [ZONE_A_CENTER, ZONE_B_CENTER, ZONE_C_CENTER]
var zone_center: Vector3 = zone_centers[zone_index]
```

## Acceptance Criteria
- [ ] Ship interior renders three distinct teal floor zone markers when entered
- [ ] Recycler occupies zone 0 (left), Fabricator occupies zone 1 (centre), Automation Hub occupies zone 2 (right)
- [ ] `get_first_empty_zone()` returns 2 when only zones 0 and 1 are filled
- [ ] `get_first_empty_zone()` returns -1 only when all three zones are filled
- [ ] `place_module_in_zone(2, node)` correctly positions the module at Zone C
- [ ] `get_zone_count()` returns 3
- [ ] No visual clipping between zone markers at the new positions
- [ ] No regression on zone 0 (Recycler) or zone 1 (Fabricator) placement or interaction
- [ ] All existing unit tests for `ShipInterior` pass; add or update tests for the 3-zone case
- [ ] All code follows `docs/engineering/coding-standards.md`

## Activity Log
- 2026-02-25 [producer] Created ticket — blocking Automation Hub end-to-end QA
- 2026-02-25 [gameplay-programmer] DONE — Added ZONE_C_CENTER, expanded zone arrays to 3, updated _build_module_zones() and place_module_in_zone() with array lookups, rebalanced zone positions to -3.0/0.0/+3.0. Added test_ship_interior_unit.gd with 15 unit tests. Commit 3cecac4, PR #55 merged.
