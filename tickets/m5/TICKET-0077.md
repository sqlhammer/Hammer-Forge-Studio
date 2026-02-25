---
id: TICKET-0077
title: "Compliance — remove game pause from in-world UI panels"
type: BUGFIX
status: DONE
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-24
updated_at: 2026-02-24
milestone: "M5"
milestone_gate: "M4"
phase: "Foundation"
depends_on: []
blocks: [TICKET-0075]
tags: [compliance, pause, ui, input]
---

## Summary

Per DEC-0001 (decision log), in-world UI menus do not pause the game. Three implemented UI scripts and one test world workaround currently call `get_tree().paused = true/false`, which is incorrect. This ticket removes the pause calls and replaces them with an input-suppression approach: when a menu opens, gameplay inputs are disabled via `InputManager`; when the menu closes, they are restored. Automated systems (Recycler, future machines, drones) run uninterrupted.

## Files to Change

| File | Change |
|------|--------|
| `game/scripts/ui/inventory_screen.gd` | Remove `get_tree().paused = true/false`; suppress gameplay inputs via InputManager on open/close; remove `PROCESS_MODE_WHEN_PAUSED` settings (no longer needed) |
| `game/scripts/ui/recycler_panel.gd` | Same as above |
| `game/scripts/ui/module_placement_ui.gd` | Same as above |
| `game/scripts/levels/test_world.gd` | Remove `Recycler.process_mode = PROCESS_MODE_ALWAYS` — this workaround is obsolete; Recycler reverts to default `PROCESS_MODE_INHERIT` |

## Acceptance Criteria

- [ ] `inventory_screen.gd`: no calls to `get_tree().paused`; opening inventory does not halt game time
- [ ] `recycler_panel.gd`: no calls to `get_tree().paused`; opening panel does not halt Recycler job progress or any other system
- [ ] `module_placement_ui.gd`: no calls to `get_tree().paused`; module placement UI does not halt game time
- [ ] `test_world.gd`: `PROCESS_MODE_ALWAYS` override removed from Recycler; Recycler runs at default process mode
- [ ] All three UI panels still fully suppress player movement and action inputs while open (player cannot walk, scan, mine, or interact with the world while a menu is open)
- [ ] Mouse mode still switches to `MOUSE_MODE_VISIBLE` on open and `MOUSE_MODE_CAPTURED` on close
- [ ] UI navigation inputs (ui_up, ui_down, ui_left, ui_right, ui_accept, ui_cancel) still handled correctly within each panel
- [ ] Existing unit tests pass (284 M1–M4 baseline must hold)
- [ ] No regressions to Recycler job processing, inventory slot state, or module installation flow

## Implementation Notes

- The InputManager autoload is at `game/autoload/InputManager.gd` — use it (or an equivalent mechanism) to block gameplay inputs while a menu is open. If InputManager does not yet have a `set_gameplay_inputs_enabled(bool)` method, add one as part of this ticket.
- `PROCESS_MODE_WHEN_PAUSED` settings on UI CanvasLayer nodes and their containers were only needed to survive the `get_tree().paused` call. Once the pause is removed, these should be removed or left at the default `PROCESS_MODE_INHERIT`.
- Do not change how `set_input_as_handled()` is used — UI input consumption within panels is correct and should remain.
- Reference `docs/studio/decision-log.md` (DEC-0001) for full rationale.

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-24 [producer] Created ticket — compliance with DEC-0001
- 2026-02-25 [gameplay-programmer] DONE — commit 8aef9b4, PR #38 merged. Added set_gameplay_inputs_enabled() to InputManager; removed all get_tree().paused calls and PROCESS_MODE overrides from UI panels and test_world.
