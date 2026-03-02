# UAT Sign-Off — T2: Usage Attribution

> **Prepared by:** qa-engineer
> **Date Prepared:** 2026-03-01
> **Milestone:** T2 — Usage Attribution
>
> **Studio Head:** Review each feature below, follow the How to Test steps, then mark each checkbox.
> When all checkboxes are marked `✅ Approved`, reply to the Producer to grant final milestone sign-off.

---

## Header

| Field | Value |
|-------|-------|
| **Milestone** | T2 — Usage Attribution |
| **Prepared By** | qa-engineer |
| **Date Prepared** | 2026-03-01 |
| **Test Build** | be1b68c (main) |
| **Sign-Off Status** | ⏳ Pending |

---

## How to Use This Document

1. Features in this milestone are all **tooling/CLI** features — no Godot scene required.
2. For each feature, check the **Verification Method** tag:
   - `integration-test` — Covered by QA validation session (evidence in TICKET-0213 Activity Log)
   - **`manual-playtest`** — **Requires hands-on testing by Studio Head.** Follow the test steps.
3. For `manual-playtest` items, follow the **How to Test** steps from a terminal in the repo root.
4. Mark each checkbox:
   - `✅ Approved` — feature works as described, no blocking issues
   - `❌ Rejected` — feature is broken or missing; add a note describing the problem
5. Once all features are marked, sign off at the bottom.

---

## Feature Sign-Off Checklist

### Usage Extraction — Conductor Pipeline (TICKET-0207, TICKET-0208)

---

#### Usage Metadata Extraction from Claude CLI Output (TICKET-0207)

**Verification Method:** `integration-test`

**What changed:** Added `extract_usage_from_output()` to conductor.py. This function parses the Claude CLI's `--output-format json` output to extract input/output token counts, model name, and stop reason from each API call. The `run_claude()` function now returns a 4-tuple `(exit_code, stdout, stderr, usage_meta)` instead of a 3-tuple.

**How to test:**
1. Open a terminal in the repo root
2. Run: `python3 tools/usage_report.py --by-agent --no-color`
3. Confirm the breakdown shows multiple agents with non-zero token counts and costs

**Expected result:** A table showing agents (gameplay-programmer, systems-programmer, producer, qa-engineer) with their respective costs, input/output token counts, and call counts. Total cost should be ~$27.47.

**Automated coverage:** QA validation: 22 records extracted from 22 log files with no parse errors. All required fields present.

- [ ] ✅ Approved / ❌ Rejected — _Notes:_

---

#### JSONL Ledger Recording (TICKET-0208)

**Verification Method:** `integration-test`

**What changed:** After each conductor wave's planning call and each worker call completes, a JSON record is appended to `orchestrator/usage.jsonl`. Each record captures: timestamp, agent, ticket_id, milestone, phase, model, input_tokens, output_tokens, cost_usd, duration_seconds, call_type. The conductor's `state.json` also accumulates `total_cost_usd` for the active session.

**How to test:**
1. Run: `cat orchestrator/usage.jsonl | head -5` to inspect ledger contents
2. Confirm each line is valid JSON with all required fields
3. Run: `python3 tools/usage_report.py --no-color` to confirm totals are computed correctly

**Expected result:** Each line in `usage.jsonl` is a valid JSON object. The report shows 22 total records, $27.47 total cost, 10 planning waves.

**Automated coverage:** QA validation: all 22 records validated, all required fields present, no parse errors. State.json `total_cost_usd` tracks session costs (per-session accumulation, resets each conductor run by design).

- [ ] ✅ Approved / ❌ Rejected — _Notes:_

---

### Capacity Configuration (TICKET-0209)

---

#### Plan Limits Configuration in config.json (TICKET-0209)

**Verification Method:** `integration-test`

**What changed:** Added a `plan_limits` section to `orchestrator/config.json` documenting the Max 20 plan token limits used for capacity gauge calculations: 220,000 output tokens per 5-hour rolling window and 3,080,000 output tokens per week. Opus tokens are weighted at 1.7× in capacity calculations.

**How to test:**
1. Run: `cat orchestrator/config.json`
2. Confirm a `plan_limits` section exists with `plan_tier`, `five_hour_output_token_limit`, `weekly_output_token_limit`, and `_docs` fields
3. Run: `python3 tools/usage_report.py --capacity --no-color`
4. Confirm the Plan tier shows "Max 20" and limits show 220,000 and 3,080,000

