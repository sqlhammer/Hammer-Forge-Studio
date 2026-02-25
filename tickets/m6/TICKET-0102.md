---
id: TICKET-0102
title: "QA — icon integration and Studio Head final sign-off"
type: TASK
status: OPEN
priority: P0
owner: qa-engineer
created_by: producer
created_at: 2026-02-25
updated_at: 2026-02-25
milestone: "M6"
milestone_gate: "M5"
phase: "Integration & QA"
depends_on: [TICKET-0098, TICKET-0099, TICKET-0100, TICKET-0101]
blocks: []
tags: [icons, qa, studio-head, milestone-close]
---

## Summary

Verify that all icon locations identified in the TICKET-0086 audit are correctly populated with approved production icons in the running game. Test all icon states, sizes, and dynamic tinting. This is the milestone QA close ticket — it **requires Studio Head sign-off** before it can be marked DONE.

## Acceptance Criteria

**Completeness (every icon location from docs/art/icon-needs.md):**
- [ ] Every item icon location is populated (inventory slots, tech tree nodes, machine panels, module catalog)
- [ ] Every HUD icon location is populated (battery, scanner, compass, mining, ship globals, notifications, tech tree state indicators, drone UI)
- [ ] No `[Missing Texture]` in any icon slot during any tested game state

**Visual quality at all sizes:**
- [ ] Item icons render crisply at 48×48px in inventory and tech tree
- [ ] Item icons render acceptably at 32×32px if used in machine panels
- [ ] HUD icons are legible at 16px (smallest inline use)
- [ ] HUD icons are legible at 24px and 32px (larger status use)
- [ ] No blurry, pixelated, or incorrectly filtered icons at any size

**State coverage:**
- [ ] Battery icon tints correctly at all charge levels (teal normal → amber warning → coral critical)
- [ ] Tech tree lock/unlock icons display correctly in all node states (Locked, Unlockable, Focused, Unlocked)
- [ ] Notification toast icons display for info, warning, and critical types — icon type distinguishes severity independent of color (color-blind safety requirement)
- [ ] Disabled item slots show empty state (no icon bleed or artifact)

**Regression: no new failures introduced:**
- [ ] Full test suite runs with zero failures after icon integration
- [ ] No new Godot import errors or warnings in the Output panel

**Studio Head sign-off:**
- [ ] QA engineer presents findings (passing or failing) to Studio Head
- [ ] Studio Head reviews icon integration in the running game
- [ ] Studio Head explicitly approves this ticket — their approval is recorded in the Activity Log with date and any notes
- [ ] This ticket is marked DONE only after Studio Head approval is recorded

## Implementation Notes

- Use the icon needs list from `docs/art/icon-needs.md` (TICKET-0086) as the QA checklist — every entry on that list must be verified
- Test in the running game, not the editor — Godot's editor scene preview can mask import issues that appear at runtime
- If any icon fails QA, file a new BUGFIX ticket rather than blocking this ticket indefinitely; use producer judgment on whether a bugfix must resolve before Studio Head sign-off or can follow immediately after milestone close
- This is the milestone QA close touchpoint — the Studio Head's sign-off here closes M6

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-25 [producer] Created ticket for M6 Integration & QA phase — milestone close; requires Studio Head sign-off
