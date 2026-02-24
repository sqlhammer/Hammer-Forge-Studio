---
id: TICKET-0064
title: "Mining drone system — data layer and Automation Hub"
type: FEATURE
status: OPEN
priority: P1
owner: systems-programmer
created_by: producer
created_at: 2026-02-24
updated_at: 2026-02-24
milestone: "M5"
milestone_gate: "M4"
phase: "Foundation"
depends_on: [TICKET-0060, TICKET-0061]
blocks: [TICKET-0072]
tags: [drones, automation, automation-hub, data]
---

## Summary
Define the data layer for the mining drone system and its host module, the Automation Hub. The Automation Hub is a ship module unlocked via the tech tree (requires Fabricator unlocked). It enables mining drones — autonomous agents that execute extraction on analyzed deposits without player intervention. Implements deferred item D-009.

## Acceptance Criteria
- [ ] `AutomationHubModule` defined extending the existing module base class (M4 module system)
- [ ] Module gated behind tech tree node `automation_hub` (requires `fabricator_module` unlocked)
- [ ] `DroneProgram` resource defined with: target deposit type filter, minimum purity filter, tool tier assignment, extraction radius, priority order
- [ ] `DroneAgent` data defined: assigned program, current target deposit ID, state machine (idle / traveling / extracting / returning)
- [ ] Constraint enforced: a deposit may only be assigned as a drone target if the player has completed Phase 2 Analysis on it
- [ ] Drone energy consumption drawn from ship Power (ShipState) — not player suit battery
- [ ] Max simultaneous active drones: defined as a constant on AutomationHub tier (placeholder: 2 for Tier 1)
- [ ] Signals: `drone_started(deposit_id)`, `drone_completed(deposit_id, yield)`, `drone_returned`
- [ ] All code follows `docs/engineering/coding-standards.md`

## Implementation Notes
- Reference `docs/design/systems/meaningful-mining.md` for the full drone design spec and scanner-first constraint
- Reference `docs/design/systems/mobile-base.md` for module categories and power draw behavior
- Design doc originally listed Extraction Bay as prerequisite for Automation Hub; M5 uses Fabricator as the prerequisite instead (approved deviation — Studio Head confirmed 2026-02-24)
- Automation Hub unlock cost (tech tree) is TBD — confirm with Studio Head before TICKET-0072 implementation
- Physical drone visuals and world behavior are implemented in TICKET-0072

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-24 [producer] Created ticket
