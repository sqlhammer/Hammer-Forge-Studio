---
id: TICKET-0039
title: "Ship global variables — data layer"
type: FEATURE
status: DONE
priority: P1
owner: systems-programmer
created_by: producer
created_at: 2026-02-23
updated_at: 2026-02-23
milestone: "M4"
milestone_gate: "M3"
depends_on: []
blocks: [TICKET-0040, TICKET-0046, TICKET-0047]
tags: [ship, data, architecture]
---

## Summary
Define the data model for the ship's four global variables: Power, Integrity, Heat, and Oxygen. Includes baseline power behavior (always-on low output sufficient to recharge the player's suit and run one Tier 1 machine), value clamping, and signal emission on change.

## Acceptance Criteria
- [ ] ShipState resource/autoload defined with Power, Integrity, Heat, Oxygen (0.0–100.0 float range)
- [ ] Baseline power value defined as a constant — sufficient to recharge player suit and run one Tier 1 machine simultaneously
- [ ] Baseline power generation is always-on and cannot be disabled
- [ ] Signals emitted on each variable change (e.g., `ship_power_changed`, `ship_integrity_changed`, `ship_heat_changed`, `ship_oxygen_changed`)
- [ ] Values clamped to 0.0–100.0 on all write operations
- [ ] Data model extensible for future drain/recharge systems (module power draw, navigation fuel consumption)
- [ ] Architect documents the chosen pattern (autoload vs. resource) in implementation notes
- [ ] All code follows `docs/engineering/coding-standards.md`

## Implementation Notes
- Reference `docs/design/systems/mobile-base.md` for the full ship global variable spec and intended behavior
- M4 scope: data model and signals only — drain/recharge gameplay mechanics come in later milestones
- Baseline power is a design floor guarantee: the player can always recharge their suit and run the Recycler even with no additional power modules installed
- Consider a `ShipState` autoload to make variables globally accessible — consistent with `InputManager` and `Global` patterns

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-23 [producer] Created ticket
- 2026-02-23 [systems-programmer] Implemented: ShipState autoload with Power/Integrity/Heat/Oxygen (0.0-100.0 clamped), BASELINE_POWER=30.0, change signals, module power draw registration/deregistration, adjust/reset helpers. Pattern: autoload (consistent with InputManager/Global)
