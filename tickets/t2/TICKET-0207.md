---
id: TICKET-0207
title: "Usage data extraction from Claude CLI output"
type: FEATURE
status: OPEN
priority: P1
owner: tools-devops-engineer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "T2"
phase: "Foundation"
depends_on: []
blocks: [TICKET-0208]
tags: [tooling, usage, orchestrator, conductor]
---

## Summary

Extract usage metadata (input tokens, output tokens, cost) from Claude CLI `--output-format json` stdout in the orchestrator's `conductor.py`. Extend the `run_claude()` return value to include structured usage data so downstream callers can record per-call cost and token consumption.

## Acceptance Criteria

### Extraction Function
- [ ] Add `extract_usage_from_output(stdout: str) -> dict` function to `conductor.py`
- [ ] Parses the JSON result block from Claude CLI stdout
- [ ] Extracts fields: `input_tokens`, `output_tokens`, `model`, `stop_reason`
- [ ] Returns empty dict (not None) if parsing fails — never crashes the caller
- [ ] Handles edge cases: empty stdout, malformed JSON, missing fields

### run_claude() Return Extension
- [ ] `run_claude()` return value extended from 3-tuple `(exit_code, stdout, stderr)` to 4-tuple `(exit_code, stdout, stderr, usage_meta)`
- [ ] `usage_meta` is a dict with keys: `input_tokens`, `output_tokens`, `model`, `stop_reason`, `duration_seconds`
- [ ] `duration_seconds` is wall-clock time of the CLI call (use `time.time()` before/after)

### Call Site Updates
- [ ] Update `_do_planning` call site (~line 836) to unpack 4-tuple
- [ ] Update `_run_worker` call site (~line 1254) to unpack 4-tuple
- [ ] No functional change to existing behavior — usage_meta is captured but not yet persisted

### Testing
- [ ] Manual test: run a single conductor wave and verify usage_meta is populated in debug logs
- [ ] Verify no regression: existing orchestrator runs complete successfully with the 4-tuple change

## Implementation Notes

- Claude CLI with `--output-format json` includes a `result` object in stdout with `usage` data. The exact structure should be inspected from an actual CLI run before implementing.
- Line numbers are approximate — verify current positions before editing.
- Keep extraction logic defensive: the orchestrator must never crash due to usage parsing failures.

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created ticket — usage data extraction from Claude CLI output
