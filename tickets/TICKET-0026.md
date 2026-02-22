---
id: TICKET-0026
title: "Mining interaction"
type: FEATURE
status: OPEN
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-22
updated_at: 2026-02-22
milestone: "M3"
depends_on: [TICKET-0021, TICKET-0023, TICKET-0025]
blocks: [TICKET-0027]
tags: [mining, tools, gameplay, interaction]
---

## Summary
Implement the mining interaction: the player holds Use Tool near an analyzed deposit to extract resources. Mining drains the suit battery, fills inventory, and depletes the deposit over multiple extractions. The hand drill is the only tool in M3.

## Acceptance Criteria
- [ ] Player aims at an analyzed deposit within proximity range (close but not touching — configurable distance)
- [ ] Player holds Use Tool input (Left Mouse / Right Trigger per input-system.md) to begin extraction
- [ ] Mining progress indicator displayed during extraction (per wireframe spec from TICKET-0019)
- [ ] Each extraction takes a configurable duration (e.g., 2–4 seconds of continuous hold)
- [ ] Suit battery drains during extraction (rate from TICKET-0023)
- [ ] On extraction complete: resource added to inventory (TICKET-0021), deposit quantity decremented (TICKET-0022)
- [ ] Resource pickup notification displayed showing what was collected and quantity
- [ ] If battery reaches 0% during extraction: extraction is cancelled, partial progress lost
- [ ] Cannot mine a deposit that has not been analyzed (Phase 2 must come first)
- [ ] Cannot mine when suit battery is at 0%
- [ ] Deposit yields 3–5 extractions before depletion (per deposit instance configuration)
- [ ] Depleted deposit changes visual state and can no longer be mined
- [ ] If inventory is full: extraction is prevented, player is notified
- [ ] Hand drill mesh (`game/assets/meshes/tools/mesh_hand_drill.glb`) visible in first-person view during mining (basic — held position, no animation required)
- [ ] Proximity check: player must be close to the node but not right up against it
- [ ] Input routed through InputManager (no direct Input API calls)

## Implementation Notes
- M3 simplification: no mining minigame (trace lit lines). Hold-to-extract only. See `docs/studio/deferred-items.md`.
- Reference `docs/design/systems/meaningful-mining.md` for full mining spec including the deferred minigame
- Reference `docs/design/systems/input-system.md` for Use Tool binding (Left Mouse / Right Trigger)
- Proximity range should be larger than melee range but require intentional approach — playtest to feel right
- The hand drill viewmodel (first-person held item) can be a simple mesh instance positioned relative to the camera — no animation, rig, or state machine needed for M3
- Consider using a raycast from camera center to detect aimed deposit within range
- Reference `docs/engineering/coding-standards.md` for naming conventions

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-22 [producer] Created ticket
