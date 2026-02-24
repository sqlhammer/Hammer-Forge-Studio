---
id: TICKET-0080
title: "Compliance — update ship machine SOP for non-pause model"
type: TASK
status: OPEN
priority: P2
owner: producer
created_by: producer
created_at: 2026-02-24
updated_at: 2026-02-24
milestone: "M5"
milestone_gate: "M4"
phase: "Foundation"
depends_on: []
blocks: []
tags: [compliance, pause, sop, design-docs]
---

## Summary

Per DEC-0001 (decision log), in-world UI menus do not pause the game. The Ship Machine SOP (`docs/studio/sop-ship-machine.md`) codifies `Recycler.process_mode = ALWAYS` as the canonical pattern for all future machines — this was a workaround to keep machines running through an incorrect tree pause. Now that the pause is removed, this workaround is obsolete and the SOP must be corrected so future machines are not implemented with it.

## Files to Update

| File | What to Change |
|------|---------------|
| `docs/studio/sop-ship-machine.md` | Remove the `PROCESS_MODE_ALWAYS` pattern note; replace with the correct model: machine interaction panels suppress player inputs via InputManager, game time continues, machines run at default `PROCESS_MODE_INHERIT`; add a reference to DEC-0001 |

## Acceptance Criteria

- [ ] `PROCESS_MODE_ALWAYS` removed as a required pattern for machine modules
- [ ] SOP updated to state: machine panels open without pausing the game; player inputs are suppressed while the panel is open; machines process at default `PROCESS_MODE_INHERIT`
- [ ] SOP references `docs/studio/decision-log.md` (DEC-0001) for the authoritative decision
- [ ] No remaining references in the SOP that imply or instruct `get_tree().paused = true` for machine panels
- [ ] SOP search for "pause", "paused", "PROCESS_MODE_ALWAYS" — all instances reviewed and corrected

## Implementation Notes

- The Recycler reference example in the SOP (M4) should note that TICKET-0077 corrects the M4 implementation — the Recycler's `PROCESS_MODE_ALWAYS` override in `test_world.gd` is removed as part of that ticket.
- The Fabricator (M5) is the new canonical reference machine — document it as the first machine built to the correct model.

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-24 [producer] Created ticket — compliance with DEC-0001
