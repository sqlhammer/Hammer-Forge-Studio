---
id: TICKET-0213
title: "QA testing — T2 usage attribution"
type: TASK
status: OPEN
priority: P1
owner: qa-engineer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "T2"
phase: "QA"
depends_on: [TICKET-0212]
blocks: []
tags: [tooling, usage, qa, testing]
---

## Summary

End-to-end QA validation of the T2 usage attribution system. Verify the full pipeline from CLI output extraction through ledger recording to report generation. Confirm capacity gauges are accurate and backfill works correctly on historical data.

## Acceptance Criteria

### Pipeline Integration Test
- [ ] Run a conductor session (at least 2 waves with 2+ workers each)
- [ ] Verify `orchestrator/usage.jsonl` contains one record per CLI call (producer + workers)
- [ ] Verify each record has all required fields populated (non-null for live records)
- [ ] Verify `state.json` `total_cost_usd` matches sum of `cost_usd` in ledger

### Report Validation
- [ ] `python tools/usage_report.py` produces correct default summary
- [ ] `python tools/usage_report.py --by-agent` shows correct per-agent breakdown
- [ ] `python tools/usage_report.py --by-ticket` shows correct per-ticket breakdown
- [ ] `python tools/usage_report.py --by-phase` shows correct per-phase breakdown
- [ ] `python tools/usage_report.py --capacity` shows capacity gauges with correct percentages
- [ ] `python tools/usage_report.py --json` produces valid, parseable JSON
- [ ] All flags combined: `--by-agent --by-ticket --by-phase --capacity --json` works correctly

### Capacity Gauge Accuracy
- [ ] Verify 5-hour rolling window calculation against manual count of recent records
- [ ] Verify weekly rolling window calculation against manual count
- [ ] Verify Opus 1.7x weighting is applied correctly (create test records with known Opus token counts)
- [ ] Verify gauge display thresholds: green <50%, yellow 50-80%, red >80%

### Backfill Validation
- [ ] Run `python tools/backfill_usage.py --dry-run` on existing logs, verify output makes sense
- [ ] Run `python tools/backfill_usage.py`, verify records written to ledger
- [ ] Run again, verify idempotency (zero new records)
- [ ] Run `python tools/usage_report.py` on backfilled data, verify historical milestones appear

### Edge Cases
- [ ] Delete `orchestrator/usage.jsonl`, run report — verify clean "no data" message
- [ ] Remove `plan_limits` from config, run report with `--capacity` — verify defaults used with warning
- [ ] Corrupt one line in ledger (invalid JSON), run report — verify it skips bad lines gracefully

### Regression
- [ ] Run a full orchestrator session end-to-end — verify no regression in ticket processing, PR creation, or phase gate logic
- [ ] Verify usage tracking does not measurably slow down conductor operations

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created ticket — T2 QA testing
