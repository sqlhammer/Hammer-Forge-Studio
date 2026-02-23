---
id: TICKET-0034
title: "FIX: InputManager use_tool registers mouse button as InputEventKey"
type: BUGFIX
status: DONE
priority: P2
owner: systems-programmer
created_by: systems-programmer
created_at: 2026-02-23
updated_at: 2026-02-23
milestone: "M3"
depends_on: []
blocks: [TICKET-0035]
tags: [input, coding-standards, inputmanager]
---

## Summary
`InputManager:123` registers `MOUSE_BUTTON_LEFT` as a keycode on an `InputEventKey` instead of using `InputEventMouseButton`. This is incorrect — mouse buttons must use `InputEventMouseButton`. `mining.gd:64-76` works around this deficiency by adding the input event manually at runtime. Fix: `InputManager` must natively support mouse button input event registration.

## Root Cause
`InputManager` was built with keyboard and gamepad inputs in mind. Mouse button support was not implemented, so the gameplay programmer added a runtime workaround in `mining.gd`.

## Acceptance Criteria
- [ ] `InputManager` correctly registers `MOUSE_BUTTON_LEFT` (and any other mouse buttons) using `InputEventMouseButton`
- [ ] The incorrect `InputEventKey` registration for mouse buttons is removed
- [ ] Mouse button actions are registered at startup via `InputManager`, not at runtime in gameplay scripts
- [ ] All code follows `docs/engineering/coding-standards.md`
- [ ] No Godot editor errors or warnings

## Implementation Notes
- Found during TICKET-0030 code review (P2)
- This is a prerequisite for TICKET-0035 — `mining.gd` cannot remove its runtime workaround until `InputManager` handles mouse buttons correctly
- Verify no other actions incorrectly use `InputEventKey` for mouse buttons

## Activity Log
- 2026-02-23 [systems-programmer] Created from TICKET-0030 P2 findings
- 2026-02-23 [systems-programmer] Implemented: added `mouse_buttons` parameter to `_add_action_if_missing()`, use_tool now correctly registers `InputEventMouseButton` for `MOUSE_BUTTON_LEFT`
