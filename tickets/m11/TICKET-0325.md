---
id: TICKET-0325
title: "VERIFY — Scene-First remediation: Main Menu (TICKET-0296)"
type: TASK
status: TODO
priority: P1
owner: play-tester
created_by: producer
created_at: 2026-03-07
updated_at: 2026-03-07
milestone: "M11"
phase: "QA"
depends_on: [TICKET-0296]
blocks: []
tags: [verify, scene-first, main-menu]
---

## Summary

Verify that the Main Menu loads correctly and can start a new game after the Scene-First
refactor in TICKET-0296.

---

## Acceptance Criteria

- [ ] Visual verification: Launching res://game.tscn displays the main menu correctly —
      title and button(s) are visible and correctly positioned
- [ ] Visual verification: Pressing New Game (or equivalent) loads the game world without
      errors or blank screens
- [ ] State dump: No quantitative assertions required; check for ERROR-free console
- [ ] Unit test suite: zero failures across all tests
- [ ] No runtime errors during any verification scenario

---

## Handoff Notes

(Leave blank until verification is complete.)

---

## Activity Log

- 2026-03-07 [producer] Created VERIFY ticket for TICKET-0296 — Scene-First: Main Menu
