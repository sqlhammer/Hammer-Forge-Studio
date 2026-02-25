---
id: TICKET-0091
title: "HUD/functional icon style guide — aesthetic brief, format, size, mood"
type: DESIGN
status: OPEN
priority: P1
owner: ui-ux-designer
created_by: producer
created_at: 2026-02-25
updated_at: 2026-02-25
milestone: "M6"
milestone_gate: "M5"
phase: "Foundation"
depends_on: [TICKET-0088]
blocks: [TICKET-0092, TICKET-0093, TICKET-0094]
tags: [icons, style-guide, hud-icons, design, foundation]
---

## Summary

Define the visual target for all HUD and functional icons: suit battery, scanner ping, compass direction marker, mining activity indicator, ship global status symbols (Power, Integrity, Heat, Oxygen), notification type badges, tech tree state icons (lock, checkmark, unlock indicator), and drone indicators.

HUD/functional icons are fundamentally different from item icons — they communicate state and action, not object identity. They must be readable at 16px (inline HUD use) through 32px (prominent status panels), and their style should prioritize immediate legibility over decorative detail.

This style guide is the brief that all icon generation experiments (TICKET-0092–0094) must follow for their HUD icon outputs. It supersedes the current single-line icon entry in `docs/design/ui-style-guide.md`.

## Acceptance Criteria

- [ ] `docs/art/icon-style-guide-hud.md` created and committed
- [ ] Document covers all of the following sections:

**Aesthetic Direction**
- [ ] 2–3 sentence description of the visual mood for HUD icons: functional, legible, "researcher's instrument panel" feel (per existing style guide philosophy)
- [ ] Differentiation from item icons: HUD icons are communicative glyphs, not object portraits
- [ ] At least 3 external reference examples of HUD icon systems (games or UI frameworks) with notes on what to take from each

**Size & Grid**
- [ ] Sizes supported: 16×16px (inline), 24×24px (standard), 32×32px (large/prominent) — consistent with existing style guide size grid
- [ ] Internal safe area / padding guideline within the icon canvas
- [ ] Guidance on which size is the design master (design at 32px, scale down)

**Color Usage**
- [ ] HUD icons must inherit parent text color by default (as per existing style guide) — confirm this rule or define exceptions
- [ ] State-based color overrides: which icons change color to communicate state (e.g., battery icon goes coral at critical level)
- [ ] Whether any HUD icons have fixed colors vs. dynamic/inherited

**Style Constraints**
- [ ] Stroke-based vs. filled/solid: the existing style guide specifies line icons (2px stroke, rounded caps) — confirm this is maintained, modified, or replaced
- [ ] Complexity ceiling: at 16px, only the simplest forms survive — define max detail level
- [ ] Symbol vs. pictographic: where abstract symbols are acceptable vs. recognizable pictographs required

**Output Format**
- [ ] Target file format for Godot import
- [ ] Export resolution if PNG: minimum 48×48px @3x (displayed at 16×16 minimum)
- [ ] Naming convention: `icon_hud_[name].svg` (e.g., `icon_hud_battery.svg`, `icon_hud_power.svg`)

**Godot Integration Notes**
- [ ] How icons are tinted dynamically at runtime (using Godot `modulate` on the TextureRect or equivalent)
- [ ] Any import settings to apply

**Icon List Coverage**
- [ ] Confirm style guidance addresses all known HUD icon types from the audit (TICKET-0086); if audit is not yet complete, use the preliminary list from the M6 milestone doc as the working baseline

## Implementation Notes

- Read `docs/design/ui-style-guide.md` sections on Icon Style, Color Palette, and Component Standards — this guide must be coherent with those definitions
- Read all HUD wireframes under `docs/design/wireframes/` to understand where each icon type appears in context
- The style guide defines the **target**, not the method. Experiments will attempt to achieve this target — write the guide as a brief to a hypothetical human icon artist
- Generation method research (TICKET-0088) must be complete so format decisions reflect what selected methods can actually produce

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-25 [producer] Created ticket for M6 Foundation phase
