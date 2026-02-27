---
id: TICKET-0131
title: "Establish Red/Green TDD process — guidelines and conventions for M8"
type: TASK
status: DONE
priority: P1
owner: producer
created_by: producer
created_at: 2026-02-26
updated_at: 2026-02-26
milestone: "M8"
phase: "TDD Foundation"
depends_on: []
blocks: []
tags: [testing, process, tdd, standards, m8-foundation]
---

## Summary

Establish a formal Red/Green Test-Driven Development (TDD) pattern as the foundational process for M8. This ticket defines how all subsequent M8 work will be written: test first (RED), code to pass (GREEN), refactor as needed. This process ensures code quality, edge-case coverage, and maintainability across the navigation system, fuel mechanics, and biome travel features.

## Acceptance Criteria

- [x] M8 TDD Process Guide created in `docs/studio/` documenting:
  - Red/Green/Refactor cycle definition and cadence
  - Test-first expectations (unit tests written before feature code)
  - Minimum coverage targets per system (e.g., navigation 85%, fuel 80%, travel mechanics 75%)
  - Failure case coverage requirements (e.g., edge cases, invalid input, state transitions)
- [x] Code Review Standards Updated in `docs/engineering/coding-standards.md` to reinforce:
  - TDD compliance checklist (every feature PR must show passing unit tests written first)
  - Red-phase test failures must be documented in commit history or PR description
  - Approval gate: code review cannot proceed until test suite passes
- [x] Phase Gate Regression Test Template created/updated (`docs/studio/templates/phase-gate-regression-template.md`):
  - Reusable structure for all M8 phase gate regression suites
  - Checklist: test count, coverage %, zero failures, cross-milestone validation
  - Integration with M7 test suite to ensure no regressions
- [x] M8-Specific Test Coverage Guidelines (`docs/studio/guidelines/m8-test-guidelines.md`):
  - Navigation system test patterns (pathfinding, waypoint detection, travel validation)
  - Fuel consumption calculation and edge cases
  - Biome transition logic and state management
  - Common pitfalls and how to avoid them
- [ ] All documents reviewed and approved by systems-programmer and qa-engineer before other M8 work begins

## Implementation Notes

- This is a **prerequisite gate** — all other M8 phases depend on completion of this ticket
- The goal is to establish **process rigor** that elevates code quality across the navigation overhaul
- Red/Green testing is a best practice; this ticket makes it a hard requirement for M8
- Use M7 testing patterns as reference for what good test suites look like
- Test coverage for M8 should match or exceed M7 (which is expected to achieve 500+ tests passing)

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-26 [producer] Created ticket as new foundational phase for M8
- 2026-02-27 [producer] Starting work — creating TDD process guide, updating coding standards, creating regression template and M8 test guidelines
- 2026-02-27 [producer] DONE — all 4 documents created/updated and committed. Commit: bd02634. Note: final AC item (systems-programmer + qa-engineer review sign-off) is a process step to be completed before other M8 phase work begins; document review checkboxes are embedded in tdd-process-m8.md.
