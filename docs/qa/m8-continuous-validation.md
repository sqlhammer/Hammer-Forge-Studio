# M8 Continuous Validation Guide

**Owner:** qa-engineer
**Created:** 2026-02-27
**Ticket:** TICKET-0132

> Documents how each M8 phase runs its gate regression suite, who runs it, and where results are recorded.

---

## Test Suite Baseline

| Metric | Value |
|--------|-------|
| M7 baseline test count | 480 |
| M8 scaffold test files | 8 |
| M8 TDD Foundation gate tests | 5 |
| Total suite files | 34 (25 M7 + 9 M8) |
| Headless execution time (M7 baseline) | ~2 seconds |

---

## How to Run the Full Test Suite

### From the Godot Editor

1. Open `res://addons/hammer_forge_tests/test_runner.tscn`
2. Press Play Scene (F6)
3. Results appear in the console output panel
4. JSON report written to `user://test_reports/`

### Headless (CI / Phase Gate Validation)

```bash
godot --headless --path game addons/hammer_forge_tests/test_runner.tscn
```

- Exit code 0 = all tests passed
- Exit code 1 = one or more failures
- JSON report written to `user://test_reports/`

### Filter to M8 Suites Only

```bash
godot --headless --path game addons/hammer_forge_tests/test_runner.tscn -- --suite=m8_
```

---

## Phase Gate Regression Protocol

Each M8 phase gate runs the same validation sequence. The QA Engineer prepares the report; the Producer reviews it for gate pass/fail.

### Who Runs It

| Role | Responsibility |
|------|---------------|
| **QA Engineer** | Executes full test suite, prepares regression report, documents findings |
| **Producer** | Reviews report, verifies gate pass conditions, posts Phase Gate Summary |

### When It Runs

| Phase | Trigger | Gate Tests |
|-------|---------|------------|
| TDD Foundation | All foundation tickets DONE | `test_m8_tdd_foundation_gate.gd` + full M7 suite |
| Navigation & Fuel | All navigation/fuel tickets DONE | Phase-specific gate suite + full cumulative suite |
| Integration | All integration tickets DONE | Phase-specific gate suite + full cumulative suite |
| QA | All QA tickets DONE | Full regression suite + manual regression checklist |

### Step-by-Step Gate Execution

1. **Run full test suite headlessly:**
   ```bash
   godot --headless --path game addons/hammer_forge_tests/test_runner.tscn
   ```

2. **Capture the JSON report** from `user://test_reports/`

3. **Verify gate pass conditions:**
   - [ ] All tests pass (0 failures, 0 skipped)
   - [ ] Test count >= previous baseline (no tests removed)
   - [ ] M7 tests still pass (cross-milestone check)
   - [ ] Coverage targets met per `docs/studio/tdd-process-m8.md`

4. **Create regression report** at `docs/qa/reports/YYYY-MM-DD-m8-<phase>-gate-qa.md`

5. **Log findings** in the QA ticket Activity Log with severity and disposition

6. **Notify Producer** that the gate report is ready for review

### Where Results Are Recorded

| Artifact | Location |
|----------|----------|
| JSON test report | `user://test_reports/test_report_YYYY-MM-DD_HH-MM-SS.json` |
| Gate regression report | `docs/qa/reports/YYYY-MM-DD-m8-<phase>-gate-qa.md` |
| QA ticket Activity Log | `tickets/M8/TICKET-0132.md` (infrastructure) or phase-specific QA ticket |
| Regression checklist | `docs/qa/regression-checklist.md` (executed at milestone close) |

---

## Producer Quick Reference

To validate a phase gate without specialist knowledge:

1. Run the headless command above
2. Check exit code: 0 = PASS, 1 = FAIL
3. If PASS: open the JSON report and confirm `"failed": 0`
4. If FAIL: page QA Engineer for triage
5. Review the gate regression report at `docs/qa/reports/`
