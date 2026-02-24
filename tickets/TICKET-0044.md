---
id: TICKET-0044
title: "Module placement mechanic"
type: FEATURE
status: DONE
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-23
updated_at: 2026-02-23
milestone: "M4"
milestone_gate: "M3"
depends_on: [TICKET-0040, TICKET-0043, TICKET-0054]
blocks: [TICKET-0045]
tags: [ship, modules, interaction, gameplay]
---

## Summary
Player can install the Recycler module inside the ship interior. Interacting with a placement zone opens a module selection UI showing available modules with install costs. Confirming the install deducts resources from inventory and places the module in the zone.

## Acceptance Criteria
- [x] Player can interact with a placement zone inside the ship interior
- [x] Module selection UI displays available modules from the module catalog (Recycler in M4) with install cost shown
- [x] Install blocked with feedback if player lacks sufficient resources
- [x] Confirming install deducts Scrap Metal from player inventory
- [x] Installed Recycler appears visually in the placement zone using `game/assets/meshes/machines/mesh_recycler_module.glb` (delivered by TICKET-0054)
- [x] Installed Recycler is interactable — opens Recycler panel (TICKET-0045)
- [x] Placement zone shows occupied/empty state correctly
- [x] Install persists correctly — Recycler still installed after leaving and re-entering ship
- [x] All input routed through InputManager
- [x] No Godot editor errors or warnings

## Implementation Notes
- Module selection UI can be a simple list — no complex layout needed in M4
- Use `game/assets/meshes/machines/mesh_recycler_module.glb` (TICKET-0054) for the installed machine — this is a greybox asset, not a placeholder; M8 (Visual Asset Refinement) will polish it
- Reference the module install API from TICKET-0040 for resource deduction logic
- Only one placement zone required in M4; the framework should support multiple for future milestones

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-23 [producer] Created ticket
- 2026-02-23 [producer] Added TICKET-0054 dependency; updated acceptance criteria and implementation notes to reference real Recycler mesh asset rather than placeholder
- 2026-02-23 [gameplay-programmer] Implemented: ModulePlacementUI with catalog listing, cost/power display, install flow via ModuleManager API, Recycler mesh placement via ShipInterior zone system, greybox fallback. Integrated into test_world.gd.
