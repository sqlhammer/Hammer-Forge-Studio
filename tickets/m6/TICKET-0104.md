---
id: TICKET-0104
title: "Amend icon style guides — add contrast requirements against in-game backgrounds"
type: TASK
status: OPEN
priority: P1
owner: ui-ux-designer
created_by: producer
created_at: 2026-02-25
updated_at: 2026-02-25
milestone: "M6"
phase: "Integration & QA"
depends_on: []
blocks: [TICKET-0105]
tags: [icons, style-guide, contrast, accessibility, ui]
---

## Summary

Post-integration QA has identified that the current Method A SVG icons are too dark to read clearly against the game's UI panel backgrounds. Both icon style guides (`docs/art/icon-style-guide-items.md` and `docs/art/icon-style-guide-hud.md`) must be amended to define explicit contrast requirements. These requirements will drive TICKET-0105 (icon regeneration).

## Acceptance Criteria

- [ ] `docs/art/icon-style-guide-items.md` amended with a **Contrast Requirements** section
- [ ] `docs/art/icon-style-guide-hud.md` amended with a **Contrast Requirements** section
- [ ] Both sections define:
  - The known background colors icons appear on (dark panel background, inventory slot, HUD overlay). Read the current scenes and UI style guide to identify the actual hex values in use.
  - A minimum luminance difference between the icon's primary fill color and the background it sits on (define a specific value, e.g., primary fill must be at least 40% lighter than the darkest background it is used on)
  - A rule for icon stroke/outline: if fill-alone contrast is insufficient, a light outline or drop-shadow effect is required to separate the icon from the background
  - Explicit approved fill palette: list 2–4 approved fill colors (hex values) that satisfy the contrast requirement against all known backgrounds
- [ ] `docs/design/ui-style-guide.md` Icon Style section updated to note that contrast requirements are defined in the individual style guides (1-line addition only — do not rewrite the section)
- [ ] All changes committed to `main`

## Implementation Notes

- Open the game scenes or read the UI style guide to determine the exact background hex values for: dark panel backgrounds, inventory slot backgrounds, and HUD overlay backgrounds. Do not guess or invent values.
- The contrast rule does not need to be WCAG-exact, but must be a specific, testable numeric threshold the technical-artist can implement in the Python SVG generator
- Do not redesign the icon shapes or change any other aspect of the style guides — this is a targeted contrast-only amendment

## Activity Log

- 2026-02-25 [producer] Created ticket — contrast deficiency identified post-integration. Blocks icon regeneration (TICKET-0105).
