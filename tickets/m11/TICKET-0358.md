---
id: TICKET-0358
title: "VERIFY — BUG fix: Tech tree panel opens via terminal interaction in ship interior (TICKET-0355)"
type: TASK
status: OPEN
priority: P1
owner: play-tester
created_by: producer
created_at: 2026-03-08
updated_at: 2026-03-08
milestone: "M11"
phase: "QA"
depends_on: [TICKET-0355]
blocks: []
tags: [auto-created]
---

## Summary

Verify that pressing interact near the tech tree terminal in the ship interior opens the TechTreePanel with correct node display.

## Acceptance Criteria

- [ ] Visual verification: Player walks to the tech tree terminal in the ship interior, presses E (interact), and the TechTreePanel opens showing at least two nodes — Fabricator (UNLOCKABLE) and Automation Hub (LOCKED) — with icons, labels, and unlock costs visible
- [ ] Visual verification: Detail panel updates when selecting different tech tree nodes; Unlock button is enabled for Fabricator and disabled for Automation Hub (requires Fabricator prerequisite)
- [ ] State dump: TechTreePanel.is_open() returns true after terminal interaction; no null reference errors in output
- [ ] Unit test suite: zero failures across all tests
- [ ] No runtime errors during any verification scenario

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-03-08 [conductor] Created via orchestration wave 44
