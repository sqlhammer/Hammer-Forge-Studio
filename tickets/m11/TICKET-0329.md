---
id: TICKET-0329
title: "VERIFY — Scene-First remediation: HUD layout properties moved from _ready() (TICKET-0300)"
type: TASK
status: TODO
priority: P1
owner: play-tester
created_by: producer
created_at: 2026-03-07
updated_at: 2026-03-07
milestone: "M11"
phase: "QA"
depends_on: [TICKET-0300]
blocks: []
tags: [verify, scene-first, hud, layout]
---

## Summary

Verify that all 8 HUD components with layout properties moved from _ready() into the scene
file display correctly with no anchor or positioning regressions after TICKET-0300.

---

## Acceptance Criteria

- [ ] Visual verification: All HUD elements are correctly positioned at game start — compass
      bar, battery bar, fuel gauge, scanner readout, and mining overlays are in expected
      screen locations
- [ ] Visual verification: CompassBar is visible at the expected position (not collapsed,
      not displaced to corner)
- [ ] Visual verification: MiningProgress and MiningMinigameOverlay appear correctly
      positioned during a mining session
- [ ] State dump: No quantitative assertions required; check for ERROR-free console
- [ ] Unit test suite: zero failures across all tests (specifically test_scene_properties_unit
      anchors tests must pass)
- [ ] No runtime errors during any verification scenario

---

## Handoff Notes

(Leave blank until verification is complete.)

---

## Activity Log

- 2026-03-07 [producer] Created VERIFY ticket for TICKET-0300 — Scene-First: HUD layout properties
