---
id: TICKET-0029
title: "Greybox test world"
type: TASK
status: OPEN
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-22
updated_at: 2026-02-22
milestone: "M3"
depends_on: [TICKET-0022]
blocks: []
tags: [world, level, greybox, integration]
---

## Summary
Build a small, bounded greybox test level that serves as the M3 gameplay environment. This is a functional playground — not a polished biome. It contains the ship as a static landmark with a recharge zone, flat/gently rolling terrain, and scattered resource deposits at varying distances to test the full scan/mine loop.

## Acceptance Criteria
- [ ] Test level scene created (e.g., `game/scenes/levels/test_world.tscn`)
- [ ] Flat or gently rolling terrain — simple MeshInstance3D or CSG geometry, greybox only
- [ ] Bounded play area — invisible walls, kill zone, or terrain walls to keep the player in bounds
- [ ] Ship exterior mesh placed as a static landmark (`game/assets/meshes/vehicles/mesh_ship_exterior.glb`)
- [ ] Ship has a recharge zone (Area3D) that triggers suit battery recharging (TICKET-0023)
- [ ] Player spawns at or near the ship
- [ ] 8–12 resource deposit instances placed at varying distances from the ship
- [ ] Deposits configured with varying purity (1–5) and density (Low/Med/High) to test analysis readout
- [ ] At least one deposit placed near the ship (easy first find) and some placed at the edge of scanner range
- [ ] Basic lighting — directional light, no complex setup
- [ ] Basic skybox or clear color — functional, not polished
- [ ] Scene is set as the main scene or easily launchable for testing
- [ ] Player first-person controller (from M1) integrated and functional in the level
- [ ] Collision set up on terrain and ship so player cannot fall through

## Implementation Notes
- This is a greybox level — use simple geometry, placeholder materials, solid colors
- Reference `docs/design/systems/biomes.md` B001 (Overgrown Suburbs) for general vibe, but do not attempt to replicate the art direction
- The ship is NOT functional — it is a static mesh with only a recharge zone. No interior, no systems, no navigation
- Deposit placement should test various scanner scenarios: close, far, clustered, isolated
- This level will be used by QA (TICKET-0031) for the full loop test
- Prioritize getting this built early so other gameplay tickets have a world to test in
- Reference `docs/engineering/coding-standards.md` for naming conventions

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-22 [producer] Created ticket
