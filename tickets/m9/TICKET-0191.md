---
id: TICKET-0191
title: "Log archive rotation at milestone close"
type: TASK
status: IN_PROGRESS
priority: P3
owner: tools-devops-engineer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "M9"
phase: "Orchestrator Resilience"
depends_on: [TICKET-0187]
blocks: []
tags: [orchestrator, conductor, resilience, logging, archive, rotation, milestone-close]
---

## Summary

The conductor's `activity.log` and the new `suspension.log` (TICKET-0187) grow indefinitely across milestones. When the conductor transitions to `IDLE` via the `milestone_complete` action, these logs should be archived to milestone-specific files and the active logs reset, keeping the working directory clean and making historical logs easy to locate.

See `docs/engineering/orchestrator-resilience-plan.md` Task 3 Section 3.4 (Retention Policy).

## Acceptance Criteria

### Archive on Milestone Complete
- [ ] When the conductor's status transitions to `IDLE` via `milestone_complete` action, execute log rotation before finalizing the state.
- [ ] Archive `orchestrator/activity.log` → `orchestrator/logs/activity-{milestone}.log` (e.g., `activity-m8.log`).
- [ ] Archive `orchestrator/suspension.log` → `orchestrator/logs/suspension-{milestone}.log` (if `suspension.log` exists; skip if it doesn't).
- [ ] After archiving, truncate the active log files (create fresh empty files) so the next milestone starts with clean logs.
- [ ] Log `[SYSTEM ] Archived activity.log → logs/activity-{milestone}.log` (this entry goes in the ACTIVE log before truncation, and is therefore the last entry in the archived file).

### Archive Safety
- [ ] If `orchestrator/logs/activity-{milestone}.log` already exists (e.g., milestone was restarted), append to the existing archive rather than overwriting.
- [ ] If `orchestrator/logs/` directory does not exist, create it.
- [ ] Archive operation must be atomic: copy then truncate, not move (prevents data loss if truncation is interrupted).

### Checkpoint Anomaly Check
- [ ] Before archiving, scan `orchestrator/checkpoints/` for any remaining checkpoint files.
- [ ] If any checkpoint files exist: log `[WARNING ] {N} unresolved checkpoint(s) found at milestone close — investigate before proceeding` and list the ticket IDs.
- [ ] Do NOT block the archive — this is a warning, not a gate. The checkpoint files themselves are left in place for the next milestone or manual investigation.

### Testing
- [ ] All existing conductor tests pass.
- [ ] Add test case: conductor reaches `milestone_complete` → `activity.log` archived to `logs/activity-{milestone}.log`, active log reset to empty.
- [ ] Add test case: archive target already exists → content is appended, not overwritten.

## Implementation Notes

- The `milestone_complete` transition currently happens in `_do_planning` when the Producer returns `action: "milestone_complete"`. The log rotation should be added to this code path, after setting status to `IDLE` but before `save_state`.
- Use `shutil.copy2` for the archive copy, then open the active log in write mode to truncate.
- The `orchestrator/logs/` directory already exists (worker logs are written there), so the mkdir is purely defensive.
- The checkpoint anomaly check is informational — it feeds into the milestone close checklist in TICKET-0188 (documentation).

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created ticket — log archive rotation (split from TICKET-0187)
- 2026-03-02 [tools-devops-engineer] Starting work — implementing log archive rotation on milestone_complete, checkpoint anomaly scan, and tests
