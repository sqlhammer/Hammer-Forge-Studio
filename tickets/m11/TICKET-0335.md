---
id: TICKET-0335
title: "VERIFY — BUG fix: HUD CompassBar/MiningProgress/MiningMinigameOverlay anchor presets (TICKET-0307)"
type: TASK
status: TODO
priority: P1
owner: play-tester
created_by: producer
created_at: 2026-03-07
updated_at: 2026-03-07
milestone: "M11"
phase: "QA"
depends_on: [TICKET-0307]
blocks: []
tags: [verify, bug, hud, compass-bar, mining-progress, anchors]
---

## Summary

Verify that CompassBar, MiningProgress, and MiningMinigameOverlay are correctly positioned
at runtime after the anchor preset regression fix in TICKET-0307.

---

## Acceptance Criteria

- [ ] Visual verification: CompassBar is correctly positioned (not collapsed to a point or
      displaced to a corner) when the game world is loaded
- [ ] Visual verification: MiningProgress bar appears correctly sized and positioned during
      an active mining session
- [ ] Visual verification: MiningMinigameOverlay appears correctly positioned when the
      mining minigame is triggered
- [ ] State dump: No quantitative assertions required; check for ERROR-free console
- [ ] Unit test suite: zero failures across all tests — specifically the three
      test_scene_properties_unit anchor tests (CompassBar, MiningProgress,
      MiningMinigameOverlay) must pass
- [ ] No runtime errors during any verification scenario

---

## Handoff Notes

(Leave blank until verification is complete.)

---

## Activity Log

- 2026-03-07 [producer] Created VERIFY ticket for TICKET-0307 — BUG: HUD anchor presets regression
