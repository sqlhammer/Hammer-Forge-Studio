# M8 Red/Green/Refactor TDD Process Guide

**Owner:** producer
**Status:** Active
**Last Updated:** 2026-02-27
**Applies To:** M8 — Ship Navigation (all phases)

> This document establishes the mandatory Test-Driven Development process for Milestone 8. All M8 feature work must follow the Red/Green/Refactor cycle defined here. This is a hard requirement, not a best-practice suggestion.

---

## Overview

M8 introduces the navigation system, fuel mechanics, biome travel, and procedural terrain — all net-new systems with complex interactions. To maintain the quality bar set in M7 (480 passing tests, zero regressions), M8 adopts strict Red/Green/Refactor TDD as its foundational process.

---

## Red/Green/Refactor Cycle

Every feature in M8 must be developed in exactly this order:

### Step 1 — RED: Write a Failing Test

Before writing any feature code:

1. Identify the behavior to implement — the smallest observable unit of functionality.
2. Write a unit test in the corresponding `game/tests/` file that exercises that behavior.
3. Run the test suite and confirm the new test **fails** (red). A test that passes before any implementation is written is an invalid test.
4. Document the failing test state in the commit message or PR description (see commit conventions below).

**Red-phase commit convention:**
```
TICKET-XXXX: [RED] Add failing test for <behavior>
```

### Step 2 — GREEN: Write Minimum Code to Pass

1. Write the minimum production code in `game/scripts/` necessary to make the failing test pass.
2. Do not add extra logic, optimizations, or features not covered by the current test.
3. Run the full test suite — the new test must now pass, and all previously passing tests must still pass (zero regressions).
4. Commit with a green-phase message.

**Green-phase commit convention:**
```
TICKET-XXXX: [GREEN] Implement <behavior> — N tests passing
```

### Step 3 — REFACTOR: Clean Up Without Breaking Tests

1. After green, improve code clarity, reduce duplication, apply coding standards.
2. The test suite must pass after every refactor change — run tests between each refactor step, not just at the end.
3. Refactoring never adds new behavior; it only improves existing code structure.
4. Commit refactoring separately from implementation.

**Refactor-phase commit convention:**
```
TICKET-XXXX: [REFACTOR] Clean up <system> — N tests passing
```

### Cycle Cadence

- One full Red/Green/Refactor cycle per logical behavior unit — not per file, not per class.
- A single ticket may complete multiple Red/Green/Refactor cycles for multiple behaviors.
- Each cycle must be independently committable and the test suite must be green at each cycle boundary.

---

## Test-First Expectations

| Rule | Detail |
|------|--------|
| Test file exists before feature file | The `game/tests/test_<system>.gd` file must be created or updated **before** any code in `game/scripts/` |
| No feature ships untested | Every public method, every state transition, every edge case must have at least one corresponding test |
| Red-phase proof required | The commit history must show a red-phase commit (failing test) before the green-phase commit (passing implementation) for each behavior |
| Full suite passes at ticket close | Before marking a ticket DONE, run the full test suite (`res://addons/hammer_forge_tests/test_runner.tscn`) and confirm zero failures |

---

## Coverage Targets Per System

These are **minimum** targets. Exceeding them is encouraged.

| System | Coverage Target | Notes |
|--------|----------------|-------|
| Navigation system | 85% | Pathfinding, waypoint validation, travel routing |
| Fuel system | 80% | Consumption calculation, cell crafting, empty/full states |
| Biome travel mechanics | 75% | Transition logic, state management, resource respawn |
| Procedural terrain | 70% | TerrainFeatureRequest API, chunk grid, ArrayMesh generation |
| Cryonite resource | 80% | Yield, drone-minability, node behavior |
| Navigation console UI | 65% | Modal state, input routing, display accuracy |
| Debug scene | 60% | Biome selector, begin-wealthy, selector accuracy |

Coverage is measured by: (behaviors with at least one passing test) / (total defined behaviors in system spec). QA Engineer tracks this in the phase gate regression suite.

---

## Failure Case Coverage Requirements

Every system must include tests for the following categories of failure cases:

### Invalid Input
- Null references passed to public methods
- Out-of-range numeric values (negative fuel, zero distance, max-int coordinates)
- Empty arrays or dictionaries where populated structures are expected
- Malformed resource requests (unknown biome type, unsupported feature type)

### State Transitions
- Attempting a transition that is not valid from the current state (e.g., travel when already traveling)
- Interruption mid-transition (e.g., fuel runs out during biome travel)
- Recovery from failed state (e.g., returning to idle after an error)
- Re-entry into a completed state (e.g., re-triggering arrival at a biome already active)

### Edge Cases
- Empty biome (no resource nodes spawned)
- Zero fuel at travel initiation
- Navigation to the currently active biome (no-op expected)
- Simultaneous resource respawn and drone-mining requests on the same node
- TerrainFeatureRequest for a location outside the valid chunk grid

### Integration Boundaries
- Navigation system receiving signals from the fuel system
- Biome change triggering resource respawn correctly
- Terrain generator receiving feature requests in the correct sequence

---

## Relation to Phase Gates

The Phase Gate passes only when:

- All tests for the phase's tickets are written (test files exist in `game/tests/`)
- The full test suite passes with zero failures
- Coverage targets above are met for all systems in scope for that phase
- QA Engineer has reviewed the regression suite and signed off

Phase gate failure due to TDD violations (missing tests, coverage below target) is treated as a P1 blocker. No exceptions.

---

## Reference: M7 TDD Baseline

M7 shipped with 480 passing tests across 39 tickets. M8 must not reduce this count. The M7 test suite is the regression baseline for all M8 work. Any M8 implementation that causes M7 tests to fail is a cross-milestone regression and triggers an immediate BLOCKER ticket assigned to the responsible agent.

---

## Document Review

This guide was reviewed and approved by:

- [ ] systems-programmer
- [ ] qa-engineer

Reviews must be completed before any other M8 phase work begins (enforced by TICKET-0131 gate dependency).
