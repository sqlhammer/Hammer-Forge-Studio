---
id: TICKET-0044
title: "Module placement mechanic"
type: FEATURE
status: OPEN
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-23
updated_at: 2026-02-23
milestone: "M4"
depends_on: [TICKET-0040, TICKET-0043]
blocks: [TICKET-0045]
tags: [ship, modules, interaction, gameplay]
---

## Summary
Player can install the Recycler module inside the ship interior. Interacting with a placement zone opens a module selection UI showing available modules with install costs. Confirming the install deducts resources from inventory and places the module in the zone.

## Acceptance Criteria
- [ ] Player can interact with a placement zone inside the ship interior
- [ ] Module selection UI displays available modules from the module catalog (Recycler in M4) with install cost shown
- [ ] Install blocked with feedback if player lacks sufficient resources
- [ ] Confirming install deducts Scrap Metal from player inventory
- [ ] Installed Recycler appears visually in the placement zone (placeholder mesh acceptable)
- [ ] Installed Recycler is interactable — opens Recycler panel (TICKET-0045)
- [ ] Placement zone shows occupied/empty state correctly
- [ ] Install persists correctly — Recycler still installed after leaving and re-entering ship
- [ ] All input routed through InputManager
- [ ] No Godot editor errors or warnings

## Implementation Notes
- Module selection UI can be a simple list — no complex layout needed in M4
- Placeholder mesh for the installed Recycler is fine; M6 (Ship Interior) will add proper visuals
- Reference the module install API from TICKET-0040 for resource deduction logic
- Only one placement zone required in M4; the framework should support multiple for future milestones

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-23 [producer] Created ticket