**Expected result:** The `plan_limits` section is present and well-documented. Capacity report shows Max 20 plan with correct limits. Removing the section triggers a warning and uses hardcoded defaults (220,000 / 3,080,000).

**Automated coverage:** QA validation: defaults-fallback tested — warning printed to stderr, report continued with correct defaults.

- [ ] ✅ Approved / ❌ Rejected — _Notes:_

---

### Usage Report Script (TICKET-0210)

---

#### Default Summary Report (TICKET-0210)

**Verification Method:** `manual-playtest`

**What changed:** New script `tools/usage_report.py` reads `orchestrator/usage.jsonl` and produces a usage summary. Default output shows total cost, producer vs worker cost split, token counts, duration, wave count, and record count.

**How to test:**
1. Open a terminal in the repo root
2. Run: `python3 tools/usage_report.py --no-color`

**Expected result:**
```
============================================================
  USAGE SUMMARY
============================================================
  Total cost      : $27.4686
  Producer cost   : $2.0582
  Worker cost     : $25.4104
  Input tokens    : 14,179
  Output tokens   : 316,783
  Total duration  : 127m 5s
  Planning waves  : 10
  Total records   : 22
```

**Automated coverage:** QA validation: output matches expected values.

- [ ] ✅ Approved / ❌ Rejected — _Notes:_

---

#### Per-Agent Breakdown (TICKET-0210)

**Verification Method:** `manual-playtest`

**What changed:** `--by-agent` flag shows per-agent cost, input tokens, output tokens, and call count, sorted by cost descending.

**How to test:**
1. Run: `python3 tools/usage_report.py --by-agent --no-color`

**Expected result:** A table with agents gameplay-programmer, systems-programmer, producer, qa-engineer each showing their total cost, token counts, and call count. gameplay-programmer should be the most expensive (~$14.37, 2 calls due to Opus usage).

**Automated coverage:** QA validation: breakdown verified correct.

- [ ] ✅ Approved / ❌ Rejected — _Notes:_

---

#### Per-Ticket Breakdown (TICKET-0210)

**Verification Method:** `manual-playtest`

**What changed:** `--by-ticket` flag shows per-ticket cost, input tokens, output tokens, and duration, sorted by cost descending.

**How to test:**
1. Run: `python3 tools/usage_report.py --by-ticket --no-color`

**Expected result:** A table showing TICKET-0247 as most expensive (~$14.37), followed by TICKET-0250, TICKET-0256, etc. Planning waves (PLAN_WAVE_1 through PLAN_WAVE_10) also appear in the breakdown.

**Automated coverage:** QA validation: breakdown verified correct, planning waves correctly included.

- [ ] ✅ Approved / ❌ Rejected — _Notes:_

---

#### Per-Phase Breakdown (TICKET-0210)

**Verification Method:** `manual-playtest`

**What changed:** `--by-phase` flag shows cost/token breakdown grouped by milestone then phase, with unique ticket count per phase.

**How to test:**
1. Run: `python3 tools/usage_report.py --by-phase --no-color`

**Expected result:** Two milestone groups appear:
- `M8 / Bug Fix` — costs from the gameplay-programmer's bug fix work
- `T4 / Foundation` — costs from the T4 foundation tickets (systems-programmer, qa-engineer)
- `Unknown / Unknown` — producer planning calls (no milestone/phase context during planning)

**Automated coverage:** QA validation: phase breakdown verified, historical milestones appear correctly.

- [ ] ✅ Approved / ❌ Rejected — _Notes:_

---

#### Capacity Gauges (TICKET-0210)

**Verification Method:** `manual-playtest`

**What changed:** `--capacity` flag shows 5-hour rolling window and weekly rolling window token usage with ASCII progress bars. Colors indicate utilization: green <50%, yellow 50–80%, red >80%. Opus tokens weighted at 1.7× for capacity. Per-session breakdown also shown.

**How to test:**
1. Run: `python3 tools/usage_report.py --capacity --no-color`

**Expected result:**
- 5-Hour Rolling Window: ~118% used (will show full bar since >80%)
- Weekly Rolling Window: ~16.6% used (shows partial bar since <50%)
- 4 conductor sessions detected
- Opus-using agents (gameplay-programmer, systems-programmer) show higher weighted token counts than raw counts

**Automated coverage:** QA validation: 5h and weekly windows manually verified against raw records. Opus 1.7× weighting confirmed. Threshold logic verified: <50% green, 50–80% yellow, >80% red.

