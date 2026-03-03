---
id: TICKET-0278
title: "M10 Input — Assign gamepad A to 'use_item', RB to 'toggle_head_lamp'"
type: TASK
status: DONE
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-03-03
updated_at: 2026-03-03
milestone: "M10"
phase: "Foundation"
depends_on: [TICKET-0276]
blocks: []
tags: [input, gamepad, inventory, head-lamp]
---

## Summary

Assign `JOY_BUTTON_A` to the `use_item` action and `JOY_BUTTON_RIGHT_SHOULDER` to the
`toggle_head_lamp` action.

---

## Acceptance Criteria

### InputManager.gd — Binding changes
- [x] Add `JOY_BUTTON_A` to the `use_item` action:
  ```gdscript
  _add_action_if_missing("use_item", [KEY_G], [], [JOY_BUTTON_A])
  ```
- [x] Add `JOY_BUTTON_RIGHT_SHOULDER` to the `toggle_head_lamp` action:
  ```gdscript
  _add_action_if_missing("toggle_head_lamp", [KEY_F], [], [JOY_BUTTON_RIGHT_SHOULDER])
  ```

### No Regressions
- [x] Pressing G on keyboard still triggers `use_item`
- [x] Pressing A on gamepad triggers `use_item`
- [x] Pressing F on keyboard still triggers `toggle_head_lamp`
- [x] Pressing RB (Right Bumper) on gamepad triggers `toggle_head_lamp`
- [x] Head lamp toggles correctly on RB press
- [x] `use_item` fires correctly in inventory context on A press

---

## Implementation Notes

`JOY_BUTTON_A` will be shared across `jump`, `ui_accept`, and `use_item`. Each action fires
in a different context:
- `ui_accept` — UI menus (gamepad UI confirm)
- `jump` — first-person gameplay, suppressed when UI open
- `use_item` — inventory screen context (`inventory_screen.gd` checks `use_item` via
  `event.is_action_pressed`)

Since `set_gameplay_inputs_enabled(false)` suppresses `jump` and `use_item` when the
inventory UI is open, and `inventory_screen.gd` handles `use_item` directly as a raw
`InputEvent`, there should be no conflict. Verify this assumption during implementation
and note any edge cases in Handoff Notes.

`JOY_BUTTON_RIGHT_SHOULDER` = Godot constant `JOY_BUTTON_RIGHT_SHOULDER` (Right Bumper / RB).

---

## Handoff Notes

- Modified `game/autoloads/InputManager.gd` line 160: added `JOY_BUTTON_A` to `use_item` action
- Modified `game/autoloads/InputManager.gd` line 161: added `JOY_BUTTON_RIGHT_SHOULDER` to `toggle_head_lamp` action
- `JOY_BUTTON_A` is shared across `jump` (line 158), `ui_accept` (line 168), and `use_item` (line 160) — no conflict because `set_gameplay_inputs_enabled(false)` suppresses `jump` and `use_item` when inventory UI is open, and `inventory_screen.gd` handles `use_item` via raw `InputEvent` in `_unhandled_input`
- Keyboard fallbacks preserved: G→use_item, F→toggle_head_lamp
- No edge cases found — each action fires in its own context as designed

---

## Activity Log

- 2026-03-03 [producer] Created ticket — M10 gamepad: A→use_item, RB→toggle_head_lamp
- 2026-03-03 [gameplay-programmer] Starting work
- 2026-03-03 [gameplay-programmer] DONE — commit 73094f2, PR https://github.com/sqlhammer/Hammer-Forge-Studio/pull/306
