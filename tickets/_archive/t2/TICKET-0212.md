---
id: TICKET-0212
title: "Code review — T2 systems"
type: REVIEW
status: DONE
priority: P1
owner: systems-programmer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-03-01
milestone: "T2"
phase: "QA"
depends_on: [TICKET-0207, TICKET-0208, TICKET-0209, TICKET-0210, TICKET-0211]
blocks: [TICKET-0213]
tags: [tooling, usage, review, qa]
---

## Summary

Code review of all T2 implementation tickets. Review the usage extraction, JSONL ledger, capacity configuration, reporting script, and backfill script for correctness, robustness, and adherence to project coding standards.

## Acceptance Criteria

### Conductor Changes (TICKET-0207, TICKET-0208)
- [x] `extract_usage_from_output()` handles all edge cases (empty input, malformed JSON, missing fields)
- [x] 4-tuple return from `run_claude()` does not break any existing call paths
- [x] JSONL append is atomic-safe and wrapped in error handling
- [x] Pricing constants are accurate and easy to update
- [x] `total_cost_usd` accumulation in state.json is correct
- [x] No performance regression from usage tracking (file I/O is non-blocking to orchestrator flow)

### Configuration (TICKET-0209)
- [x] `plan_limits` schema is clean and well-documented
- [x] Graceful fallback when section is missing
- [x] Default values match documented Max 20 plan limits

### Reporting Script (TICKET-0210)
- [x] All breakdown modes produce correct output
- [x] Capacity gauge calculations are mathematically correct (especially Opus 1.7x weighting)
- [x] Rolling window logic handles timezone/edge cases
- [x] `--json` output is valid JSON and structurally matches human-readable output
- [x] No external dependencies — stdlib only

### Backfill Script (TICKET-0211)
- [x] Idempotency verified — no duplicate records on re-run
- [x] Log parsing is defensive — never crashes on unexpected log formats
- [x] `backfilled: true` flag is present on all generated records
- [x] Inference logic (ticket ID from filename, milestone from ticket files) is correct

### General
- [x] All new code follows project coding standards
- [x] No secrets, credentials, or sensitive data in committed files
- [x] `.gitignore` updated for `orchestrator/usage.jsonl`

## Handoff Notes

### Review Summary — APPROVED with minor findings

All T2 implementation tickets pass code review. The code is well-structured, defensive, and follows project conventions. No blocking defects found. Minor findings noted below for Producer to triage.

### Files Reviewed

- `orchestrator/conductor.py` — extract_usage_from_output(), append_usage_record(), run_claude() 4-tuple, _do_planning usage recording, _do_working usage recording, plan_limits warning, calc_cost_usd(), total_cost_usd accumulation
- `orchestrator/config.json` — plan_limits schema and _docs section
- `tools/usage_report.py` — all breakdown modes, capacity gauge logic, JSON output, color handling
- `tools/backfill_usage.py` — log parsing, idempotency, ticket metadata inference, backfilled flag
- `.gitignore` — usage.jsonl entry confirmed

### Detailed Findings

#### Conductor (TICKET-0207, TICKET-0208) — PASS

1. **extract_usage_from_output()** (line 677): Handles empty input, malformed JSON, and missing fields correctly. Returns empty dict on any failure. Handles both list (JSON array from `--output-format json`) and dict formats. Uses `.get()` throughout — no KeyError risk.

2. **run_claude() 4-tuple** (line 557): Signature cleanly extended to `-> tuple[int, str, str, dict]`. Both call sites (_do_planning ~line 954, _run_worker ~line 1394) correctly unpack 4 values. Timeout path returns `{}` for usage_meta.

3. **append_usage_record()** (line 148): Uses append mode with flush — adequate for single-process JSONL writes. Wrapped in `except Exception: pass` — never crashes the caller.

4. **Pricing constants** (line 47): Opus $15/$75, Sonnet $3/$15, Haiku $0.80/$4 per MTok — matches current Claude API pricing. Dictionary format is easy to update.

