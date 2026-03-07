---
id: TICKET-0344
title: "VERIFY — BUG fix: Resource nodes render correctly above terrain surface (TICKET-0316)"
type: TASK
status: TODO
priority: P1
owner: play-tester
created_by: producer
created_at: 2026-03-07
updated_at: 2026-03-07
milestone: "M11"
phase: "QA"
depends_on: [TICKET-0316]
blocks: []
tags: [verify, bug, resource-nodes, terrain-surface, rendering]
---

## Summary

Verify that resource nodes render as visible 3D meshes above the terrain surface (not as
floating white dots below it) after the fix in TICKET-0316.

---

## Acceptance Criteria

- [ ] Visual verification: Resource nodes in each biome appear as distinct 3D objects
      (ore deposits, crystal formations, etc.) resting on or above the terrain surface
- [ ] Visual verification: No resource nodes render as white dots or appear embedded below
      the terrain mesh
- [ ] Visual verification: Scanner ping highlights resource nodes at their correct
      above-ground positions; compass markers point to valid locations
- [ ] State dump: No quantitative assertions required; check for ERROR-free console
- [ ] Unit test suite: zero failures across all tests
- [ ] No runtime errors during any verification scenario

---

## Handoff Notes

(Leave blank until verification is complete.)

---

## Activity Log

- 2026-03-07 [producer] Created VERIFY ticket for TICKET-0316 — BUG: Resource nodes floating white dots fix
