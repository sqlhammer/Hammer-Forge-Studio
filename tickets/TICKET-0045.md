---
id: TICKET-0045
title: "Recycler interaction panel UI"
type: FEATURE
status: OPEN
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-23
updated_at: 2026-02-23
milestone: "M4"
milestone_gate: "M3"
depends_on: [TICKET-0041, TICKET-0042, TICKET-0044]
blocks: [TICKET-0048]
tags: [ship, recycler, ui, crafting]
---

## Summary
Implement the Recycler's interaction panel. The player opens the panel by interacting with the installed Recycler, queues a Scrap Metal → Metal job, monitors progress, and collects the Metal output into their inventory.

## Acceptance Criteria
- [ ] Panel opens on interact input when facing the installed Recycler
- [ ] Input slot: player can select Scrap Metal from their inventory to queue a job
- [ ] Active job display: shows current recipe, progress bar or timer
- [ ] Output slot: Metal appears when job completes, ready to collect
- [ ] Collect button/input adds Metal to player inventory
- [ ] Cancel input closes the panel without interrupting an active job
- [ ] Panel reflects live job state — progress updates while panel is open
- [ ] Insufficient input resource is communicated clearly (feedback, not a silent failure)
- [ ] Follows wireframe from TICKET-0042 and M3 UI style guide
- [ ] All input routed through InputManager
- [ ] Input context switches correctly — game input suppressed while panel is open
- [ ] No Godot editor errors or warnings

## Implementation Notes
- Reference the Recycler job queue API from TICKET-0041
- Reference the inventory API from TICKET-0021 for reading and deducting player resources
- Panel should close gracefully if the player exits the ship while it is open
- M4 scope: one active job at a time — multi-job queuing deferred

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-23 [producer] Created ticket
