---
id: TICKET-0099
title: "Integrate item icons — inventory, tech tree, all machine panels"
type: FEATURE
status: OPEN
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-25
updated_at: 2026-02-25
milestone: "M6"
milestone_gate: "M5"
phase: "Integration & QA"
depends_on: [TICKET-0097]
blocks: [TICKET-0101, TICKET-0102]
tags: [icons, integration, ui, inventory, tech-tree]
---

## Summary

Wire all item icons from `game/assets/icons/item/` into every UI location where item icons appear. This replaces any placeholder/missing icon states (grey boxes, missing textures) with the approved production icons.

## Acceptance Criteria

- [ ] **Inventory screen:** All items in the `ItemData` / `ResourceDefs` system have their icon path wired to the correct file in `game/assets/icons/item/`. Inventory slot `TextureRect` displays the correct icon for each item type at 48×48px.
- [ ] **Tech tree node cards:** Fabricator node card displays `icon_item_fabricator.svg` (or equivalent); Automation Hub node card displays its icon. Icons display at 48×48px per the tech tree wireframe spec.
- [ ] **Recycler interaction panel:** Scrap Metal and Metal icons display correctly in the input/output sections of the Recycler UI.
- [ ] **Fabricator interaction panel:** All Fabricator recipe inputs and outputs display the correct item icons.
- [ ] **Module catalog / placement UI:** Each installable module (Recycler, Fabricator, Automation Hub) displays its icon in the catalog/placement UI.
- [ ] **Item detail area (inventory):** Icon for the focused item is also visible in the detail row below the grid (if not already handled by the slot reference).
- [ ] No `[Missing Texture]` errors in any icon slot after integration
- [ ] All icons display at the correct size specified by their wireframe (48×48 for inventory/tech tree)
- [ ] All code follows `docs/engineering/coding-standards.md`

## Implementation Notes

- Icons are committed to `game/assets/icons/item/` by TICKET-0097. Do not move or rename files — reference them at their committed paths.
- If item data resources (`.tres` or GDScript `const`) currently have an `icon` or `texture` property, set it to `load("res://assets/icons/item/icon_item_[name].svg")` (or `.png` depending on format)
- If no icon property exists on item data resources, add one per the systems-programmer's data layer pattern (see `game/scripts/systems/` for existing resource definitions)
- Place integration-test assets in `game/assets/icons/temp/` ONLY if you need a temporary stand-in during development — all final wiring must reference `game/assets/icons/item/`
- Refer to `docs/design/wireframes/m3/inventory.md` (inventory slot spec), `docs/design/wireframes/m5/tech-tree.md` (node card spec), and M4/M5 machine panel wireframes for exact layout context

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-25 [producer] Created ticket for M6 Integration & QA phase
