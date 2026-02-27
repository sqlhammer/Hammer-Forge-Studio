---
id: TICKET-0159
title: "Navigation system — biome registry, travel state machine, fuel cost calculation"
type: FEATURE
status: IN_PROGRESS
priority: P1
owner: systems-programmer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "M8"
phase: "Foundation"
depends_on: [TICKET-0158]
blocks: []
tags: [navigation, biome-registry, travel, state-machine, m8-foundation]
---

## Summary

Implement the navigation system: a biome registry that defines all available biomes, their seeds, distances from each other, and resource profiles; a travel state machine that manages the jump sequence; and fuel cost calculation integrated with the fuel system.

This system is the backbone of ship travel — every biome ticket, the navigation console UI, the travel sequence, and the respawn system depend on it.

## Acceptance Criteria

- [ ] `BiomeRegistry` — data resource defining all biomes, each with:
  - Unique ID, display name, description
  - Terrain seed (integer) — fixed per biome, consistent layout on every visit
  - Distance values to every other biome (used for fuel cost)
  - Resource profile summary (informational — used by biome scene tickets)
- [ ] Three biomes registered at minimum: `shattered_flats`, `rock_warrens`, `debris_field`
- [ ] `NavigationSystem` autoload or ship subsystem with:
  - `current_biome: String` — tracks where the ship currently is
  - `get_travel_cost(destination_id: String) -> float` — returns fuel cost via FuelSystem formula
  - `can_travel_to(destination_id: String) -> bool` — wraps FuelSystem.can_travel()
  - `initiate_travel(destination_id: String)` — triggers travel state machine
  - Travel states: `IDLE → PREPARING → IN_TRANSIT → ARRIVING → IDLE`
  - `travel_completed` signal — fires on arrival, passes destination biome ID
  - `travel_blocked` signal — fires if travel attempted without sufficient fuel
- [ ] NavigationSystem calls FuelSystem.consume_fuel() on travel initiation
- [ ] NavigationSystem emits `biome_changed` signal on arrival (consumed by resource respawn system in TICKET-0161)
- [ ] Unit tests cover: registry lookup, travel cost calculation, travel blocked when fuel insufficient, state machine transitions, biome_changed signal fires on arrival
- [ ] Full test suite passes

## Implementation Notes

- Biome distances should be defined symmetrically (A→B == B→A) in the registry
- Travel state machine should be simple — no animation logic here, that belongs to TICKET-0168
- The `biome_changed` signal is the sole integration point for TICKET-0161 (respawn) and TICKET-0168 (travel sequence)
- Resolves deferred item D-004 (ship navigation between biomes, deferred from M3)

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created — M8 Foundation phase. Resolves D-004.
- 2026-02-27 [systems-programmer] Starting work — implementing BiomeRegistry, NavigationSystem autoload, unit tests.
