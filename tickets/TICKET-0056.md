---
id: TICKET-0056
title: "FIX: ship_interior.gd — missing class_name and section ordering violations"
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
tags: [coding-standards, ship-interior]
---

## Summary
`ship_interior.gd` has three coding standard violations found during TICKET-0048 code review:

1. **Missing `class_name`**: The script extends `Node3D` and is NOT an autoload, so it requires `class_name ShipInterior` per coding standards.
2. **Variable in wrong section**: `_player_in_exit_zone` (line 371) is declared inside the Private Methods section instead of the Private Variables section.
3. **Public methods after Private Methods**: `is_player_in_exit_zone()` and `get_nearby_zone_index()` are public methods placed after the Private Methods section header. They should be in the Public Methods section.

## Acceptance Criteria
- [ ] `class_name ShipInterior` added below the docstring comment, above `extends Node3D`
- [ ] `_player_in_exit_zone` variable moved to the Private Variables section (after `_is_player_inside`)
- [ ] `is_player_in_exit_zone()` and `get_nearby_zone_index()` moved to the Public Methods section
- [ ] No functional changes — structural reorder only
- [ ] All code follows `docs/engineering/coding-standards.md`
- [ ] No Godot editor errors or warnings

## Activity Log
- 2026-02-23 [systems-programmer] Created from TICKET-0048 code review (P2)
- 2026-02-23 [gameplay-programmer] Added class_name ShipInterior, moved _player_in_exit_zone to Private Variables section, moved is_player_in_exit_zone() and get_nearby_zone_index() to Public Methods section. DONE
