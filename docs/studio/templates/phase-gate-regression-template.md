# Phase Gate Regression Test Report — Template

**Milestone:** M8 — Ship Navigation
**Phase:** <!-- e.g., TDD Foundation / Foundation / Gameplay / QA -->
**Gate Date:** <!-- YYYY-MM-DD -->
**Prepared By:** qa-engineer
**Reviewed By:** producer

---

## 1. Test Suite Summary

| Metric | Value | Target | Pass/Fail |
|--------|-------|--------|-----------|
| Total tests run | | ≥ prev milestone baseline | |
| Tests passing | | 100% of run | |
| Tests failing | | 0 | |
| Tests skipped | | 0 (explain any skips) | |
| New tests added this phase | | ≥ 1 per ticket in phase | |

**Test runner command:**
```
# Headless:
godot --headless --path game res://addons/hammer_forge_tests/test_runner.tscn

# Editor:
Open res://addons/hammer_forge_tests/test_runner.tscn and press Run
```

---

## 2. Coverage by System

| System | Behaviors Defined | Behaviors Tested | Coverage % | Target | Pass/Fail |
|--------|------------------|-----------------|------------|--------|-----------|
| Navigation system | | | | 85% | |
| Fuel system | | | | 80% | |
| Biome travel mechanics | | | | 75% | |
| Procedural terrain | | | | 70% | |
| Cryonite resource | | | | 80% | |
| Navigation console UI | | | | 65% | |
| Debug scene | | | | 60% | |

> Only include systems with tickets in this phase. Leave others blank.

---

## 3. Cross-Milestone Regression Check

| Milestone | Baseline Test Count | This Run Count | Regressions | Pass/Fail |
|-----------|--------------------|--------------:|-----------:|-----------|
| M1 | — | | 0 | |
| M2 | — | | 0 | |
| M3 | — | | 0 | |
| M4 | 284 | | 0 | |
| M5 | 417 | | 0 | |
| M6 | 467 | | 0 | |
| M7 | 480 | | 0 | |

A regression count > 0 for any prior milestone is a **gate blocker**. Create a BLOCKER ticket immediately and page the Studio Head before proceeding.

---

## 4. Failure Case Coverage

Confirm each failure category is covered for all systems in scope for this phase:

- [ ] Invalid input tests present
- [ ] State transition failure tests present
- [ ] Edge case tests present
- [ ] Integration boundary tests present

---

## 5. TDD Compliance Verification

For each ticket in this phase, verify the Red/Green/Refactor cycle was followed:

| Ticket | Red Commit Present | Green Commit Present | Refactor Committed | Pass/Fail |
|--------|--------------------|----------------------|--------------------|-----------|
| TICKET-XXXX | | | | |

> A "Red Commit" is a commit with `[RED]` in the message showing a failing test before implementation. Pull this from `git log`.

---

## 6. Open Blockers

List any unresolved issues that could prevent gate passage:

| # | Description | Owner | Ticket |
|---|-------------|-------|--------|
| | | | |

If any blockers exist, the gate **cannot pass**. Resolve all blockers before signing off.

---

## 8. Scene Property Validation

Scene property tests (`test_scene_properties_unit.gd`) validate `.tscn` file properties that unit tests cannot catch: anchor presets, collision shape types, group memberships, and node existence. This section is **mandatory** — a FAIL here is a gate blocker.

| Check Category | Tests Run | Tests Passed | Tests Failed | Pass/Fail |
|----------------|-----------|-------------|-------------|-----------|
| HUD anchor presets | | | 0 | |
| Collision shape types | | | 0 | |
| Node existence / wiring | | | 0 | |
| Group memberships | | | 0 | |
| **Total scene property tests** | | | **0** | |

> Any scene property test failure is a **gate blocker**. The implementing agent must fix the `.tscn` file and re-run before the gate can pass.

---

## 9. Gate Decision

| Condition | Status |
|-----------|--------|
| All phase tickets DONE | ☐ |
| Zero test failures | ☐ |
| Coverage targets met | ☐ |
| Zero cross-milestone regressions | ☐ |
| Scene property validation tests pass with zero failures | ☐ |
| All failure case categories covered | ☐ |
| TDD compliance verified for all tickets | ☐ |
| No open blockers | ☐ |

**Gate Decision:** ☐ PASS  ☐ FAIL

**QA Engineer Sign-Off:** _________________________ Date: ___________

**Producer Sign-Off:** _________________________ Date: ___________

> On PASS: Producer opens the next phase. Studio Head is NOT paged.
> On FAIL: Producer pages Studio Head immediately with specific failure conditions.
