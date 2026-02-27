---
id: TICKET-0161
title: "Resource respawn system — biome-change trigger, surface node respawn logic"
type: FEATURE
status: IN_PROGRESS
priority: P1
owner: systems-programmer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "M8"
phase: "Foundation"
depends_on: [TICKET-0159]
blocks: []
tags: [resource, respawn, biome, m8-foundation]
---

## Summary

Surface resource nodes respawn when the ship changes biomes. When the player travels to a different biome and returns, all depleted surface nodes in the previously visited biome are restored to full stock. Deep nodes (infinite) are excluded from respawn logic. This creates a meaningful travel loop — leaving a biome and returning refreshes its resources.

## Acceptance Criteria

- [ ] Respawn system listens to `NavigationSystem.biome_changed` signal
- [ ] On biome change, all depleted surface nodes in the **departed** biome are marked for respawn
- [ ] On arrival back at a previously visited biome, respawned nodes are restored to full stock
- [ ] Deep nodes (`infinite: true`) are explicitly excluded from respawn logic
- [ ] Respawn state is tracked per-biome (departing and re-entering correctly restores the right biome's nodes)
- [ ] Respawn does NOT trigger on the initial visit to a biome (only on return after departure)
- [ ] Unit tests cover: respawn fires on biome change, deep nodes excluded, correct biome targeted, no respawn on first visit, repeated departure/return cycles
- [ ] Full test suite passes

## Implementation Notes

- Biome node state (depleted/full) should be stored in a dictionary keyed by biome ID so multiple biomes can have independent respawn states
- The trigger is purely biome-change driven — no timers, no passive regeneration
- This is a data/logic system only; the physical node visibility/reset is handled in the biome scene tickets (TICKET-0170–0172)

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created — M8 Foundation phase
- 2026-02-27 [systems-programmer] Starting work — merged main (includes TICKET-0159 NavigationSystem), implementing ResourceRespawnSystem autoload
