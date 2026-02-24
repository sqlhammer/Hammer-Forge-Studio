# Phase Gate Summary — [MILESTONE] / [PHASE NAME]

> **Template:** Copy this file and fill in all fields when a phase gate fires.
> Save to `docs/studio/reports/` as `YYYY-MM-DD-[milestone]-[phase]-gate.md`.

---

## Gate Header

| Field | Value |
|-------|-------|
| **Milestone** | e.g., M4 — Ship Infrastructure |
| **Phase Name** | e.g., Foundation |
| **Gate Timestamp** | YYYY-MM-DD HH:MM UTC |
| **Gate Status** | ✅ PASS / ❌ FAIL |
| **Studio Head Action Required** | No (PASS) / **Yes — see Failure section (FAIL)** |

---

## Tickets Closed

List every ticket that was part of this phase. All must be `DONE` for the gate to pass.

| Ticket | Title | Owner | Status |
|--------|-------|-------|--------|
| TICKET-NNNN | Ticket title | agent-slug | DONE |

**Total:** N tickets — N DONE, N Open

---

## Test Results

| Result | Count |
|--------|-------|
| Tests Run | N |
| Passed | N |
| Failed | N |
| Skipped | N |

**Suite Status:** ✅ All passing / ❌ Failures — see below

If failures exist, list them:
- `test_file.gd::test_name` — brief description of failure

---

## Dependency Violations

> List any tickets that were set to `IN_PROGRESS` while a `depends_on` entry was not `DONE`. None is the expected outcome.

None

<!-- If violations occurred:
- TICKET-NNNN began while TICKET-MMMM was IN_PROGRESS (not DONE) on YYYY-MM-DD
-->

---

## Cross-Milestone Issues

> List any parse errors, test failures, or breaking changes introduced in this milestone that affected a prior milestone's test suite. None is the expected outcome.

None

<!-- If issues occurred:
- TICKET-NNNN introduced a parse error in [script] that caused M[n] test failures — resolved/unresolved
-->

---

## Gate Determination

A gate **PASSES** only when ALL of the following are true:

- [ ] Every ticket in the phase has status `DONE`
- [ ] The full test suite passes with zero failures
- [ ] No cross-milestone parse errors or test-runner blockers exist
- [ ] The dependency graph is clean — no ticket was started while a `depends_on` was non-DONE

**Gate Status: PASS / FAIL**

---

## Failure Details

> Complete this section only if Gate Status is FAIL. Leave blank on PASS.

**Failure Condition:** (describe exactly which gate check failed)

**Blocking Issue:** (what must be resolved before the next phase opens)

**Studio Head Notification:** (timestamp and channel — Producer pages Studio Head immediately on FAIL)

---

## Next Phase

| Field | Value |
|-------|-------|
| **Phase Name** | e.g., Gameplay |
| **Tickets in Scope** | TICKET-NNNN, TICKET-MMMM, ... |
| **Gate Status Required to Open** | This gate must PASS |
| **Phase Opens** | Automatically on PASS / Pending Studio Head resolution on FAIL |
