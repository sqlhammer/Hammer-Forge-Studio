---
id: TICKET-0183
title: "Checkpoint system — write, read, and clear suspension checkpoints"
type: FEATURE
status: DONE
priority: P1
owner: tools-devops-engineer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "M9"
phase: "Orchestrator Resilience"
depends_on: [TICKET-0182]
blocks: [TICKET-0185, TICKET-0186]
tags: [orchestrator, conductor, resilience, checkpoint, resume]
---

## Summary

When a worker exits abnormally, the conductor currently queues a retry with no context about what the previous session accomplished. This ticket implements a checkpoint system that captures the interrupted worker's git state, PR state, and ticket status into a structured JSON file. These checkpoints enable informed resume dispatches and auto-remediation of silently-completed work.

See `docs/engineering/orchestrator-resilience-plan.md` Section 2.1–2.2 for the full checkpoint schema and writer protocol.

## Acceptance Criteria

### Checkpoint Directory
- [ ] Create `orchestrator/checkpoints/` directory.
- [ ] Add `orchestrator/checkpoints/` to `.gitignore` (checkpoints are runtime state, not committed).

### Checkpoint Writer (`_write_checkpoint`)
- [ ] New method `_write_checkpoint(worker, exit_code, stdout, stderr)` in the `Conductor` class.
- [ ] Probes worktree git state (if worktree still exists): last commit hash, uncommitted changes, branch name.
- [ ] Probes remote PR state via `gh pr list --head {branch} --json number,url,state,merged`.
- [ ] Reads ticket status from disk via `read_ticket_status()`.
- [ ] Writes `orchestrator/checkpoints/{TICKET-NNNN}.checkpoint.json` per the schema in the resilience plan.
- [ ] Logs `[CHECKPOINT ] TICKET-NNNN suspended — wrote checkpoint` to activity log.

### Integration into Result Processing
- [ ] `_write_checkpoint` is called in `_do_working` for every abnormal worker exit (empty stdout, timeout, non-zero exit) **before** `_queue_retry`.
- [ ] Checkpoint data is made available to downstream processing (auto-remediation in TICKET-0190, retry queuing) via the returned checkpoint dict.

### Checkpoint Cleanup
- [ ] When a worker completes successfully (outcome=done, verified on disk), delete any existing checkpoint for that ticket.
- [ ] Log `[CHECKPOINT ] TICKET-NNNN checkpoint cleared` on deletion.

### Startup Zombie Detection
- [ ] On conductor startup (before main loop), scan `orchestrator/checkpoints/` for existing checkpoint files.
- [ ] For each checkpoint: if ticket is DONE on disk → auto-remediate and delete. If IN_PROGRESS → log `[CLEANUP ] TICKET-NNNN was zombie — checkpoint exists from previous session`.
- [ ] Clear any stale entries from `active_ticket_ids` that correspond to checkpoint files (no live process exists after restart).

### Testing
- [ ] All existing conductor tests pass.
- [ ] Add test case to `test_harness.py`: worker exits with empty stdout after committing → checkpoint file is created with correct schema.
- [ ] Add test case: checkpoint exists on startup with ticket DONE on disk → auto-remediated and deleted.

## Implementation Notes

- The checkpoint schema is defined in `docs/engineering/orchestrator-resilience-plan.md` Section 2.1.
- The `gh` CLI is available in the environment and used elsewhere in the conductor for PR operations.
- Worktree paths are stored in `state["active_workers"]` entries — use the `worktree` field.
- Checkpoint files must be written atomically (write to `.tmp` then rename) to avoid partial reads.

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created ticket — checkpoint infrastructure for graceful failure and resume
- 2026-02-27 [producer] Moved R3 auto-remediation (merged-PR detection) to dedicated TICKET-0190
- 2026-03-02 [tools-devops-engineer] Starting work — implementing checkpoint system per resilience plan sections 2.1–2.2
- 2026-03-02 [tools-devops-engineer] DONE — commit 051c2b1, PR https://github.com/sqlhammer/Hammer-Forge-Studio/pull/278 merged. Implemented _write_checkpoint, _delete_checkpoint, _scan_checkpoints_on_startup; integrated into _do_working and run(); added orchestrator/checkpoints/ to .gitignore; added 2 unit tests to test_harness.py. All 13+2 harness tests and 6/6 usage-limit tests pass.
