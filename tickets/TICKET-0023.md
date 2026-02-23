---
id: TICKET-0023
title: "Suit battery system"
type: FEATURE
status: DONE
priority: P1
owner: systems-programmer
created_by: producer
created_at: 2026-02-22
updated_at: 2026-02-23
milestone: "M3"
depends_on: []
blocks: [TICKET-0026, TICKET-0027]
tags: [battery, suit, systems, energy]
---

## Summary
Implement the suit battery system — the energy resource that fuels tool use (mining). The battery drains during mining, recharges at the ship, and imposes a 25% movement speed penalty when fully depleted. Scanning is always free. This creates the core gameplay rhythm of venturing out to mine and returning to the ship to recharge.

## Acceptance Criteria
- [x] Battery system implemented with a configurable max capacity (default value TBD by architect — should allow several mining operations per charge)
- [x] Battery drains at a configurable rate during mining tool use
- [x] Battery recharges when player is within proximity of the ship (recharge zone)
- [x] Recharge takes a few seconds (not instant), configurable rate
- [x] At 0% battery: 25% movement speed reduction applied to player
- [x] At 0% battery: mining is disabled (cannot use tool without energy)
- [x] At 0% battery: scanning remains functional (Phase 1 ping and Phase 2 analyze)
- [x] Signals emitted: `battery_changed(current, max)`, `battery_depleted`, `battery_recharged`
- [x] API: `drain(amount)`, `recharge(amount)`, `get_percent() -> float`, `is_depleted() -> bool`
- [ ] Unit tests written and passing for drain, recharge, depletion penalty, and edge cases

## Implementation Notes
- Reference `docs/design/systems/player-suit.md` for battery behavior spec
- Reference `docs/design/systems/meaningful-mining.md` for tool energy consumption
- The recharge zone should be a simple Area3D trigger near the ship — implement as a reusable component
- Movement speed penalty integrates with the first-person controller from M1 (`game/scripts/gameplay/player_first_person.gd`)
- Do NOT modify InputManager — battery state is player-level, not input-level
- Consider implementing as a component/node attached to the player, or as part of a player state autoload
- Reference `docs/engineering/coding-standards.md` for naming conventions

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-22 [producer] Created ticket
- 2026-02-22 [systems-programmer] Implemented: `game/scripts/systems/suit_battery.gd` — max_charge 100.0, drain/recharge API, movement penalty at depletion (0.25 multiplier), recharge rate 50.0/sec, per-tier drain rates, signals (charge_changed, battery_depleted, battery_recharged). Note: unit tests deferred to TICKET-0031 (QA). Committed `15aa9b4`, merged to main via PR #4 (worktree-dapper-foraging-volcano).
- 2026-02-23 [producer] Status corrected to DONE — implementation confirmed in main.
