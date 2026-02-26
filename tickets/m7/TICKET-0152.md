---
id: TICKET-0152
title: "Bugfix — compass and scan progress bar anchored to upper-left instead of top-center"
type: BUGFIX
status: IN_PROGRESS
priority: P1
owner: gameplay-programmer
created_by: studio-head
created_at: 2026-02-26
updated_at: 2026-02-26
milestone: "M7"
phase: "QA"
depends_on: []
blocks: []
tags: [hud, compass, scanner, layout, anchor, bugfix, p1]
---

## Summary

The compass HUD and the scanning progress bar are both anchored to the upper-left corner of the viewport instead of their intended positions. This was observed in-game and is visible in the attached screenshot — the compass tick strip and the "SCANNING" label with its teal progress bar appear flush against the top-left edge of the screen.

The M7 scene architecture refactor (TICKET-0122 through TICKET-0128) touched HUD scenes and likely displaced or reset Control node anchors/offsets.

## Screenshot

`C:\temp\2026-02-26_16-56-02.png`

- Compass tick strip (showing "E" / "SE" headings): visible at the very top-left, should be centered horizontally at the top of the viewport
- Scan progress bar ("SCANNING" + teal bar): visible below the compass at top-left, should be positioned at a defined location (center-top or center of screen per original design)

## Steps to Reproduce

1. Load the game in first-person mode with a deposit nearby
2. Begin scanning a deposit (hold Scan key)
3. Observe compass and scan progress bar position

## Expected Behavior

- Compass is centered horizontally at the top of the viewport
- Scan progress bar is centered horizontally (or positioned per the original HUD layout spec)

## Actual Behavior

Both elements are anchored/offset to the upper-left corner of the screen.

## Acceptance Criteria

- [ ] Compass Control node has correct anchor and offset — centered horizontally at top of viewport
- [ ] Scan progress bar Control node has correct anchor and offset — matches pre-refactor position
- [ ] Both elements remain correctly positioned at multiple resolutions (test at 1920×1080 and windowed)
- [ ] No other HUD elements have been unintentionally displaced
- [ ] Full test suite still passes after fix

## Implementation Notes

- Check anchor presets on the compass root Control node (`game/scenes/hud/` or equivalent) — likely `ANCHOR_BEGIN` on both axes instead of `ANCHOR_CENTER` / top-center preset
- Check the scan progress bar container's anchor preset similarly
- The M7 refactor tickets most likely to have caused this: TICKET-0122 (scene restructure), TICKET-0127 (HUD wiring), TICKET-0128 (integration)
- Do not hardcode pixel offsets — use Godot anchor presets and `grow_direction` so the layout is resolution-independent

## Activity Log
- 2026-02-26 [studio-head] Created — observed during post-M7 playtesting before QA sign-off
- 2026-02-26 [gameplay-programmer] Status → IN_PROGRESS — Starting work
