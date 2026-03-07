---
id: TICKET-0324
title: "VERIFY — Scene-First remediation: Tech Tree Panel (TICKET-0295)"
type: TASK
status: TODO
priority: P1
owner: play-tester
created_by: producer
created_at: 2026-03-07
updated_at: 2026-03-07
milestone: "M11"
phase: "QA"
depends_on: [TICKET-0295]
blocks: []
tags: [verify, scene-first, tech-tree]
---

## Summary

Verify that the Tech Tree panel opens with tech entries and prerequisites displayed correctly
after the Scene-First refactor in TICKET-0295.

---

## Acceptance Criteria

- [ ] Visual verification: Tech tree panel opens; entries are listed with icons and labels
- [ ] Visual verification: Selecting a tech with prerequisites shows those prerequisites
      (not blank/empty)
- [ ] Visual verification: Unlocking an available tech (with required resources) succeeds
      and updates the tech tree display
- [ ] State dump: No quantitative assertions required; check for ERROR-free console
- [ ] Unit test suite: zero failures across all tests
- [ ] No runtime errors during any verification scenario

---

## Handoff Notes

(Leave blank until verification is complete.)

---

## Activity Log

- 2026-03-07 [producer] Created VERIFY ticket for TICKET-0295 — Scene-First: Tech Tree Panel
