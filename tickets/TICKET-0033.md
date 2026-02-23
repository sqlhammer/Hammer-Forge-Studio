---
id: TICKET-0033
title: "FIX: scanner.gd uses direct Input API call — route through InputManager"
type: BUGFIX
status: DONE
priority: P2
owner: systems-programmer
created_by: systems-programmer
created_at: 2026-02-23
updated_at: 2026-02-23
milestone: "M3"
depends_on: []
blocks: []
tags: [input, coding-standards, scanner]
---

## Summary
`scanner.gd:82` calls `Input.is_action_just_pressed("scan")` directly, violating the coding standard that all input must route through the `InputManager` autoload. The workaround was used because `InputManager` lacks an `is_action_just_pressed()` method. Fix requires adding the method to `InputManager` and updating `scanner.gd` to use it.

## Root Cause
`InputManager` only exposes `is_action_pressed()` (held state). `scanner.gd` needed a just-pressed check for the scan trigger, so the gameplay programmer fell back to the direct `Input` API.

## Acceptance Criteria
- [ ] `InputManager` exposes `is_action_just_pressed(action: StringName) -> bool`
- [ ] `scanner.gd:82` updated to call `InputManager.is_action_just_pressed("scan")` instead of `Input.is_action_just_pressed("scan")`
- [ ] No other direct `Input.is_action_just_pressed()` calls remain in gameplay scripts
- [ ] All code follows `docs/engineering/coding-standards.md`
- [ ] No Godot editor errors or warnings

## Implementation Notes
- Found during TICKET-0030 code review (P2)
- `InputManager` is the systems-programmer's domain — add the method there, then update scanner.gd
- Search for any other `Input.is_action_just_pressed` usages across the codebase and fix them in the same pass

## Activity Log
- 2026-02-23 [systems-programmer] Created from TICKET-0030 P2 findings
- 2026-02-23 [systems-programmer] Implemented: added `is_action_just_pressed()` to InputManager, updated scanner.gd:82 to route through InputManager, verified no other direct `Input.is_action_just_pressed` calls in gameplay scripts
