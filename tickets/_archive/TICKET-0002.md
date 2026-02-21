---
id: TICKET-0002
title: "Implement InputManager autoload for keyboard and gamepad"
type: TASK
status: DONE
priority: P1
owner: systems-programmer
created_by: producer
created_at: 2026-02-21
updated_at: 2026-02-21
milestone: "M1"
depends_on: [TICKET-0001]
blocks: [TICKET-0003, TICKET-0004]
tags: [input-system, autoload]
---

## Summary
Implement the `InputManager` autoload that centralizes all input handling. This system will normalize keyboard and gamepad input, manage input events, and provide a clean interface for controllers to query input state. Must follow coding standards and support the input design from TICKET-0001.

## Acceptance Criteria
- [x] `res://autoloads/InputManager.gd` created with `class_name InputManager`
- [x] Keyboard action bindings configured in Godot project settings (18 actions at runtime)
- [x] Gamepad input mapping implemented (analog sticks, buttons, triggers)
- [x] Input state queries work: `is_action_pressed()`, `get_action_strength()`, `get_analog_input()`, `get_trigger_input()`
- [x] Support both first-person and third-person input contexts (separate action sets)
- [x] All code follows `docs/engineering/coding-standards.md` (PascalCase class, snake_case functions, type hints, docstrings)
- [x] `res://project.godot` updated to register InputManager as autoload
- [x] Debug logging implemented via `Global.log()`
- [x] Standalone test scene created: `res://test/test_input_manager.tscn` (tested and verified)
- [x] `docs/engineering/architecture.md` updated with InputManager and Global documentation

## Implementation Notes
- Reference `docs/design/input-system.md` from TICKET-0001
- Use Godot's `Input` singleton to query system input
- Implement input normalization for gamepad (e.g., dead zones, axis mapping)
- InputManager must be accessible via `InputManager.` from any script
- Scene should be testable independently per coding standards

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-21 [producer] Created ticket; depends on TICKET-0001
- 2026-02-21 [systems-programmer] Started implementation
- 2026-02-21 [systems-programmer] Created `res://autoloads/Global.gd` - Global utility autoload
- 2026-02-21 [systems-programmer] Created `res://autoloads/InputManager.gd` with full implementation:
  - Keyboard and gamepad input normalization
  - Dead zone handling for analog sticks and triggers
  - Input context awareness (keyboard/gamepad switching)
  - Input device detection with debounce
  - Query methods: `is_action_pressed()`, `get_action_strength()`, `get_analog_input()`, `get_trigger_input()`
  - Support for both first-person and third-person contexts
  - 18 input actions configured (movement, camera, actions, ship controls)
  - Debug logging via `Global.log()`
- 2026-02-21 [systems-programmer] Updated `res://project.godot` to register Global and InputManager autoloads
- 2026-02-21 [systems-programmer] Created test scene `res://test/test_input_manager.tscn` with real-time input state display
- 2026-02-21 [systems-programmer] All acceptance criteria met; test scene verified
- 2026-02-21 [systems-programmer] Status changed to DONE
- 2026-02-21 [producer] Archived
