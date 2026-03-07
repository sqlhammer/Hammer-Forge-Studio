---
id: TICKET-0333
title: "VERIFY — BUG fix: Ship boarding ContextualPrompt only shows when aiming at hull (TICKET-0305)"
type: TASK
status: TODO
priority: P1
owner: play-tester
created_by: producer
created_at: 2026-03-07
updated_at: 2026-03-07
milestone: "M11"
phase: "QA"
depends_on: [TICKET-0305]
blocks: []
tags: [verify, bug, ship-boarding, contextual-prompt]
---

## Summary

Verify that the "Board Ship" contextual prompt only appears when the player's crosshair is
aimed at the ship hull — not when merely near the ship — after the fix in TICKET-0305.

---

## Acceptance Criteria

- [ ] Visual verification: Approaching the ship without aiming at the hull — no "Board Ship"
      prompt appears
- [ ] Visual verification: Aiming crosshair directly at the ship hull — "Board Ship" prompt
      appears correctly
- [ ] Visual verification: Moving crosshair off the hull causes the prompt to disappear
- [ ] Visual verification: Pressing interact while prompt is visible successfully boards
      the ship
- [ ] State dump: No quantitative assertions required; check for ERROR-free console
- [ ] Unit test suite: zero failures across all tests
- [ ] No runtime errors during any verification scenario

---

## Handoff Notes

(Leave blank until verification is complete.)

---

## Activity Log

- 2026-03-07 [producer] Created VERIFY ticket for TICKET-0305 — BUG: Ship boarding prompt fix
