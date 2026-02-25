---
id: TICKET-0098
title: "Update UI style guide — replace icon section with approved direction"
type: TASK
status: OPEN
priority: P2
owner: ui-ux-designer
created_by: producer
created_at: 2026-02-25
updated_at: 2026-02-25
milestone: "M6"
milestone_gate: "M5"
phase: "Integration & QA"
depends_on: [TICKET-0096]
blocks: [TICKET-0102]
tags: [icons, style-guide, documentation]
---

## Summary

The current `docs/design/ui-style-guide.md` contains a single brief icon section:

> **Style:** Line icons, 2px stroke weight, rounded caps
> **Size grid:** 16x16px (inline), 24x24px (standard), 32x32px (large/prominent)
> **Format:** SVG preferred for editor; exported as Godot `AtlasTexture` or `SVGTexture` for runtime

This entry was a placeholder. Now that the winning icon method and style have been approved by Studio Head, replace this section with references to the two authoritative icon style guides produced in this milestone.

## Acceptance Criteria

- [ ] `docs/design/ui-style-guide.md` Icon Style section replaced with content that:
  - References `docs/art/icon-style-guide-items.md` as the authoritative spec for item icons
  - References `docs/art/icon-style-guide-hud.md` as the authoritative spec for HUD/functional icons
  - Retains any size grid or format information that is still accurate after the experiment, updating any values that changed
  - Notes the winning generation method and links to `docs/art/icon-poc-report.md` for full pipeline documentation
- [ ] No other sections of `docs/design/ui-style-guide.md` modified
- [ ] Change committed to `main`

## Implementation Notes

- Read TICKET-0096 Handoff Notes and `docs/art/icon-poc-report.md` to understand which method won and what format the approved icons use
- Keep the style guide update minimal — do not rewrite surrounding sections. This is a targeted replacement of the Icon Style section only.

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-25 [producer] Created ticket for M6 Integration & QA phase
