---
id: TICKET-0155
title: "Bugfix — missing interaction prompt at ship interior exit"
type: BUGFIX
status: OPEN
priority: P2
owner: gameplay-programmer
created_by: studio-head
created_at: 2026-02-26
updated_at: 2026-02-26
milestone: "M7"
phase: "QA"
depends_on: []
blocks: []
tags: [interaction-prompt, hud, ship-interior, exit, bugfix, p2]
---

## Summary

When the player approaches the ship interior exit, no interaction prompt appears. The player receives no visual feedback that they can press the mapped key (e.g. `[E] Exit Ship`) to leave the ship. The interaction prompt HUD system (D-016, implemented in M7) should be displaying this prompt — either the exit trigger zone is not wired to the prompt system, or the prompt data is missing for the exit interactable.

## Steps to Reproduce

1. Enter the ship interior
2. Walk toward the ship exit (door/hatch/exit trigger area)
3. Observe the interaction prompt HUD area — no prompt appears
4. Pressing the interact key (default: E) may or may not trigger the exit depending on whether the trigger itself is functional

## Expected Behavior

When the player enters the exit trigger zone, the interaction prompt HUD displays:

```
[E] Exit Ship
```

(where `E` is replaced with whatever key/button is currently mapped to the interact action, resolved via `InputManager`)

The prompt disappears when the player leaves the trigger zone.

## Actual Behavior

No interaction prompt is shown near the ship exit. The player has no contextual feedback that an exit action is available.

## Acceptance Criteria

- [ ] Ship interior exit trigger zone is wired to the interaction prompt system — entering the zone shows the prompt, leaving hides it
- [ ] Prompt text reads "Exit Ship" (or equivalent per design) with the correct mapped key displayed dynamically via `InputManager`
- [ ] Key label updates correctly if the player remaps the interact action mid-session
- [ ] Prompt does not appear outside the trigger zone boundary
- [ ] Behavior is consistent with other interaction prompts in the game (e.g., deposit scan prompt)
- [ ] Full test suite passes after fix

## Implementation Notes

- The interaction prompt HUD was implemented as part of D-016 in M7 — check the relevant scene and script for how other interactables register their prompt (likely an `Area3D` with `body_entered` / `body_exited` signals connected to the prompt system)
- The ship exit node in the interior scene likely needs an `Area3D` trigger added (or an existing one wired up) with the correct interaction data (action name + label string)
- Verify the exit trigger exists in the scene tree at all — it may have been omitted during the M7 scene architecture refactor (TICKET-0122–0128)
- Use the same pattern as working interaction prompts rather than inventing a new approach

## Activity Log

- 2026-02-26 [studio-head] Created — missing prompt observed during post-M7 playtesting before QA sign-off
