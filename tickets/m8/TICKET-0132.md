---
id: TICKET-0132
title: "M8 test infrastructure — unified test suite and phase gate regression template"
type: TASK
status: PENDING
priority: P1
owner: qa-engineer
created_by: producer
created_at: 2026-02-26
updated_at: 2026-02-26
milestone: "M8"
phase: "TDD Foundation"
depends_on: [TICKET-0131]
blocks: []
tags: [testing, infrastructure, tdd, regression, m8-foundation]
---

## Summary

Set up the M8 test infrastructure to support Red/Green TDD development. This includes establishing a unified test suite structure integrated with M7 tests, defining the phase gate regression test template, and ensuring the test runner is configured for automated validation at each milestone gate. QA Engineer is the owner; systems-programmer provides code review support.

## Acceptance Criteria

- [ ] M8 Test Suite Structure created in `game/tests/`:
  - Per-system test files following naming: `test_<system_name>.gd`
  - Baseline test runner configuration for M8 workload (M8 introduces navigation system, fuel system, travel mechanics = ~200–250 new unit tests expected)
  - Tests validate all existing M7 systems + M8-specific navigation and fuel systems
- [ ] M7 Cross-Milestone Regression Suite integrated:
  - All M7 tests continue passing without modification
  - M8 test runner validates both M7 and M8 suites in single execution
  - No cross-milestone breakage can occur without failing the gate
- [ ] Regression Test Template file (`game/tests/m8_phase_gate_regression_template.gd`):
  - Reusable boilerplate for each phase gate (TDD Foundation, Navigation, Integration, QA)
  - Auto-checks: all M8 tests pass, all M7 tests still pass, coverage %, zero cross-milestone breakage
  - Runnable in headless mode for CI integration
- [ ] Test Runner Configuration:
  - Verify test runner (`res://addons/hammer_forge_tests/test_runner.tscn`) works with M8 tests
  - Baseline M8 test count established and documented
  - Test execution time benchmarked (target: under 30 seconds for full suite)
- [ ] Integrated with continuous validation:
  - Document how each M8 phase will run its gate regression suite (when, who runs it, where results are recorded)
  - Ensure producer can execute regression suite without specialist knowledge
- [ ] All tests pass at baseline (0 failures before any M8 feature code is written)

## Implementation Notes

- **Test-First Mindset:** The test suite exists before the code; tests begin as RED (failing), then code is written to pass them
- Reference M7 tests as a model — that milestone establishes the TDD pattern and provides good precedent
- **Cross-Milestone Stability:** M8 is the first milestone fully following TDD from inception. Test infrastructure must ensure no regression in M6/M7 systems.
- Test infrastructure should be **minimal but complete** — no over-engineering, only what's needed for gate validation
- Regression suite runs automatically at each phase gate; producer calls it to validate PASS/FAIL conditions
- Use Hammer Forge Tests framework conventions (extend TestSuite, follow assertion patterns)

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-26 [producer] Created ticket as foundational test infrastructure work for M8
