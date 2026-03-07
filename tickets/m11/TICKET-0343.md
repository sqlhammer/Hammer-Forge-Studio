---
id: TICKET-0343
title: "VERIFY — BUG fix: Terrain features render with correct material (not grey boxes) (TICKET-0315)"
type: TASK
status: TODO
priority: P1
owner: play-tester
created_by: producer
created_at: 2026-03-07
updated_at: 2026-03-07
milestone: "M11"
phase: "QA"
depends_on: [TICKET-0315]
blocks: []
tags: [verify, bug, terrain-features, material, rendering]
---

## Summary

Verify that terrain features (plateaus, rock formations, clearings) render with correct
materials — not as untextured grey boxes — after the fix in TICKET-0315.

---

## Acceptance Criteria

- [ ] Visual verification: In Shattered Flats — terrain features are textured/shaded
      correctly; no flat grey geometry visible
- [ ] Visual verification: In Rock Warrens — rock corridor walls and features are
      textured correctly
- [ ] Visual verification: In Debris Field — any terrain features present use correct
      materials, not grey fallback
- [ ] State dump: No quantitative assertions required; check for ERROR-free console
      (no material-load errors)
- [ ] Unit test suite: zero failures across all tests
- [ ] No runtime errors during any verification scenario

---

## Handoff Notes

(Leave blank until verification is complete.)

---

## Activity Log

- 2026-03-07 [producer] Created VERIFY ticket for TICKET-0315 — BUG: Terrain features missing material