5. **total_cost_usd** (line 472 init, lines 975-976 planning, lines 1245-1247 working): Correctly initialized to 0.0, accumulated after each call. Planning path calls save_state immediately. Working path relies on the ticket lock release save_state at line 1254, which is adequate.

6. **Performance**: File I/O is synchronous but negligible (single JSON line per call). The `except Exception: pass` ensures no blocking on write failures.

#### Configuration (TICKET-0209) — PASS

1. **Schema** (config.json lines 52-62): Clean structure with `plan_tier`, `five_hour_output_token_limit`, `weekly_output_token_limit`, and `_docs` section. Well-documented.

2. **Graceful fallback** (conductor.py ~line 795): Warning printed to stderr with explicit default values. Does not crash.

3. **Default values**: 220000 and 3080000 match Max 20 plan documentation.

#### Reporting Script (TICKET-0210) — PASS

1. **Breakdowns**: All three modes (by-agent, by-ticket, by-phase) compute correct aggregates. Sorted by cost descending. Phase breakdown correctly nests within milestones and counts unique tickets.

2. **Capacity gauges**: Opus 1.7x weighting applied correctly in `weighted_output_tokens()`. Rolling windows use record timestamps (not wall-clock), satisfying the spec. Session grouping uses 30-minute gap threshold.

3. **Timezone handling**: `parse_ts()` tries multiple ISO 8601 formats, defaults naive timestamps to UTC. Records without valid timestamps excluded from capacity calculations.

4. **JSON output**: `build_json_report()` mirrors human-readable sections. `json.dumps(report, indent=2, default=str)` ensures serialization. Color disabled when `--json` active.

5. **Dependencies**: Only stdlib (argparse, json, sys, collections, datetime, pathlib).

#### Backfill Script (TICKET-0211) — PASS

1. **Idempotency**: `load_existing_keys()` loads (timestamp, agent, ticket_id) tuples. `seen_keys` set tracks both existing and newly-added records. Second run produces zero new records.

2. **Defensive parsing**: `parse_log_filename()` returns None for unrecognized filenames. `parse_log_file()` wraps all I/O in try/except. Tracks parse_error_count without crashing.

3. **Backfilled flag**: Line 363: `"backfilled": True` — present on all generated records.

4. **Inference logic**: Producer logs → `PLAN_WAVE_{N}`, worker logs → `TICKET-{NNNN}`. Ticket metadata loaded from `tickets/**/{ticket_id}.md` with caching. Planning calls correctly skip ticket metadata lookup.

#### General — PASS

1. **Coding standards**: All Python files follow project conventions — docstrings, type hints, clear naming, defensive error handling.

2. **No secrets**: No credentials, API keys, or sensitive data in any committed file.

3. **Gitignore**: `orchestrator/usage.jsonl` on line 8 of `.gitignore`.

### Minor Findings (non-blocking, for Producer triage)

1. **`fmt_cost` uses 4 decimal places** (usage_report.py line 207): `f"${usd:.4f}"` formats as `$0.0015` instead of the spec's `$X.XX`. This is actually more useful for small API costs and is a reasonable design choice, but deviates from the literal acceptance criteria text. Suggest documenting this as intentional.

2. **Backfill planning calls omit milestone/phase** (backfill_usage.py lines 347-348): Planning calls in the backfill script set milestone and phase to `None`, while the live conductor recording includes the current milestone/phase from state. This is acceptable since the backfill script cannot determine what milestone was active during historical planning calls — the information isn't in the log filenames. No action needed.

3. **`calc_cost_usd` defaults to sonnet pricing for unknown models** (conductor.py line 139, backfill_usage.py line 47): Both implementations default to sonnet rates when no model name matches. This is a reasonable middle-ground default. Consider adding a log warning when the default is used, as silent cost misattribution could compound over time.

## Activity Log

- 2026-02-27 [producer] Created ticket — T2 code review
- 2026-03-01 [systems-programmer] Starting work — reviewing all T2 implementation files
- 2026-03-01 [systems-programmer] DONE — all acceptance criteria pass. Three minor non-blocking findings documented in handoff notes. No BUGFIX tickets required.
