---
id: TICKET-0070
title: "Mining minigame — line tracing for yield bonus"
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
depends_on: [TICKET-0065, TICKET-0083]
blocks: [TICKET-0075]
tags: [mining, minigame, gameplay, yield-bonus]
---

## Summary
Implement the mining minigame: after Phase 2 Analysis reveals the deposit's mining pattern, the player can trace lit lines on the deposit geometry during extraction to earn a +50% yield bonus. Tracing is optional — missing lines or ignoring the minigame yields only the base quantity with no penalty. Implements deferred item D-002.

## Acceptance Criteria
- [ ] After Phase 2 Analysis, mining pattern lines (1–4, based on deposit tier) are illuminated on the deposit geometry
- [ ] During extraction hold, the player can trace the lit lines using the mining cursor / reticle
- [ ] Successful full trace of all lines before extraction completes awards +50% bonus yield
- [ ] Partial trace awards no bonus (all-or-nothing per line); failing a line does not abort extraction
- [ ] Ignoring the minigame entirely yields base quantity with no penalty
- [ ] Tier 1 deposits (M5 scope) show 1–2 lines — simpler patterns appropriate for tutorial-tier content
- [ ] Bonus yield notification displayed on extraction completion (consistent with existing pickup notifications)
- [ ] Minigame overlay follows design from TICKET-0065 wireframes
- [ ] Drones do not perform the minigame — drone extraction always yields base quantity (enforced at drone level, not minigame level)
- [ ] All code follows `docs/engineering/coding-standards.md`

## Implementation Notes
- Reference `docs/design/systems/meaningful-mining.md` for full minigame spec and design intent
- Reference deferred item D-002 in `docs/studio/deferred-items.md`
- The minigame should feel like a natural extension of the hold-to-extract interaction — not a separate mode
- Pattern complexity (line count) should be read from deposit data, not hardcoded in minigame logic
- Baseline bonus is +50% of base yield; per-resource-type multiplier variation is a future tuning pass

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-24 [producer] Created ticket
