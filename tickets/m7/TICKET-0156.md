---
id: TICKET-0156
title: "Bugfix — mining minigame UI shifted to upper-left"
type: BUGFIX
status: OPEN
priority: P1
owner: gameplay-programmer
created_by: studio-head
created_at: 2026-02-26
updated_at: 2026-02-26
milestone: "M7"
phase: "QA"
depends_on: []
blocks: []
tags: [ui, hud, mining, minigame, anchor, layout, bugfix, p1]
---

## Summary

The mining minigame UI is displaced to the upper-left corner of the screen instead of its intended position. This is the same class of anchor/offset regression seen in TICKET-0152 (compass and scan progress bar), likely caused by the same M7 scene architecture refactor that reset Control node anchors.

## Steps to Reproduce

1. Approach a resource deposit
2. Initiate mining
3. Observe the mining minigame UI position — it appears in the upper-left instead of its designed screen location

## Expected Behavior

Mining minigame UI is displayed at its intended position (center or center-bottom of the viewport per original design).

## Actual Behavior

Mining minigame UI is anchored/offset to the upper-left corner of the screen.

## Acceptance Criteria

- [ ] Mining minigame root Control node has correct anchor preset and offsets matching the pre-refactor position
- [ ] UI renders at the correct position at 1920×1080 and in windowed mode
- [ ] No other minigame UI elements are displaced
- [ ] Full test suite passes after fix

## Implementation Notes

- Same root cause as TICKET-0152 — check anchor presets on the mining minigame root Control node; likely reset to `ANCHOR_BEGIN` on both axes during the M7 scene refactor (TICKET-0122–0128)
- Fix via Godot anchor presets, not hardcoded pixel offsets, for resolution independence
- TICKET-0152's fix (removing conflicting runtime anchor code in `.tscn` files) is a useful reference

## Activity Log

- 2026-02-26 [studio-head] Created — regression observed during post-M7 playtesting before QA sign-off
