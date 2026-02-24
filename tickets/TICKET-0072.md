---
id: TICKET-0072
title: "Automation Hub + drone system"
type: FEATURE
status: OPEN
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-24
updated_at: 2026-02-24
milestone: "M5"
milestone_gate: "M4"
phase: "Gameplay"
depends_on: [TICKET-0064, TICKET-0065, TICKET-0078, TICKET-0083]
blocks: [TICKET-0075]
tags: [drones, automation, automation-hub, gameplay]
---

## Summary
Implement the Automation Hub ship module and its mining drone system. The Automation Hub is installed in the ship after being unlocked via the tech tree. It enables the player to configure drone programs that autonomously extract from analyzed deposits. Drones are physical entities visible in the world. Implements deferred item D-009.

## Acceptance Criteria
- [ ] Automation Hub module can be installed in ship interior via existing module placement mechanic (M4) once tech tree node is unlocked
- [ ] Drone programming UI accessible from the Automation Hub (follows wireframes from TICKET-0065)
- [ ] Player can create and configure a drone program: deposit type filter, minimum purity, tool tier, extraction radius, priority order
- [ ] Only deposits previously Phase-2-analyzed by the player appear as assignable targets
- [ ] Drone programs can be started, paused, and stopped from the UI
- [ ] Active drones are physical entities present and visible in the game world — they travel to target deposits, extract, and return to ship
- [ ] Drone extraction yields base quantity only (no minigame bonus)
- [ ] Drone energy consumption deducted from ship Power (ShipState) — not player suit battery
- [ ] Max 2 simultaneous active drones at Tier 1 Automation Hub
- [ ] Drone status displayed in programming UI: idle / traveling / extracting / returning
- [ ] `drone_completed` signal triggers inventory update when drone returns with yield
- [ ] All code follows `docs/engineering/coding-standards.md`

## Implementation Notes
- Reference `docs/design/systems/meaningful-mining.md` for full drone spec and scanner-first constraint
- Reference TICKET-0064 for all data layer types and signals
- Reference TICKET-0065 wireframes for drone programming UI layout
- Drone visual assets: greybox placeholder meshes acceptable for M5 — polished drone art is a future milestone task
- The scanner-first constraint (player must have Phase 2 analyzed a deposit before it can be drone-targeted) is enforced at the data layer (TICKET-0064); gameplay-programmer should validate this in UI — do not expose unanalyzed deposits as options

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-24 [producer] Created ticket
- 2026-02-24 [producer] Added TICKET-0078 to depends_on — wireframes must be updated for non-pause model (DEC-0001) before implementation begins
