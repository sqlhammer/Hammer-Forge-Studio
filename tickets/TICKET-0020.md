---
id: TICKET-0020
title: "Resource data definitions"
type: DESIGN
status: OPEN
priority: P1
owner: systems-programmer
created_by: producer
created_at: 2026-02-22
updated_at: 2026-02-22
milestone: "M3"
depends_on: []
blocks: [TICKET-0021, TICKET-0022]
tags: [resources, data, architecture]
---

## Summary
Define the data structures and registry for game resources. M3 only has Scrap Metal, but the data model must be extensible for future resource types, purity levels, and deposit tiers. This is the foundation that inventory and deposit systems build on.

## Acceptance Criteria
- [ ] Resource data structure defined (resource ID, display name, description, stack size, icon reference, tier, category)
- [ ] Scrap Metal resource defined with stack size of 100
- [ ] Resource registry implemented as a centralized lookup (autoload, static class, or `.tres` resource — architect's choice)
- [ ] Data model supports future extension: multiple resource types, purity modifiers, tier requirements
- [ ] Design documented in implementation notes or inline code comments per coding standards

## Implementation Notes
- Reference `docs/design/systems/meaningful-mining.md` for the purity system (1–5 stars) and deposit tiers (1–4)
- Reference `docs/design/systems/biomes.md` for resource palette structure (primary, secondary, rare, surface collectibles)
- M3 scope: only Scrap Metal exists, but the registry pattern must not be hardcoded to one type
- Consider using Godot Resource (`.tres`) files for resource definitions — data-driven, editor-friendly
- File location: `game/autoload/` or `game/scripts/systems/` — architect's discretion, document the choice
- Reference `docs/engineering/coding-standards.md` for naming and formatting

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-22 [producer] Created ticket
