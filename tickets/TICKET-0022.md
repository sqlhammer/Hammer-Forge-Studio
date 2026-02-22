---
id: TICKET-0022
title: "Deposit system — data layer"
type: FEATURE
status: OPEN
priority: P1
owner: systems-programmer
created_by: producer
created_at: 2026-02-22
updated_at: 2026-02-22
milestone: "M3"
depends_on: [TICKET-0020]
blocks: [TICKET-0024, TICKET-0025, TICKET-0029]
tags: [deposits, mining, systems, data]
---

## Summary
Implement the deposit data layer — the system that defines resource deposits in the world, tracks their state (scanned, analyzed, depleted), and exposes an API for the scanner and mining systems to interact with. Each deposit has a resource type, purity, quantity, and depletion state.

## Acceptance Criteria
- [ ] Deposit data structure defined: resource type, purity (1–5), density (Low/Med/High), quantity remaining, energy cost to mine, scan state (undiscovered/pinged/analyzed), depleted flag
- [ ] Deposit node implemented as a scene/script that can be placed in the world (extends Node3D or StaticBody3D)
- [ ] API: `ping() -> void` — marks deposit as pinged (discoverable by scanner Phase 1)
- [ ] API: `analyze() -> Dictionary` — returns purity, density, energy cost; marks deposit as analyzed
- [ ] API: `extract(amount) -> Dictionary` — removes quantity, returns resource_id and quantity extracted; sets depleted when empty
- [ ] API: `is_depleted() -> bool`
- [ ] Deposits yield 3–5 extractions before depletion (configurable per deposit instance)
- [ ] Depleted deposits do not respawn
- [ ] Depleted deposits change visual state (mesh swap, transparency, or removal — minimal implementation acceptable)
- [ ] Deposits use the M2 resource node mesh (`game/assets/meshes/props/mesh_resource_node_scrap.glb`)
- [ ] Unit tests written and passing for deposit state transitions and extraction logic

## Implementation Notes
- Reference `docs/design/systems/meaningful-mining.md` for deposit tier and purity systems
- M3 scope: all deposits are Tier 1 (Hand Drill only), Scrap Metal only
- Purity and density should still vary per deposit instance to test the analysis readout
- The deposit scene should be drag-and-droppable into the greybox world (TICKET-0029)
- Consider using `@export` variables for per-instance configuration in the editor
- Reference `docs/engineering/coding-standards.md` for naming conventions

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-22 [producer] Created ticket
