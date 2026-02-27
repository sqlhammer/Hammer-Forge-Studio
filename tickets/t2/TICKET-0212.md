---
id: TICKET-0212
title: "Code review — T2 systems"
type: REVIEW
status: OPEN
priority: P1
owner: systems-programmer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
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
- [ ] `extract_usage_from_output()` handles all edge cases (empty input, malformed JSON, missing fields)
- [ ] 4-tuple return from `run_claude()` does not break any existing call paths
- [ ] JSONL append is atomic-safe and wrapped in error handling
- [ ] Pricing constants are accurate and easy to update
- [ ] `total_cost_usd` accumulation in state.json is correct
- [ ] No performance regression from usage tracking (file I/O is non-blocking to orchestrator flow)

### Configuration (TICKET-0209)
- [ ] `plan_limits` schema is clean and well-documented
- [ ] Graceful fallback when section is missing
- [ ] Default values match documented Max 20 plan limits

### Reporting Script (TICKET-0210)
- [ ] All breakdown modes produce correct output
- [ ] Capacity gauge calculations are mathematically correct (especially Opus 1.7x weighting)
- [ ] Rolling window logic handles timezone/edge cases
- [ ] `--json` output is valid JSON and structurally matches human-readable output
- [ ] No external dependencies — stdlib only

### Backfill Script (TICKET-0211)
- [ ] Idempotency verified — no duplicate records on re-run
- [ ] Log parsing is defensive — never crashes on unexpected log formats
- [ ] `backfilled: true` flag is present on all generated records
- [ ] Inference logic (ticket ID from filename, milestone from ticket files) is correct

### General
- [ ] All new code follows project coding standards
- [ ] No secrets, credentials, or sensitive data in committed files
- [ ] `.gitignore` updated for `orchestrator/usage.jsonl`

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created ticket — T2 code review
