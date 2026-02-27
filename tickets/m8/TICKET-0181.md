---
id: TICKET-0181
title: "BUGFIX — Missing fuel cell icon asset blocks fabricator recipe display"
type: BUGFIX
status: PENDING
priority: P1
owner: technical-artist
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "M8"
phase: "Gameplay"
depends_on: []
blocks: []
tags: [asset, icon, fuel-cell, bugfix, m8-gameplay]
---

## Summary

The fabricator panel's recipe list builder fails to load `res://assets/icons/item/icon_item_fuel_cell.svg`, blocking the recipe UI from rendering. The icon file is missing from the asset directory. This is discovered during Gameplay phase testing when recipes are displayed.

## Root Cause

- TICKET-0157 (Cryonite & Fuel Cell recipe data) added the fuel cell recipe to the Fabricator, but the accompanying icon asset was not created or committed
- fabricator_panel.gd line 471 attempts to load the icon and fails silently, leaving the recipe row incomplete

## Acceptance Criteria

- [ ] Create `res://assets/icons/item/icon_item_fuel_cell.svg` — a 32×32 (or standard icon size) SVG icon representing a fuel cell
- [ ] Icon follows the M6 icon generation pipeline standards (see `docs/studio/reports/2026-02-26-m6-evaluation-summary.md`)
- [ ] Icon integrates with existing item icon style (consistent with battery, cryonite, and other resource icons)
- [ ] Fabricator panel recipe row renders without errors in-game
- [ ] No resource load warnings in the console for this file
- [ ] Icon asset is committed to the repository

## Implementation Notes

- Icon size and style should match existing item icons (check `res://assets/icons/item/` for reference)
- The SVG can be created with Python svgwrite (the winning method from M6) or hand-edited if a quick fix is needed
- No code changes required — only asset creation

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created — missing fuel cell icon blocking fabricator UI during Gameplay phase
