---
id: TICKET-0086
title: "Icon needs audit — catalog every icon location in the game"
type: TASK
status: DONE
priority: P1
owner: ui-ux-designer
created_by: producer
created_at: 2026-02-25
updated_at: 2026-02-25 (DONE)
milestone: "M6"
milestone_gate: "M5"
phase: "Foundation"
depends_on: []
blocks: [TICKET-0089, TICKET-0092, TICKET-0093, TICKET-0094]
tags: [icons, audit, ui, foundation]
---

## Summary

Before any icon can be designed or generated, we need an authoritative, exhaustive list of every location in the game where an icon appears or will appear. This audit searches wireframes, the UI style guide, GDD, and live Godot scenes to produce that list. The output document (`docs/art/icon-needs.md`) becomes the production manifest for all subsequent experiment and integration work.

## Acceptance Criteria

- [ ] `docs/art/icon-needs.md` created and committed
- [ ] Document covers both icon categories: **Item Icons** (48×48px, in inventory/tech tree/machine panels) and **HUD/Functional Icons** (16–32px, in HUD elements, notifications, status indicators)
- [ ] Every icon need is listed with: icon name, category (item/HUD), UI location(s) where it appears, required size(s), and current placeholder status (none / placeholder / production-ready)
- [ ] At minimum, the following known icons are documented (expand from scene/wireframe audit):
  - **Item Icons:** Scrap Metal, Metal, Spare Battery, Head Lamp, Hand Drill, Fabricator module, Automation Hub module, Recycler module, resource node (generic)
  - **HUD/Functional:** Suit battery, scan ping, compass direction marker, mining drill activity, power (ship global), integrity (ship global), heat (ship global), oxygen (ship global), notification badge (info/warning/critical), lock (tech tree), unlock/checkmark (tech tree), drone (automation hub)
- [ ] Any icon locations found in the Godot scene tree that are not covered by existing wireframes are flagged and documented
- [ ] Total icon count (by category) is summarized at the top of the document

## Implementation Notes

- Search sources in this order: `docs/design/wireframes/` (all milestones), `docs/design/ui-style-guide.md`, `docs/design/gdd.md`, live Godot scenes under `game/scenes/`
- Use Godot MCP tools (`get_scene_tree`, `view_script`) to inspect scenes for `TextureRect` or `Sprite2D` nodes that represent icon slots
- Cross-reference with M5 ticket deliverables (tech tree, fabricator panel, drone UI, third-person HUD wireframes) to ensure M5 additions are included
- This list will be used by Experiments (TICKET-0092–0094) as the definitive icon production manifest — be thorough

## Handoff Notes

`docs/art/icon-needs.md` created and committed (f317dc4). 29 icons total: 9 item icons, 20 HUD/functional icons. All slots are currently placeholder — no production texture assets exist. Three scene-level flags raised (slot size mismatch in recycler/fabricator panels, missing notification badge icon wireframe, undefined scan ping and mining active icons). Document is ready for use as production manifest by TICKET-0092–0094.

## Activity Log

- 2026-02-25 [producer] Created ticket for M6 Foundation phase
- 2026-02-25 [ui-ux-designer] DONE — docs/art/icon-needs.md created and pushed (commit f317dc4). 29 icons cataloged (9 item, 20 HUD). All acceptance criteria met.
