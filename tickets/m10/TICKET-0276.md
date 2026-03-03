---
id: TICKET-0276
title: "M10 Input — Reassign gamepad 'interact' from A to X; audit UI for hardcoded button labels"
type: TASK
status: DONE
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-03-03
updated_at: 2026-03-03
milestone: "M10"
phase: "Foundation"
depends_on: []
blocks: [TICKET-0277, TICKET-0278]
tags: [input, gamepad, ui, interaction-prompt]
---

## Summary

The `interact` action is currently mapped to `JOY_BUTTON_A` on gamepad. Reassign it to
`JOY_BUTTON_X`. Audit all UI widgets and scripts for any hardcoded gamepad button strings
(e.g. literal `"A"`, `"X"`) and confirm they dynamically derive labels from InputMap instead.

---

## Acceptance Criteria

### InputManager.gd
- [x] Change `interact` gamepad binding from `JOY_BUTTON_A` to `JOY_BUTTON_X`:
  ```gdscript
  _add_action_if_missing("interact", [KEY_E], [], [JOY_BUTTON_X])
  ```
- [x] `ui_accept` remains on `JOY_BUTTON_A` — do not change it (standard menu confirm)

### UI Audit
- [x] Confirm `interaction_prompt_hud.gd` derives button labels via `InputMap.action_get_events()`
      and does NOT hardcode `"A"` or `"X"` for the interact action — it already does this;
      verify no regression
- [x] Search all `.gd` and `.tscn` files for hardcoded strings `"A"`, `"X"`, `"LB"`, `"RB"`
      used as gamepad button labels. Replace any found with dynamic lookups
- [x] `deposit.gd` `_get_action_key_label` and equivalent methods must also derive labels
      dynamically — confirm no hardcoded strings for gamepad buttons

### No Regressions
- [x] Pressing E on keyboard still triggers `interact`
- [x] Pressing X on gamepad now triggers `interact`
- [x] Pressing A on gamepad no longer triggers `interact`
- [x] HUD displays "X" (not "A") next to the interact prompt when on gamepad

---

## Implementation Notes

`interaction_prompt_hud.gd` already uses `InputMap.action_get_events(action)` to read
button labels dynamically — this is the correct pattern. The audit is primarily to ensure
no other widget or script bypasses this by hardcoding button names.

`ui_accept` (used for UI menu confirm) is deliberately kept on `JOY_BUTTON_A` — this is
separate from the gameplay `interact` action and should not change.

---

## Handoff Notes

- Modified `game/autoloads/InputManager.gd` line 152: changed `interact` gamepad binding from `JOY_BUTTON_A` to `JOY_BUTTON_X`
- `ui_accept` remains on `JOY_BUTTON_A` (line 167) — unchanged
- `interaction_prompt_hud.gd`: confirmed dynamic label resolution via `InputMap.action_get_events()` → `_joy_button_name()` lookup table — no hardcoded action-to-label mappings
- `deposit.gd`: confirmed `_get_action_key_label()` uses `InputMap.action_get_events()` dynamically; `get_interaction_prompt()` passes action names resolved by HUD
- Grep audit of all `.gd` and `.tscn` files: no hardcoded gamepad button label strings found outside the `_joy_button_name()` constant-to-string lookup table (which is the correct pattern)

---

## Activity Log

- 2026-03-03 [producer] Created ticket — M10 gamepad input: reassign interact A→X, UI audit
- 2026-03-03 [gameplay-programmer] Starting work
- 2026-03-03 [gameplay-programmer] DONE — commit d383af1, PR https://github.com/sqlhammer/Hammer-Forge-Studio/pull/302
