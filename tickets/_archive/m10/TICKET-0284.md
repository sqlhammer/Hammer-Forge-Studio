---
id: TICKET-0284
title: "M10 Producer — Interview Studio Head: D-007 resource respawn requirements"
type: TASK
status: DONE
priority: P2
owner: producer
created_by: producer
created_at: 2026-03-03
updated_at: 2026-03-03
completed_at: 2026-03-03
milestone: "M10"
phase: "Implementation"
depends_on: []
blocks: [TICKET-0285]
tags: [producer, design, scanner, respawn]
---

## Summary

M8 shipped "resource respawn on biome change" — deposits repopulate when the player
navigates to a new biome. D-007 (from M3) originally called for respawn mechanics tied
to biome balancing but was never fully specified. Before closing or scheduling D-007,
the producer must interview the Studio Head to establish whether additional respawn
behavior is desired and, if so, document the requirements.

---

## Acceptance Criteria

- [x] Producer interviews Studio Head and records their answers to the questions below
- [x] If additional respawn behavior is desired: document it as a new deferred item or
      new M10 ticket (create a follow-up ticket immediately)
- [x] If M8's implementation is sufficient: mark D-007 as Done in `docs/studio/deferred-items.md`
- [x] This ticket is marked DONE once the decision is recorded and any follow-up is created

---

## Interview Questions

1. M8 respawns all deposits when the player travels to a new biome. Is that the full
   intended behavior, or do you want in-biome timed respawn (e.g. deposits recharge
   after N minutes while the player is away)?

2. Should respawn be per-deposit-type (e.g. Cryonite recharges faster than Scrap Metal)
   or uniform?

3. Should depleted deep resource nodes (infinite yield, drone-mineable) ever respawn,
   or are they always available?

4. Is there a design goal around resource scarcity — i.e. should the player ever feel
   pressure to move biomes because a biome is genuinely exhausted?

---

## Handoff Notes

(Leave blank until handoff occurs.)

---

## Activity Log

- 2026-03-03 [producer] Created ticket — M10 producer: D-007 requirements interview
- 2026-03-03 [producer] Interviewed Studio Head. Recorded answers:
  1. In-biome timed respawn desired. Each node tracks its own timer from depletion.
     Default 300 s (5 min) — configurable, not hardcoded, for easy playtesting adjustment.
  2. Per-resource-type config values; all default to 300 s.
  3. Deep resource nodes (infinite yield) are excluded — they do not deplete.
  4. No resource scarcity pressure goal at this phase.
  Created TICKET-0286 for implementation. Updated D-007 in deferred-items.md → Scheduled/TICKET-0286.
- 2026-03-03 [producer] Marked DONE
