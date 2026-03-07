---
id: TICKET-0326
title: "VERIFY — Scene-First remediation: Ship Interior full scene refactor (TICKET-0297)"
type: TASK
status: TODO
priority: P1
owner: play-tester
created_by: producer
created_at: 2026-03-07
updated_at: 2026-03-07
milestone: "M11"
phase: "QA"
depends_on: [TICKET-0297]
blocks: []
tags: [verify, scene-first, ship-interior]
---

## Summary

Verify that the ship interior loads with all module zones accessible after the large
Scene-First refactor of ship_interior.gd (60+ nodes moved to .tscn) in TICKET-0297.

---

## Acceptance Criteria

- [ ] Visual verification: Boarding the ship loads the ship interior without errors or
      missing nodes; all four module zones are present (Fabricator, Recycler, Automation
      Hub, Navigation Console)
- [ ] Visual verification: Each module zone is interactable — panels open without errors
- [ ] Visual verification: Exiting the ship returns to the exterior world intact
- [ ] State dump: No quantitative assertions required; check for ERROR-free console
- [ ] Unit test suite: zero failures across all tests
- [ ] No runtime errors during any verification scenario

---

## Handoff Notes

(Leave blank until verification is complete.)

---

## Activity Log

- 2026-03-07 [producer] Created VERIFY ticket for TICKET-0297 — Scene-First: Ship Interior
