---
id: TICKET-0185
title: "Resume dispatch with checkpoint context injection"
type: FEATURE
status: IN_PROGRESS
priority: P1
owner: tools-devops-engineer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "M9"
phase: "Orchestrator Resilience"
depends_on: [TICKET-0182, TICKET-0183]
blocks: []
tags: [orchestrator, conductor, resilience, resume, checkpoint, dispatch]
---

## Summary

When an agent session is interrupted and later retried, the new session starts completely fresh with no knowledge of what the previous session accomplished. This ticket closes that gap by injecting checkpoint context into the worker dispatch prompt, enabling the resumed agent to pick up where the previous session left off.

See `docs/engineering/orchestrator-resilience-plan.md` Section 2.3 (R8) and Section 2.4 (Resume Handshake).

## Acceptance Criteria

### Worker Dispatch Prompt Changes
- [x] Add `{checkpoint_context}` template variable to `orchestrator/prompts/worker_dispatch.md`.
- [x] When no checkpoint exists: `{checkpoint_context}` is empty string (no change to existing behavior).
- [x] When a checkpoint exists: `{checkpoint_context}` is populated with a structured resume briefing including:
  - Previous session's commit hash (if any)
  - Branch name and push status
  - PR URL and merge status (if any)
  - Current ticket status on disk
  - List of completed steps from the checkpoint
  - Explicit instructions for remaining steps
- [x] The resume briefing must override the IN_PROGRESS pre-claim check (coordinated with TICKET-0182).

### Conductor Dispatch Logic
- [x] In `_run_worker` (or its caller), before rendering the dispatch prompt, check for `orchestrator/checkpoints/{ticket_id}.checkpoint.json`.
- [x] If checkpoint exists: read it, render `{checkpoint_context}` with the resume briefing, log `[RESUME ] Dispatching {ticket} with checkpoint context`.
- [x] After successful completion of a resumed ticket: log `[RESUME ] {ticket} resumed successfully`, delete the checkpoint file.
- [x] After failed completion of a resumed ticket: log `[RESUME ] {ticket} resume failed`, update checkpoint with new attempt info.

### Producer Planning Integration
- [x] Add `{pending_checkpoints}` template variable to `orchestrator/prompts/plan_wave.md`.
- [x] Conductor populates it by scanning `orchestrator/checkpoints/` and listing each checkpoint's ticket ID, agent, and progress summary.
- [x] Producer uses this information to prioritize resumed tickets and avoid re-dispatching tickets that have unresolved checkpoint states.

### Testing
- [x] All existing conductor tests pass.
- [x] Add test case: checkpoint exists for ticket → dispatch prompt includes checkpoint context.
- [x] Add test case: resumed worker reports done → checkpoint file is deleted, `[RESUME ]` logged.

## Implementation Notes

- The resume briefing format should be clear and actionable. Example:
  ```
  ## Resume Context
  You are resuming TICKET-0170 from an interrupted session.
  - Previous commit: abc1234 on branch orch/gameplay-programmer/TICKET-0170
  - Branch pushed to remote: yes
  - PR created: no
  - Ticket status on disk: IN_PROGRESS
  - Steps completed: read_ticket, verified_deps, marked_in_progress, implemented, committed, pushed

  YOUR REMAINING STEPS:
  1. Create a PR from orch/gameplay-programmer/TICKET-0170 targeting main
  2. Self-merge the PR
  3. Update the ticket status to DONE with an Activity Log entry
  4. Output your JSON result

  Do NOT redo work that was already completed.
  ```
- The `{pending_checkpoints}` variable in `plan_wave.md` is informational — the Producer uses it for awareness, not enforcement. Enforcement (gate deferral) is handled by TICKET-0187.

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created ticket — resume dispatch with checkpoint context
- 2026-03-02 [tools-devops-engineer] Starting work — dependencies TICKET-0182 and TICKET-0183 both DONE
