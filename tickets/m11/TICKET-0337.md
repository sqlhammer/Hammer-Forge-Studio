---
id: TICKET-0337
title: "VERIFY — BUG fix: NavigationConsole includes debris_field in biome list (TICKET-0309)"
type: TASK
status: TODO
priority: P1
owner: play-tester
created_by: producer
created_at: 2026-03-07
updated_at: 2026-03-07
milestone: "M11"
phase: "QA"
depends_on: [TICKET-0309]
blocks: []
tags: [verify, bug, navigation-console, debris-field]
---

## Summary

Verify that the Navigation Console lists all three biomes including Debris Field — which
was missing from _biome_node_ids after the TICKET-0292 refactor — after fix in TICKET-0309.

---

## Acceptance Criteria

- [ ] Visual verification: Navigation Console opens; biome list contains exactly three
      entries — Shattered Flats, Rock Warrens, and Debris Field
- [ ] Visual verification: Selecting Debris Field and confirming travel successfully
      loads the Debris Field biome
- [ ] State dump: BIOME = "debris_field" in state dump after travelling to Debris Field
- [ ] Unit test suite: zero failures across all tests
- [ ] No runtime errors during any verification scenario

---

## Handoff Notes

(Leave blank until verification is complete.)

---

## Activity Log

- 2026-03-07 [producer] Created VERIFY ticket for TICKET-0309 — BUG: NavigationConsole missing debris_field
