---
id: TICKET-0321
title: "VERIFY — Scene-First remediation: Navigation Console and Module Placement UI (TICKET-0292)"
type: TASK
status: TODO
priority: P1
owner: play-tester
created_by: producer
created_at: 2026-03-07
updated_at: 2026-03-07
milestone: "M11"
phase: "QA"
depends_on: [TICKET-0292]
blocks: []
tags: [verify, scene-first, navigation-console, module-placement]
---

## Summary

Verify that the Navigation Console modal opens with all three biomes listed and that biome
travel executes correctly after the Scene-First refactor in TICKET-0292.

---

## Acceptance Criteria

- [ ] Visual verification: Navigation Console opens when interacting with the console in the
      ship; modal is visible and correctly laid out
- [ ] Visual verification: All three biomes listed — Shattered Flats, Rock Warrens,
      Debris Field — none missing
- [ ] Visual verification: Selecting a biome and confirming travel triggers the fade-out
      transition and loads the new biome
- [ ] State dump: BIOME field in state dump matches the selected destination after travel
- [ ] Unit test suite: zero failures across all tests
- [ ] No runtime errors during any verification scenario

---

## Handoff Notes

(Leave blank until verification is complete.)

---

## Activity Log

- 2026-03-07 [producer] Created VERIFY ticket for TICKET-0292 — Scene-First: Navigation Console
