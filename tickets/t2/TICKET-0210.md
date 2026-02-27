---
id: TICKET-0210
title: "Usage report script with capacity gauges"
type: FEATURE
status: OPEN
priority: P1
owner: tools-devops-engineer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "T2"
phase: "Reporting"
depends_on: [TICKET-0208, TICKET-0209]
blocks: [TICKET-0212]
tags: [tooling, usage, reporting, capacity, python]
---

## Summary

Create a standalone Python reporting script that reads the JSONL usage ledger and plan capacity configuration to produce human-readable usage summaries with capacity utilization gauges. Supports multiple breakdown dimensions and machine-readable JSON output.

## Acceptance Criteria

### Script Location and Interface
- [ ] Script at `tools/usage_report.py`
- [ ] Runs via `python tools/usage_report.py` from repo root
- [ ] Exit code 0 on success, non-zero on errors
- [ ] `--help` flag shows all available options

### Default Summary (no flags)
- [ ] Reads `orchestrator/usage.jsonl`
- [ ] Prints milestone summary: total cost USD, producer/worker cost split, total input/output tokens, total duration, wave count
- [ ] Formats cost as `$X.XX`, tokens with comma separators

### Breakdown Flags
- [ ] `--by-agent`: Per-agent breakdown (cost, tokens, call count)
- [ ] `--by-ticket`: Per-ticket breakdown (cost, tokens, duration)
- [ ] `--by-phase`: Per-phase breakdown within each milestone (cost, tokens, ticket count)
- [ ] Breakdowns are additive — multiple flags can be combined

### Capacity Gauges (`--capacity`)
- [ ] **Rolling 5-hour window**: Sums output tokens from the last 5 hours of ledger data, compares to `five_hour_output_token_limit` from config
- [ ] **Per-conductor-session**: Groups records by session (contiguous timestamps with <30min gaps), shows per-session token usage
- [ ] **Weekly rolling**: Sums output tokens from the last 7 days, compares to `weekly_output_token_limit` from config
- [ ] Opus token weighting: output tokens from Opus model calls are multiplied by 1.7x before comparing to capacity limits
- [ ] Gauge display: ASCII progress bar (e.g., `[########--] 82% of 5hr limit`) with color thresholds: green <50%, yellow 50-80%, red >80%

### Machine-Readable Output
- [ ] `--json` flag outputs the entire report as a single JSON object to stdout
- [ ] JSON structure mirrors the human-readable sections: `summary`, `breakdowns`, `capacity`

### Edge Cases
- [ ] Empty or missing ledger file: prints "No usage data found" and exits cleanly
- [ ] Missing config `plan_limits`: uses hardcoded defaults, prints warning
- [ ] Records with unknown model: excluded from capacity weighting, included in cost totals

## Implementation Notes

- Use only Python standard library (json, datetime, argparse, pathlib). No external dependencies.
- The 5-hour rolling window should use the `timestamp` field from ledger records, not wall-clock time of the report run.
- Keep the script stateless — it reads the ledger and config on every run, computes everything fresh.
- Color output: use ANSI escape codes for terminal color. Detect `--no-color` flag or non-TTY stdout to disable.

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created ticket — usage report script with capacity gauges
