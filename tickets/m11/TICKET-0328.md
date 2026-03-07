---
id: TICKET-0328
title: "VERIFY — Scene-First remediation: Ship Status Display and Travel Fade Layer (TICKET-0299)"
type: TASK
status: TODO
priority: P1
owner: play-tester
created_by: producer
created_at: 2026-03-07
updated_at: 2026-03-07
milestone: "M11"
phase: "QA"
depends_on: [TICKET-0299]
blocks: []
tags: [verify, scene-first, ship-status-display, travel-fade]
---

## Summary

Verify that the Ship Status Display and Travel Fade Layer work correctly after the
Scene-First refactor in TICKET-0299.

---

## Acceptance Criteria

- [ ] Visual verification: The travel fade (fade-out → load → fade-in) plays correctly
      when traveling between biomes via the Navigation Console
- [ ] Visual verification: Ship status display (docked/undocked state indicators) updates
      correctly when boarding and exiting the ship
- [ ] State dump: No quantitative assertions required; check for ERROR-free console
- [ ] Unit test suite: zero failures across all tests
- [ ] No runtime errors during any verification scenario

---

## Handoff Notes

(Leave blank until verification is complete.)

---

## Activity Log

- 2026-03-07 [producer] Created VERIFY ticket for TICKET-0299 — Scene-First: Ship Status Display + Travel Fade
