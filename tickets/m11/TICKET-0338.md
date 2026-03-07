---
id: TICKET-0338
title: "VERIFY — BUG fix: compass_bar no longer causes infinite loop during terrain generation (TICKET-0310)"
type: TASK
status: TODO
priority: P1
owner: play-tester
created_by: producer
created_at: 2026-03-07
updated_at: 2026-03-07
milestone: "M11"
phase: "QA"
depends_on: [TICKET-0310]
blocks: []
tags: [verify, bug, compass-bar, terrain-generation]
---

## Summary

Verify that biome loading completes without infinite-loop hangs or timeouts in
compass_bar._on_tree_node_added after the fix in TICKET-0310.

---

## Acceptance Criteria

- [ ] Visual verification: Traveling to each biome (Shattered Flats, Rock Warrens,
      Debris Field) completes within a reasonable time — no hang or freeze during terrain
      generation
- [ ] Visual verification: Compass bar displays correctly after biome load — no missing
      or broken compass markers
- [ ] State dump: No quantitative assertions required; check for ERROR-free console
      (no infinite recursion or stack overflow errors)
- [ ] Unit test suite: zero failures across all tests
- [ ] No runtime errors during any verification scenario

---

## Handoff Notes

(Leave blank until verification is complete.)

---

## Activity Log

- 2026-03-07 [producer] Created VERIFY ticket for TICKET-0310 — BUG: compass_bar infinite loop fix
