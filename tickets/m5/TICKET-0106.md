---
id: TICKET-0106
title: "Bugfix — Scan ring visual effect missing when pressing Q to locate resources"
type: BUGFIX
status: TODO
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-25
updated_at: 2026-02-25
milestone: "M5"
phase: "QA"
depends_on: []
blocks: []
tags: [bugfix, scanner, visual, required-feature]
---

## Summary
When the player presses Q to scan for resources, no visual ring expands outward from the player. The scan ring effect was a required deliverable. The scan action may still function mechanically, but the visual feedback is absent.

## Reproduction
1. Start the game and enter the game world on foot
2. Press Q to activate the resource scanner
3. Observe — no ring or pulse animation expands from the player's position

## Expected Behavior
A visible ring (pulse/wave) must expand outward from the player when Q is pressed, indicating the scan radius. This is a required visual for the scanner feature. Resource highlights or indicators should appear on detected deposits within range.

## Fix
- Locate the scanner visual implementation (likely in `game/scripts/gameplay/` or the scanner scene)
- Determine whether the ring effect was never implemented or was broken during M5
- Implement or restore the expanding ring effect tied to the Q scan action
- Ensure the ring scales to the correct scan radius and fades out at the edge

## Acceptance Criteria
- [ ] Pressing Q causes a visible ring/pulse to expand outward from the player
- [ ] The ring reaches the edge of the scan radius and then disappears
- [ ] Resource deposits within range are highlighted or indicated after the scan
- [ ] No errors thrown during scan

## Activity Log
- 2026-02-25 [producer] Created from UAT feedback. Scan ring is a required visual; currently absent entirely.
