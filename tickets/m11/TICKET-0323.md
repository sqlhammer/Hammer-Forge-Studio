---
id: TICKET-0323
title: "VERIFY — Scene-First remediation: HUD Readout components (TICKET-0294)"
type: TASK
status: TODO
priority: P1
owner: play-tester
created_by: producer
created_at: 2026-03-07
updated_at: 2026-03-07
milestone: "M11"
phase: "QA"
depends_on: [TICKET-0294]
blocks: []
tags: [verify, scene-first, hud, scanner-readout, ship-globals-hud, ship-stats-sidebar]
---

## Summary

Verify that scanner_readout, ship_globals_hud, and ship_stats_sidebar all display correctly
after the Scene-First refactor in TICKET-0294.

---

## Acceptance Criteria

- [ ] Visual verification: ship_globals_hud visible in HUD during play — battery and fuel
      values displayed
- [ ] Visual verification: ship_stats_sidebar visible when appropriate; displays ship stats
- [ ] Visual verification: scanner_readout appears when scanner is activated (ping action);
      shows scan data and hides when scanner is inactive
- [ ] State dump: BATTERY and FUEL values in state dump match HUD readout display
- [ ] Unit test suite: zero failures across all tests
- [ ] No runtime errors during any verification scenario

---

## Handoff Notes

(Leave blank until verification is complete.)

---

## Activity Log

- 2026-03-07 [producer] Created VERIFY ticket for TICKET-0294 — Scene-First: HUD Readout components
