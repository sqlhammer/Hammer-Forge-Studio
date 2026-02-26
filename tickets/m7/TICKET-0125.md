---
id: TICKET-0125
title: "Refactoring phase gate — regression test suite"
type: TASK
status: TODO
priority: P1
owner: qa-engineer
created_by: producer
created_at: 2026-02-26
updated_at: 2026-02-26
milestone: "M7"
phase: "Refactoring"
depends_on: [TICKET-0111, TICKET-0112, TICKET-0113, TICKET-0114, TICKET-0115, TICKET-0116, TICKET-0117]
blocks: [TICKET-0126]
tags: [qa, regression, testing, phase-gate]
---

## Summary

Run the full existing test suite after all 7 scene-architecture refactors (TICKET-0111 through TICKET-0117) are complete. The refactors extract embedded game objects into standalone instanced scenes — this regression test ensures nothing broke during the extraction.

This ticket serves as the Refactoring phase gate check. All prior milestone test suites (M1–M6) must continue to pass with zero failures.

## Acceptance Criteria

- [ ] Full test suite executed via `res://addons/hammer_forge_tests/test_runner.tscn`
- [ ] All existing tests pass with zero failures (same pass count as M6 close-out or higher)
- [ ] No new parse errors or runtime warnings introduced by the refactors
- [ ] If any test fails, a BUGFIX ticket is created and the phase gate does not pass until resolved
- [ ] Test results documented in this ticket's Activity Log

## Implementation Notes

- Run the test runner in editor (not headless) to catch any scene loading errors
- Pay special attention to tests that reference specific node paths — refactored scenes may have changed internal paths
- Check that all instanced scenes load without errors in the editor's scene tree

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-26 [producer] Created ticket — refactoring phase gate regression
