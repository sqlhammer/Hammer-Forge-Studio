---
id: TICKET-0157
title: "Cryonite — resource data layer and Fabricator Fuel Cell recipe"
type: FEATURE
status: IN_PROGRESS
priority: P1
owner: systems-programmer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "M8"
phase: "Foundation"
depends_on: []
blocks: []
tags: [resource, cryonite, fuel-cell, fabricator, data-layer, m8-foundation]
---

## Summary

Define Cryonite as a new mineable resource and add the Fuel Cell crafting recipe to the Fabricator. Cryonite is a pressurized mineral — found trapped in pressurized rock formations across all three biomes in varying concentrations. It is the volatile component required to produce Fuel Cells, which power ship travel.

Cryonite mining ties into the existing mining minigame: careful, timed play yields a full stack; rushed or failed play results in a partial yield (Cryonite vents under pressure when mishandled).

## Acceptance Criteria

- [ ] `Cryonite` resource defined in the resource data registry with:
  - Display name, description, icon slot, stack size, tier
  - `pressurized: true` flag (used by mining minigame to apply partial-yield penalty on failure)
- [ ] Mining minigame system reads `pressurized` flag and applies partial yield on failure (50% yield if minigame failed or skipped) vs full yield on success
- [ ] Fabricator recipe registered: **Metal (2) + Cryonite (1) → Fuel Cell (1)**
- [ ] Fuel Cell defined as a resource/item with display name, description, and stack size (non-equippable, consumed by ship fuel system)
- [ ] Cryonite and Fuel Cell appear correctly in inventory UI with placeholder icons
- [ ] Unit tests cover: Cryonite resource definition, Fuel Cell recipe registration, minigame partial-yield path for pressurized resources, full-yield path on success
- [ ] Full test suite passes

## Implementation Notes

- Extend the existing resource registry pattern used for Scrap Metal, Metal, etc.
- The `pressurized` flag should be a property on the resource definition, not a special-case in the minigame code — minigame queries the resource being mined
- Fuel Cell is a ship-consumed item, not a player-equippable — ensure the item type flag reflects this so it cannot be accidentally equipped
- Cryonite deposit *scene* (3D mesh) is handled in TICKET-0179 — this ticket is data only

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created — M8 Foundation phase
- 2026-02-27 [systems-programmer] Starting work — adding Cryonite resource, Fuel Cell item, fabricator recipe, and pressurized mining yield logic
