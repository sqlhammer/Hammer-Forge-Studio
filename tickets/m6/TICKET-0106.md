---
id: TICKET-0106
title: "Visual QA — verify icon contrast at all integration points"
type: TASK
status: OPEN
priority: P1
owner: qa-engineer
created_by: producer
created_at: 2026-02-25
updated_at: 2026-02-25
milestone: "M6"
phase: "Integration & QA"
depends_on: [TICKET-0105]
blocks: [TICKET-0102]
tags: [icons, qa, contrast, visual, integration]
---

## Summary

After icon regeneration (TICKET-0105), perform a targeted visual pass at every in-game icon integration point to confirm the updated icons are clearly readable against their backgrounds. This is a prerequisite for TICKET-0102 (full QA sign-off and Studio Head approval).

## Acceptance Criteria

- [ ] Every icon integration point checked in a running build:
  - **Inventory screen** — all 9 item icons at 48×48px against inventory slot background
  - **Tech tree node cards** — Fabricator, Automation Hub icons at 48×48px against card background
  - **Recycler interaction panel** — Scrap Metal and Metal icons in input/output sections
  - **Fabricator interaction panel** — all recipe input/output item icons
  - **Module catalog / placement UI** — Recycler, Fabricator, Automation Hub module icons
  - **HUD overlay** — all 20 HUD/functional icons at 16px (minimum size) and 24px
  - **Ship global map / navigation HUD** — relevant HUD icons at their in-situ sizes
- [ ] Each icon passes: clearly readable and distinguishable at its displayed size against its actual background. A "pass" means a reasonable person can identify the icon's subject without ambiguity.
- [ ] Any icon that fails the readability check is documented with: icon file name, integration point, background color, and a brief description of the failure
- [ ] If any icons fail: open a follow-up BUGFIX ticket and block TICKET-0102 on it. Do not mark this ticket DONE and let failures through to QA sign-off.
- [ ] If all icons pass: record pass status in Handoff Notes and mark DONE

## Implementation Notes

- Use the Godot editor Play Scene feature to test in a running build — do not evaluate against static editor previews
- The contrast requirements are defined in `docs/art/icon-style-guide-items.md` and `docs/art/icon-style-guide-hud.md` (post TICKET-0104) — reference these for the pass/fail threshold
- Test the HUD icons at 16px specifically; this is the hardest size and the most likely to fail if the contrast fix was insufficient

## Activity Log

- 2026-02-25 [producer] Created ticket — visual QA gate for icon contrast fix. Blocks TICKET-0102.