- [ ] ✅ Approved / ❌ Rejected — _Notes:_

---

#### JSON Output Mode (TICKET-0210)

**Verification Method:** `manual-playtest`

**What changed:** `--json` flag outputs the entire report as a single JSON object to stdout. All flags can be combined with `--json`. Color is disabled when `--json` is active.

**How to test:**
1. Run: `python3 tools/usage_report.py --by-agent --by-ticket --by-phase --capacity --json | python3 -m json.tool --no-ensure-ascii > /dev/null && echo "JSON valid"`

**Expected result:** `JSON valid` is printed, confirming the output is parseable JSON. The JSON structure includes `summary`, `breakdowns` (with `by_agent`, `by_ticket`, `by_phase`), and `capacity` keys.

**Automated coverage:** QA validation: JSON output validated with all flag combinations. All keys and values present and structurally match human-readable output.

- [ ] ✅ Approved / ❌ Rejected — _Notes:_

---

### Backfill Script (TICKET-0211)

---

#### Historical Log Backfill (TICKET-0211)

**Verification Method:** `integration-test`

**What changed:** New script `tools/backfill_usage.py` scans `orchestrator/logs/*.log` files, parses token usage from the Claude CLI JSON output, infers ticket/milestone/phase context from filenames and ticket frontmatter, and writes JSONL records to `orchestrator/usage.jsonl`. Each backfilled record has `"backfilled": true`. The script is idempotent: re-running produces zero duplicates.

**How to test:**
1. Run: `python3 tools/backfill_usage.py --dry-run --verbose`
2. Confirm output shows 0 new records (all 22 already in ledger from prior backfill)
3. Run: `python3 tools/backfill_usage.py`
4. Confirm output still shows 0 new records (idempotency)
5. Check ledger line count is still 22: `wc -l orchestrator/usage.jsonl`

**Expected result:**
- Dry-run shows 22 files scanned, 0 new records, 22 skipped (duplicates), 0 parse errors
- Live run: 0 new records written, ledger still 22 lines
- `python3 tools/usage_report.py --by-phase --no-color` shows M8 and T4 milestones

**Automated coverage:** QA validation: dry-run and live run both verified. Idempotency confirmed (ledger unchanged after second run). Historical milestone data appears in reports.

- [ ] ✅ Approved / ❌ Rejected — _Notes:_

---

## QA Findings

### Findings from TICKET-0213 Validation Session (2026-03-01)

All tests were executed by qa-engineer against commit `be1b68c` on `main`.

| Finding | Severity | System | Observation | Disposition |
|---------|----------|--------|-------------|-------------|
| F-001 | P3 | state.json / ledger | `state.json total_cost_usd` is $0.0 while ledger total is $27.47. This is by design: `total_cost_usd` tracks the *current active session* only and resets when conductor exits. The ledger (`usage.jsonl`) is the cumulative historical record. No bug. | Known behavior, acceptable for milestone — documents design intent |
| F-002 | P2 | test_harness.py | `python3 orchestrator/test_harness.py` fails with `AttributeError: module 'orchestrator.conductor' has no attribute 'STATE_PATH'`. This is a **pre-existing regression** from TICKET-0250 (instance-path refactor) which removed `STATE_PATH` as a module-level constant but did not update test_harness.py. Not caused by T2 usage tracking work. | Pre-existing regression, not blocking T2 sign-off — file a separate ticket for test_harness.py update |
| F-003 | P3 | usage_report.py | `fmt_cost` uses 4 decimal places (`$0.0015`) instead of 2 (`$0.00`). This is more useful for small API costs. Noted by code review (TICKET-0212) as a minor intentional deviation. | Known issue, acceptable — documented in TICKET-0212 code review |

### Bugs Filed

- None blocking. F-002 (test_harness.py regression) should be filed as a follow-up TASK ticket for a future milestone.

---

## Rejection Notes

| Feature | Ticket | Issue Description |
|---------|--------|-------------------|
| — | — | — |

---

## Final Sign-Off

**Total Features:** 8
**Approved:** 0 (pending Studio Head review)
**Rejected:** 0

**Gate Condition:** All features must be `✅ Approved` for sign-off to be granted.

---

**Studio Head Sign-Off:**

- [ ] All features approved — milestone is cleared for close

**Signed off by:** _(Studio Head)_
**Date:** ___________
