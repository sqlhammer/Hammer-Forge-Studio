---
id: TICKET-0259
title: "Code Quality: Use DeepResourceNode in biome scenes instead of Deposit.new(infinite=true)"
type: TASK
status: OPEN
priority: P3
owner: systems-programmer
created_by: producer
created_at: 2026-03-01
updated_at: 2026-03-01
milestone: "M9"
phase: "Code Quality"
depends_on: [TICKET-0235]
blocks: []
tags: [code-quality, m8-cleanup, biome, deep-resource-node, deposit, architecture]
---

## Summary

Biome scripts currently instantiate deep resource nodes using `Deposit.new()` with `infinite = true` set manually, bypassing the purpose-built `DeepResourceNode` class entirely. The `DeepResourceNode` class was added to M8 specifically to encapsulate deep-node defaults (infinite yield, drone-only, etc.), but it is never used in production code. This inconsistency is confusing — the class exists but does nothing. Either adopt `DeepResourceNode` where appropriate, or remove it.

## Acceptance Criteria

- [ ] Each biome script's deep-node construction is updated to use `DeepResourceNode.new()` instead of `Deposit.new()` with manual `infinite = true`
- [ ] Any properties that `DeepResourceNode` consolidates as defaults no longer need to be set explicitly at the call site
- [ ] If `DeepResourceNode` is missing a property needed at the call site, add it to the class rather than reverting to the manual approach
- [ ] All biome scenes load without errors
- [ ] Deep resource nodes still behave identically in-game (infinite yield, drone-minable, same scan behavior)
- [ ] Full test suite passes with no new failures

## Implementation Notes

- Locate biome scripts: `grep -rn "infinite = true" game/scripts/`
- `DeepResourceNode` likely extends `Deposit` — confirm its definition before changing call sites
- If `DeepResourceNode` is trivially identical to `Deposit` with `infinite = true` and has no other value, document that finding in the activity log and close the ticket as "assessed, no change needed" — do not force an abstraction that adds no value

## Activity Log

- 2026-03-01 [producer] Created — deferred item D-027 from M8 code review (TICKET-0177); scheduled for M9 Code Quality phase
