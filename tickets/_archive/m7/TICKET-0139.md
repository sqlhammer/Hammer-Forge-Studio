---
id: TICKET-0139
title: "Bugfix — inventory ship status icons misaligned with bars"
type: BUGFIX
status: DONE
priority: P2
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-26
updated_at: 2026-02-26
milestone: "M7"
phase: "QA"
depends_on: []
blocks: [TICKET-0130]
tags: [hud, inventory, ui, bugfix, p2]
---

## Summary

When the inventory screen is open, the icon column in the SHIP status panel (Power ⚡, O2, Temperature, Integrity) is vertically misaligned with its corresponding progress bars. The icons appear offset relative to their bar rows — they do not sit centered alongside the bar they label.

## Steps to Reproduce

1. Launch the game
2. Press `I` to open the Inventory screen
3. Observe the SHIP status panel (top-right of the inventory UI)

## Expected Behavior

Each status icon (Power, O2, Temperature, Integrity) is vertically centered on the same row as its progress bar and percentage label.

## Actual Behavior

The icon column is offset — icons do not align with their corresponding bars. The icon column appears shifted up or down relative to the bar/label rows.

## Acceptance Criteria

- [x] All 4 ship status icons are vertically centered alongside their respective bars in the SHIP panel
- [x] Alignment is consistent at all supported resolutions

## Implementation Notes

- Likely a container/alignment issue in the ship status HUD scene — check `VBoxContainer`, `HBoxContainer`, or `GridContainer` vertical alignment settings on the icon nodes
- The icon column may be in a separate container with a different row height or `size_flags` than the bar column

## Activity Log

- 2026-02-26 [producer] Created — visual regression found during M7 QA review
- 2026-02-26 [gameplay-programmer] IN_PROGRESS — Starting work. Root cause: icon and bar children in `_create_variable_row` lack `size_flags_vertical = SIZE_SHRINK_CENTER`, causing them to stretch instead of vertically centering within HBoxContainer rows.
- 2026-02-26 [gameplay-programmer] DONE — Fix committed (d6923c5), PR #102 merged (cdb88d5). Added `size_flags_vertical = Control.SIZE_SHRINK_CENTER` to icon and bar in `ShipStatsSidebar._create_variable_row()`. https://github.com/sqlhammer/Hammer-Forge-Studio/pull/102
