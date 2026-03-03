---
id: TICKET-0277
title: "M10 Input — Assign gamepad A to 'jump', LB to 'ping'; rename action 'scan' → 'ping'"
type: TASK
status: OPEN
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-03-03
updated_at: 2026-03-03
milestone: "M10"
phase: "Foundation"
depends_on: [TICKET-0276]
blocks: []
tags: [input, gamepad, scanner, naming]
---

## Summary

Assign `JOY_BUTTON_A` to the `jump` action and `JOY_BUTTON_LEFT_SHOULDER` to the `scan`
action. Also rename the `scan` input action to `ping` across the entire codebase — the
in-game feature is called "ping" and the action name should match to avoid confusion with
scanning/analyzing resources via the `interact` action.

---

## Acceptance Criteria

### InputManager.gd — Binding changes
- [ ] Add `JOY_BUTTON_A` to the `jump` action:
  ```gdscript
  _add_action_if_missing("jump", [KEY_SPACE], [], [JOY_BUTTON_A])
  ```
- [ ] Rename action `scan` → `ping` and assign `JOY_BUTTON_LEFT_SHOULDER`:
  ```gdscript
  _add_action_if_missing("ping", [KEY_Q], [], [JOY_BUTTON_LEFT_SHOULDER])
  ```
- [ ] Update `GAMEPLAY_ACTIONS` array: replace `"scan"` with `"ping"`

### scanner.gd
- [ ] Update `_check_ping_input()` to use `"ping"` instead of `"scan"`:
  ```gdscript
  if InputManager.is_action_just_pressed("ping") and _ping_cooldown_timer <= 0.0:
  ```

### interaction_prompt_hud.gd
- [ ] Update `_persistent_controls` registration: replace key `"scan"` with `"ping"`:
  ```gdscript
  _persistent_controls["ping"] = $PersistentControls/ControlsList/PingRow/KeyLabel as Label
  ```

### Full codebase string search
- [ ] Search all `.gd` files for the string `"scan"` used as an input action name
      (i.e. passed to `InputManager.*` or `Input.*` methods) — update all occurrences to `"ping"`
- [ ] Do NOT rename scanner system variables, signals, method names, or comments that use
      "scan" in the context of the scanning/analysis feature — only the input action string

### No Regressions
- [ ] Pressing Space still triggers `jump` on keyboard
- [ ] Pressing A on gamepad triggers `jump`
- [ ] Pressing Q still triggers `ping` on keyboard
- [ ] Pressing LB (Left Bumper) on gamepad triggers `ping`
- [ ] Ping ring fires correctly when ping input is received

---

## Implementation Notes

The internal scanner system already uses "ping" terminology throughout (`_do_ping()`,
`ping_completed` signal, `_spawn_ping_ring()`, etc.). The action name `"scan"` was a
legacy holdover. This rename aligns the input action name with the in-game feature name.

`JOY_BUTTON_A` will now be mapped to both `jump` and `ui_accept`. This is intentional:
`ui_accept` fires in UI context; `jump` fires in gameplay context. The `set_gameplay_inputs_enabled`
mechanism in InputManager suppresses `jump` when UI is open, preventing conflict.

`JOY_BUTTON_LEFT_SHOULDER` = Godot constant `JOY_BUTTON_LEFT_SHOULDER` (Left Bumper / LB).

---

## Handoff Notes

(Leave blank until handoff occurs.)

---

## Activity Log

- 2026-03-03 [producer] Created ticket — M10 gamepad: A→jump, LB→ping, rename scan→ping
