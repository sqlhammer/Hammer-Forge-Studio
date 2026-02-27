---
id: TICKET-0208
title: "Usage JSONL ledger and cost accumulation"
type: FEATURE
status: OPEN
priority: P1
owner: tools-devops-engineer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "T2"
phase: "Foundation"
depends_on: [TICKET-0207]
blocks: [TICKET-0210, TICKET-0211]
tags: [tooling, usage, ledger, orchestrator, conductor]
---

## Summary

Persist usage data to a JSONL ledger file after every Claude CLI call. Each line records the agent, ticket, milestone, phase, token counts, cost estimate, and timing. Also fix the existing `total_cost_usd` field in `state.json` which is currently dead code (never incremented).

## Acceptance Criteria

### JSONL Ledger
- [ ] Add `USAGE_LOG` constant pointing to `orchestrator/usage.jsonl`
- [ ] Add `append_usage_record(record: dict)` helper that appends a single JSON line to the ledger
- [ ] Each record contains: `timestamp` (ISO 8601), `agent`, `ticket_id`, `milestone`, `phase`, `model`, `input_tokens`, `output_tokens`, `cost_usd`, `duration_seconds`, `call_type` ("worker" or "planning")
- [ ] File is created on first write, appended thereafter
- [ ] Atomic-safe: use file append mode, flush after write

### Worker Usage Recording
- [ ] In `_do_working`, after a worker call completes, write a usage record with the worker's agent name and ticket ID
- [ ] `cost_usd` calculated from token counts using per-model pricing constants (Opus input: $15/MTok, output: $75/MTok; Sonnet input: $3/MTok, output: $15/MTok; Haiku input: $0.80/MTok, output: $4/MTok)

### Planning Usage Recording
- [ ] In `_do_planning`, after the producer call completes, write a usage record
- [ ] Use synthetic ticket ID `PLAN_WAVE_N` (where N is the current wave number) for planning calls
- [ ] Agent field set to `"producer"`

### state.json Cost Fix
- [ ] Locate the `total_cost_usd` field in `state.json` — currently initialized but never incremented
- [ ] After each usage record is written, increment `total_cost_usd` in the running state by the record's `cost_usd`
- [ ] Verify `total_cost_usd` reflects cumulative cost at end of a multi-wave run

### Gitignore
- [ ] Add `orchestrator/usage.jsonl` to `.gitignore` (usage data is local, not committed)

### Testing
- [ ] Manual test: run a conductor session, verify `orchestrator/usage.jsonl` contains one record per CLI call
- [ ] Verify records are valid JSON (parseable line-by-line)
- [ ] Verify `state.json` `total_cost_usd` is non-zero after a run

## Implementation Notes

- Pricing constants should be defined near the top of the module or in a small pricing dict keyed by model name substring (e.g., "opus", "sonnet", "haiku").
- The ledger must never block or crash the orchestrator. Wrap file I/O in try/except.
- JSONL format: one JSON object per line, no trailing comma, newline-terminated.

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created ticket — JSONL ledger and cost accumulation
