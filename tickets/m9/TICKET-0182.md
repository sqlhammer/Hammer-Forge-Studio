---
id: TICKET-0182
title: "Fix dead-lock on IN_PROGRESS pre-claim and add silent-success detection"
type: BUG
status: DONE
priority: P0
owner: tools-devops-engineer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "M9"
phase: "Orchestrator Resilience"
depends_on: [TICKET-0235]
blocks: [TICKET-0183, TICKET-0185]
tags: [orchestrator, conductor, resilience, dead-lock, P0]
---

## Summary

The conductor has a latent dead-lock bug: when a worker exits abnormally after committing work but before outputting structured JSON, the retry session reads the ticket file (still IN_PROGRESS), hits the pre-claim check in `worker_dispatch.md` line 10, and reports `outcome: "blocked"` with "already IN_PROGRESS." This exhausts all 3 retries reporting "blocked" and then HALTs — permanently dead-locking the ticket and all downstream dependents.

Additionally, the crash/timeout handlers in `conductor.py` (lines 1121-1126 for empty stdout, 1171-1182 for non-zero exit) queue retries without first checking whether the ticket is already DONE on disk. This wastes retries on tickets that completed successfully but whose agent session died before outputting JSON ("silent success" — Risk R10).

This ticket fixes both issues. See `docs/engineering/orchestrator-resilience-plan.md` Risks R1, R3, R10 for full analysis.

## Acceptance Criteria

- [x] **Silent-success check in crash handler:** Before queuing a retry in the empty-stdout crash path (`conductor.py` ~line 1121), read the ticket status from disk. If the ticket is `DONE`, log `[DONE ] {ticket} (silent success)`, add to `wave_tickets` and `completed_this_session`, and skip the retry.
- [x] **Silent-success check in timeout handler:** Same check before retry in the timeout path (`conductor.py` ~line 1171).
- [x] **Silent-success check in non-zero exit handler:** Same check before retry in the non-zero exit path (`conductor.py` ~line 1175).
- [x] **Gate the IN_PROGRESS pre-claim check:** Modify `worker_dispatch.md` step 2 so that the pre-claim check is skipped when the dispatch includes a `{checkpoint_context}` section (indicating this is a resume). The check should still apply for fresh dispatches to prevent genuine duplicate dispatch.
- [x] **Fallback for no-checkpoint resume:** Even without a checkpoint file, if the conductor detects the ticket is IN_PROGRESS and is dispatching a retry (retry count > 0), the dispatch prompt must include a note: "This ticket is IN_PROGRESS from a previous session that was interrupted. Assess the current state of the branch and ticket before proceeding."
- [x] All existing conductor tests pass (`orchestrator/test_harness.py`).

## Implementation Notes

- The `read_ticket_status()` utility already exists in `conductor.py` — reuse it.
- The pre-claim check in `worker_dispatch.md` is a prompt instruction, not code. Modify the prompt text to be conditional on `{checkpoint_context}`.
- The `{checkpoint_context}` template variable will be fully implemented in TICKET-0185, but this ticket must ensure the prompt structure supports it (i.e., add the variable placeholder even if it's empty for now).

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created ticket — P0 fix for dead-lock and silent-success detection gaps
- 2026-03-01 [tools-devops-engineer] Starting work — dependency TICKET-0235 verified DONE
- 2026-03-01 [tools-devops-engineer] DONE — commit 637e8fb, PR https://github.com/sqlhammer/Hammer-Forge-Studio/pull/273 (merged d62aaed). All 6 acceptance criteria met. 13/13 conductor tests pass.
