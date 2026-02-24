---
id: TICKET-0079
title: "Compliance — update input system design doc for non-pause model"
type: TASK
status: DONE
priority: P2
owner: systems-programmer
created_by: producer
created_at: 2026-02-24
updated_at: 2026-02-24
milestone: "M5"
milestone_gate: "M4"
phase: "Foundation"
depends_on: []
blocks: []
tags: [compliance, pause, input-system, design-docs]
---

## Summary

Per DEC-0001 (decision log), in-world UI menus do not pause the game. The input system design document (`docs/design/systems/input-system.md`) contains a "Pause State" section that defines the old model — when a menu is open, `get_tree().paused = true` and input flows to the menu system. This document must be updated to reflect the correct model: gameplay inputs are suppressed via InputManager; game time continues.

## Files to Update

| File | What to Change |
|------|---------------|
| `docs/design/systems/input-system.md` | Rewrite the "Pause State" section (lines ~207–210) to describe input suppression rather than tree pause; document how InputManager enables/disables gameplay inputs when in-world menus open and close; distinguish between in-world menus (no pause) and abstract system menus (true pause) |

## Acceptance Criteria

- [x] "Pause State" section updated — no longer states "game is paused" when a menu opens
- [x] Updated section describes the two-tier model:
  - **In-world menus** (inventory, machine panels, drone programming, ship management, tech tree): game time continues; player inputs suppressed via InputManager; automated systems run
  - **Abstract menus** (save game, keybindings, system settings): `get_tree().paused = true` is valid here
- [x] If InputManager does not yet document a `set_gameplay_inputs_enabled(bool)` API, add a placeholder noting it will be added in TICKET-0077
- [x] No remaining contradictions between this document and DEC-0001

## Implementation Notes

- Reference `docs/studio/decision-log.md` (DEC-0001) for the authoritative decision text.
- The line `Switching does not reset game state, pause the game, or interrupt ongoing actions` (device switching behavior, line ~126) is correct and does not need to change.
- Search the full document for "pause" before marking DONE to ensure no stray references remain.

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-24 [producer] Created ticket — compliance with DEC-0001
- 2026-02-24 [systems-programmer] Updated Pause State section to two-tier model per DEC-0001; added `set_gameplay_inputs_enabled(bool)` placeholder referencing TICKET-0077; verified no stray contradictions remain
