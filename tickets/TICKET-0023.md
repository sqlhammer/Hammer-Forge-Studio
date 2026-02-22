---
id: TICKET-0023
title: "Suit battery system"
type: FEATURE
status: OPEN
priority: P1
owner: systems-programmer
created_by: producer
created_at: 2026-02-22
updated_at: 2026-02-22
milestone: "M3"
depends_on: []
blocks: [TICKET-0026, TICKET-0027]
tags: [battery, suit, systems, energy]
---

## Summary
Implement the suit battery system — the energy resource that fuels tool use (mining). The battery drains during mining, recharges at the ship, and imposes a 25% movement speed penalty when fully depleted. Scanning is always free. This creates the core gameplay rhythm of venturing out to mine and returning to the ship to recharge.

## Acceptance Criteria
- [ ] Battery system implemented with a configurable max capacity (default value TBD by architect — should allow several mining operations per charge)
- [ ] Battery drains at a configurable rate during mining tool use
- [ ] Battery recharges when player is within proximity of the ship (recharge zone)
- [ ] Recharge takes a few seconds (not instant), configurable rate
- [ ] At 0% battery: 25% movement speed reduction applied to player
- [ ] At 0% battery: mining is disabled (cannot use tool without energy)
- [ ] At 0% battery: scanning remains functional (Phase 1 ping and Phase 2 analyze)
- [ ] Signals emitted: `battery_changed(current, max)`, `battery_depleted`, `battery_recharged`
- [ ] API: `drain(amount)`, `recharge(amount)`, `get_percent() -> float`, `is_depleted() -> bool`
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
