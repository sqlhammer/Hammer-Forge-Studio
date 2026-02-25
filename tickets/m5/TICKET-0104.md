---
id: TICKET-0104
title: "Bugfix — Add clickable close buttons to all UI menus that show 'ESC to close'"
type: BUGFIX
status: DONE
priority: P3
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-25
updated_at: 2026-02-25
milestone: "M5"
phase: "QA"
depends_on: []
blocks: []
tags: [bugfix, ui, accessibility]
---

## Summary
Several in-game UI menus instruct the player to press ESC to close. Players who do not wish to use the keyboard need a clickable alternative. A close button must be added to every panel that currently shows "ESC to close" or equivalent text.

## Reproduction
1. Open any in-game panel (e.g., module install menu, recycler panel, automation hub panel)
2. Observe that the only dismiss instruction is keyboard-only ("ESC to close" / "[Esc] Cancel")
3. There is no clickable button to close the panel with a mouse

## Expected Behavior
Every panel that shows "ESC to close" or "[Esc] Cancel" must also display a clickable **Close** or **Cancel** button that dismisses the panel. The ESC keybind remains functional alongside the button.

## Fix
- Audit all UI panels in `game/scenes/ui/` and `game/scenes/gameplay/` for "ESC to close" / "[Esc] Cancel" hint text
- Add a `Button` node labelled **Close** (or **Cancel** where context warrants) to each panel
- Wire the button's `pressed` signal to the same close/hide logic triggered by ESC
- Ensure the button is visible and reachable by mouse without overlapping other UI elements

## Acceptance Criteria
- [ ] Every panel with an ESC-to-close instruction also has a clickable Close/Cancel button
- [ ] Clicking the button closes the panel identically to pressing ESC
- [ ] ESC still closes panels (no regression)
- [ ] No layout breakage on any affected panel

## Activity Log
- 2026-02-25 [producer] Created from UAT feedback. Keyboard-only close is not sufficient; mouse users need a clickable target.
- 2026-02-25 [gameplay-programmer] DONE — added Close/Cancel buttons to RecyclerPanel, ModulePlacementUI, TechTreePanel, FabricatorPanel, AutomationHubPanel. ESC still works. Commit 9b6e53d, PR #53.
