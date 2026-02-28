---
id: TICKET-0217
title: "Bugfix — Ship recharge zone does not recharge player in biomes; ensure recharge area is part of the ship scene"
type: BUGFIX
status: IN_PROGRESS
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-28
updated_at: 2026-02-28
milestone: "M8"
phase: "QA"
depends_on: []
blocks: []
tags: [bugfix, ship, recharge, suit-battery, biome, scene-architecture, m8-qa]
---

## Summary

The ship's recharge zone does not recharge the player's suit battery in any biome. In TestWorld the recharge zone works correctly because `TestWorld.gd` explicitly connects `ship_exterior.recharge_zone_entered` and `recharge_zone_exited` signals and calls `SuitBattery.start_recharge()` / `stop_recharge()`. This wiring is absent in the biome gameplay context. Additionally, the recharge zone must be confirmed as a child of the ship scene itself so it travels with the ship to every biome automatically.

## Steps to Reproduce

1. Launch any biome via the debug launcher or normal travel
2. Deplete the player's suit battery by mining
3. Walk toward the ship hull and into the recharge zone area
4. Observe: suit battery does not recharge

## Expected Behavior

When the player enters the ship's recharge zone in any biome, `SuitBattery.start_recharge()` is called and the battery recharges. When the player leaves, `SuitBattery.stop_recharge()` is called. This behavior is identical to TestWorld.

## Acceptance Criteria

- [ ] Player suit battery recharges when standing in the ship's recharge zone in all biomes (Shattered Flats, Rock Warrens, Debris Field)
- [ ] `SuitBattery.stop_recharge()` is called when the player exits the zone
- [ ] The recharge zone is a child node of the ship exterior scene (`ship_exterior.tscn`) so it loads automatically with the ship into any biome — no per-biome or per-level wiring needed beyond the scene
- [ ] Recharge behavior in TestWorld is not regressed
- [ ] Full test suite passes with no new failures

## Implementation Notes

- The recharge zone signal wiring currently exists only in `test_world.gd` (`_on_recharge_zone_entered` / `_on_recharge_zone_exited`); the biome gameplay controller (or `TravelSequenceManager`) does not connect these signals
- Preferred fix: move the recharge logic into `ShipExterior` itself — `ShipExterior._on_body_entered_recharge()` already fires the signal; extend it to directly call `SuitBattery.start_recharge()` when the entering body is the player, eliminating the need for any external signal wiring. Apply the same to `_on_body_exited_recharge()`
- Confirm that `RechargeZone` (the `Area3D` child) is a node in `ship_exterior.tscn` and not added procedurally by `TestWorld` — if it is procedurally added by TestWorld only, it must be moved into the scene file
- Verify `_update_recharge(delta)` equivalent logic (calling `SuitBattery.process_recharge(delta)`) is called every frame in the biome gameplay context; if it is only in `TestWorld._process()`, it must also be driven from the biome scene or from `ShipExterior._process()`

## Activity Log

- 2026-02-28 [producer] Created — Studio Head reported during M8 playtest
- 2026-02-28 [gameplay-programmer] Starting work — moving recharge logic into ShipExterior
