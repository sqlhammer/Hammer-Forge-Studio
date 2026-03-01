---
id: TICKET-0211
title: "Usage data backfill from existing logs"
type: FEATURE
status: IN_PROGRESS
priority: P2
owner: tools-devops-engineer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "T2"
phase: "Reporting"
depends_on: [TICKET-0208]
blocks: [TICKET-0212]
tags: [tooling, usage, backfill, logs, python]
---

## Summary

Create a backfill script that scans existing orchestrator log files and reconstructs approximate usage records for the JSONL ledger. This enables historical reporting for milestones that ran before the usage tracking system was implemented.

## Acceptance Criteria

### Script Location and Interface
- [ ] Script at `tools/backfill_usage.py`
- [ ] Runs via `python tools/backfill_usage.py` from repo root
- [ ] `--dry-run` flag prints what would be written without modifying the ledger
- [ ] `--verbose` flag shows per-record details during processing
- [ ] Exit code 0 on success, non-zero on errors

### Log Scanning
- [ ] Scans `orchestrator/logs/*.log` for Claude CLI result entries
- [ ] Extracts available fields: timestamp, agent name, exit code, duration
- [ ] Infers ticket ID from log filename or log content patterns
- [ ] Infers milestone and phase from ticket files in `tickets/*/TICKET-*.md`

### Record Generation
- [ ] Generates JSONL records in the same format as TICKET-0208's live recording
- [ ] Fields that cannot be determined from logs are set to null (e.g., `input_tokens`, `output_tokens` if not logged)
- [ ] `cost_usd` set to null for records without token data
- [ ] `call_type` inferred as "worker" or "planning" from agent name ("producer" = planning, all others = worker)
- [ ] Adds `backfilled: true` flag to each record for identification

### Idempotency
- [ ] Checks existing ledger records before writing — skips records that match on (timestamp, agent, ticket_id)
- [ ] Re-running the script produces no duplicate entries
- [ ] Reports count of skipped (already-backfilled) vs newly-written records

### Testing
- [ ] Run on existing log files, verify output with `--dry-run`
- [ ] Run twice, verify second run produces zero new records
- [ ] Verify backfilled records are readable by `tools/usage_report.py` (from TICKET-0210)

## Implementation Notes

- Log file format varies across milestones — the parser should be lenient and extract what it can.
- Use only Python standard library. No external dependencies.
- The backfill script is a one-time/occasional tool, not part of the main orchestrator loop. Prioritize correctness over performance.

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created ticket — usage data backfill from existing logs
- 2026-03-01 [tools-devops-engineer] Starting work — implementing backfill_usage.py
