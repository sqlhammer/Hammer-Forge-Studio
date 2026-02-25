---
id: TICKET-0078
title: "Compliance — update UI wireframes and style guide for non-pause model"
type: TASK
status: DONE
priority: P1
owner: ui-ux-designer
created_by: producer
created_at: 2026-02-24
updated_at: 2026-02-24
milestone: "M5"
milestone_gate: "M4"
phase: "Foundation"
depends_on: []
blocks: [TICKET-0068, TICKET-0069, TICKET-0072]
tags: [compliance, pause, wireframes, design-docs]
---

## Summary

Per DEC-0001 (decision log), in-world UI menus do not pause the game. Multiple wireframe documents and the UI style guide were written under the old pause model. This ticket updates all affected design documents to reflect the correct behavior before the M5 Gameplay phase implementations begin. TICKET-0068, TICKET-0069, and TICKET-0072 are blocked on this ticket — those UIs must not be implemented against stale wireframes.

## Files to Update

| File | What to Change |
|------|---------------|
| `docs/design/wireframes/m3/inventory.md` | Remove the `get_tree().paused = true` implementation note; replace with: inputs suppressed via InputManager on open, restored on close; game time continues |
| `docs/design/wireframes/m4/recycler-panel.md` | Same — remove pause language; remove the `PROCESS_MODE_WHEN_PAUSED` specification; remove the note about Recycler needing special handling to continue while paused |
| `docs/design/wireframes/m4/recycler-machine.md` | Remove the phrase "Player is stationary (game paused)" — replace with "Player is stationary (movement inputs suppressed)" |
| `docs/design/wireframes/m5/fabricator-panel.md` | Remove `get_tree().paused = true` from the implementation spec; replace with input-suppression pattern |
| `docs/design/wireframes/m5/tech-tree.md` | Remove `get_tree().paused = true` and `PROCESS_MODE_WHEN_PAUSED` from implementation spec; replace with input-suppression pattern |
| `docs/design/wireframes/m5/drone-programming.md` | Remove `get_tree().paused = true` from implementation spec; replace with input-suppression pattern; clarify that drones continue to operate while the UI is open |
| `docs/design/ui-style-guide.md` | In the Surface color row, decouple "inventory" from "pause" — inventory is a non-pause overlay; pause menu is a separate category |

## Acceptance Criteria

- [ ] All seven files updated — no remaining references to `get_tree().paused = true/false` in the context of in-world menus
- [ ] Updated wireframes clearly state: game time continues while the panel is open; player movement and action inputs are suppressed
- [ ] Drone programming wireframe explicitly states: active drones continue operating while the UI is open
- [ ] M5 wireframes (fabricator-panel, tech-tree, drone-programming) are consistent with the M3/M4 wireframes after updates — one coherent model across all panels
- [ ] UI style guide distinguishes between non-pause in-world overlays (inventory, machine panels) and true pause overlays (save game, keybindings, system settings)
- [ ] No other wireframe or design doc is left with contradictory pause language — do a search for "paused" across `docs/design/` and address any remaining occurrences

## Implementation Notes

- The correct implementation pattern for all in-world menus is:
  1. On open: call InputManager to suppress gameplay inputs; switch mouse to `MOUSE_MODE_VISIBLE`
  2. On close: call InputManager to restore gameplay inputs; switch mouse to `MOUSE_MODE_CAPTURED`
  3. UI navigation (ui_up/down/left/right, ui_accept, ui_cancel) handled within the panel via `set_input_as_handled()`
  4. No `get_tree().paused`, no `PROCESS_MODE_WHEN_PAUSED`
- Reference `docs/studio/decision-log.md` (DEC-0001) for full decision text and rationale.
- Do not update ticket files (TICKET-0019, TICKET-0028, etc.) — those are historical records.

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-24 [producer] Created ticket — compliance with DEC-0001; blocks TICKET-0068, TICKET-0069, TICKET-0072
- 2026-02-24 [ui-ux-designer] Status → IN_PROGRESS. Auditing all 7 docs for pause language.
- 2026-02-24 [ui-ux-designer] Status → DONE. Commit: 030b95b. All 7 files updated + ship-stats-sidebar.md (additional stale reference found during audit). All get_tree().paused and PROCESS_MODE_WHEN_PAUSED references removed from in-world UI docs; replaced with InputManager input-suppression pattern. ui-style-guide.md Surface row decoupled inventory/machine panels from pause category.
