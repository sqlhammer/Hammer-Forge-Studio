---
id: TICKET-0090
title: "Item icon style guide — aesthetic brief, format, size, mood"
type: DESIGN
status: DONE
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
tags: [icons, style-guide, item-icons, design, foundation]
---

## Summary

Define the visual target for all item icons used in inventory slots, tech tree node cards, machine interaction panels (Recycler, Fabricator), and the module catalog. Item icons are distinct from HUD/functional icons — they represent physical game objects and must read clearly at 48×48px as the primary display size.

This style guide is the brief that all icon generation experiments (TICKET-0092–0094) must follow for their item icon outputs. It supersedes the current single-line icon entry in `docs/design/ui-style-guide.md` — the winning experiment's output will define what permanently replaces it.

## Acceptance Criteria

- [ ] `docs/art/icon-style-guide-items.md` created and committed
- [ ] Document covers all of the following sections:

**Aesthetic Direction**
- [ ] 2–3 sentence description of the visual mood and feel for item icons (stylized sci-fi appropriate to *The Inheritance*; reference Outer Wilds / Hades as established in the UI style guide)
- [ ] What item icons are NOT: list 2–3 anti-examples (e.g., photorealistic renders, flat cartoon icons, generic UI packs)
- [ ] At least 3 external visual references with descriptions of what to take from each

**Size & Grid**
- [ ] Primary display size: 48×48px (inventory slots, tech tree node cards)
- [ ] Secondary display size: 32×32px (machine panel references, if used)
- [ ] Internal padding/safe area guideline within the icon canvas

**Color Usage**
- [ ] How item icons interact with the game's existing color palette (teal, amber, coral, etc.)
- [ ] Whether item icons use palette colors or have their own naturalistic palette
- [ ] Background treatment: transparent or contained within a shape

**Style Constraints**
- [ ] Stroke weight guidance (if line-art style is used), or render/shading approach (if painted/rendered)
- [ ] Level of detail guidance — how complex should a single icon be?
- [ ] Perspective or viewpoint convention (e.g., slight isometric, flat top-down, 3/4 view)

**Output Format**
- [ ] Target file format for Godot import (SVG preferred for resolution independence; PNG with alpha as fallback)
- [ ] Export resolution if PNG: minimum 96×96px @2x (displayed at 48×48)
- [ ] Naming convention: `icon_item_[name].svg` (e.g., `icon_item_scrap_metal.svg`)

**Godot Integration Notes**
- [ ] How the icon is referenced in Godot scenes (AtlasTexture, SVGTexture, or standalone ImageTexture)
- [ ] Any import settings to apply (linear/sRGB, mipmaps, etc.)

## Implementation Notes

- Read `docs/design/ui-style-guide.md` first — the item icon style guide must be consistent with the broader UI visual language
- Read `docs/art/poc-evaluation-criteria.md` and `docs/art/pipeline-recommendation.md` from M2 for context on the game's established aesthetic standards
- The style guide defines the **target**, not the method. Experiments will attempt to achieve this target using different tools. Write the guide as if describing the ideal output to a human artist, not instructions to a specific tool.
- Generation method research (TICKET-0088) must be complete so you can make informed format decisions (e.g., if no selected method natively produces SVG, specify PNG as primary)

## Handoff Notes

`docs/art/icon-style-guide-items.md` created and committed. Covers all required sections: aesthetic direction (Outer Wilds / Hades / Dead Cells references, 3 anti-examples), size/grid (48×48px primary, 32×32px secondary, 28×28px compact; 24-unit canvas with 2-unit safe area), color usage (stroke inherits `currentColor`, optional one-flat-fill palette defined, transparent background), style constraints (2px stroke, rounded caps/joins, isometric/3-4 view for 3D objects, 8–12 path budget), output format (SVG primary, PNG fallback at 256px, naming convention, full 9-filename list), and Godot integration (SVG importer settings, TextureRect pattern, atlas deferred, slot-size mismatch documented). All 9 item icon file names listed. Consistent with `docs/design/ui-style-guide.md` and informed by icon method research (TICKET-0088).

## Activity Log

- 2026-02-25 [producer] Created ticket for M6 Foundation phase
- 2026-02-25 [ui-ux-designer] DONE — docs/art/icon-style-guide-items.md created and committed. All acceptance criteria met.
