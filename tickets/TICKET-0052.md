---
id: TICKET-0052
title: "BUG: module_manager.gd cannot resolve ShipState autoload at parse time"
type: BUG
status: OPEN
priority: P1
owner: systems-programmer
created_by: qa-engineer
created_at: 2026-02-23
updated_at: 2026-02-23
milestone: "M4"
depends_on: []
blocks: [TICKET-0049]
tags: [bug, autoload, parse-error, M4, blocking]
---

## Summary
`module_manager.gd` fails to parse because the `ShipState` autoload identifier is not resolved at compile time. This causes `ModuleManager` and `Recycler` autoloads to fail, which blocks ALL scene execution including the test runner. No scenes can run in the current state.

## Error Details
```
res://scripts/systems/module_manager.gd:38 - Parse Error: Identifier "ShipState" not declared in the current scope.
res://scripts/systems/module_manager.gd:57 - Parse Error: Identifier "ShipState" not declared in the current scope.
res://scripts/systems/module_manager.gd:81 - Parse Error: Identifier "ShipState" not declared in the current scope.
modules/gdscript/gdscript.cpp:3041 - Failed to load script "res://scripts/systems/module_manager.gd" with error "Parse error".
```

## Root Cause Analysis
`ship_state.gd` has `class_name ShipStateType` and is registered as autoload `ShipState`. The code in `module_manager.gd` references the autoload singleton name `ShipState` (e.g., `ShipState.would_exceed_capacity()`). Godot 4.5.1 cannot resolve this identifier at parse time.

Other autoloads (`Global`, `PlayerInventory`) referenced by the same script resolve fine, suggesting a specific issue with how `ShipState` registers. The autoload ordering in project.godot places `ShipState` before `ModuleManager`, so load order should not be the cause.

## Cascade Effect
1. `module_manager.gd` fails to parse -> `ModuleManager` autoload fails to instantiate
2. `recycler.gd` references `ModuleManager` -> also fails to parse
3. Both autoloads crash -> all scenes fail to load -> test runner cannot execute

## Acceptance Criteria
- [ ] `module_manager.gd` parses without errors
- [ ] `ShipState` autoload is accessible from `module_manager.gd` at runtime
- [ ] All scenes load successfully (test runner, test_world, etc.)
- [ ] Full test suite runs and all existing tests pass

## Implementation Notes
- Possibly related to the M3 P1 finding (TICKET-0032): class_name/autoload conflicts. The same pattern was fixed for `SuitBattery` -> `SuitBatteryType` and `DepositRegistry` -> `DepositRegistryType`.
- Consider whether `ShipState` as autoload name collides with GDScript internal resolution in Godot 4.5.1
- Alternative fix: reference ShipState via `get_node("/root/ShipState")` or use the class_name `ShipStateType` for type checks

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-23 [qa-engineer] Created from TICKET-0051 regression testing — parse errors block all scene execution
