---
id: TICKET-0140
title: "Bugfix — HUD compass is not horizontally centered"
type: BUGFIX
status: IN_PROGRESS
priority: P2
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-26
updated_at: 2026-02-26
milestone: "M7"
phase: "QA"
depends_on: []
blocks: [TICKET-0130]
tags: [hud, compass, ui, bugfix, p2]
---

## Summary

The HUD compass bar that should appear centered at the top of the screen is instead pinned to the top-left corner of the viewport. It is only partially visible and cut off at the left edge.

## Steps to Reproduce

1. Launch the game (exterior or interior — observed in exterior)
2. Observe the compass bar at the top of the screen

## Expected Behavior

The compass bar is horizontally centered at the top of the screen, with cardinal/intercardinal tick marks and labels readable across the full width.

## Actual Behavior

The compass bar is anchored to the top-left corner of the screen. Only the rightmost portion of the bar (showing W and NW) is visible; the rest is clipped off-screen to the left.

## Acceptance Criteria

- [x] Compass bar is horizontally centered at the top of the screen
- [x] All visible compass labels and ticks render correctly within the centered bar
- [x] Centering holds at the target resolution and when resizing

## Implementation Notes

- Check the compass HUD node's anchor and offset settings in the CanvasLayer scene — the node is likely anchored `LEFT` instead of `CENTER` or `TOP_CENTER`
- In Godot 4, verify `anchor_left`, `anchor_right`, and `offset_left`/`offset_right` are set symmetrically for a centered layout, or use a `CenterContainer` parent

## Activity Log

- 2026-02-26 [producer] Created — visual regression found during M7 QA review
- 2026-02-26 [gameplay-programmer] Starting work — setting anchors to center compass bar horizontally at top of screen
