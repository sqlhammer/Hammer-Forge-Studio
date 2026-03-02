---
id: TICKET-0190
title: "Auto-remediation for silently-merged PRs with IN_PROGRESS tickets"
type: FEATURE
status: IN_PROGRESS
priority: P3
owner: tools-devops-engineer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-03-02
milestone: "M9"
phase: "Orchestrator Resilience"
depends_on: [TICKET-0183]
blocks: []
tags: [orchestrator, conductor, resilience, auto-remediation, PR, cleanup]
---

## Summary

When a worker merges its PR to main but exits before marking the ticket DONE (Risk R3), the code is on main but the ticket is stuck IN_PROGRESS. Currently this scenario dead-locks the ticket via the IN_PROGRESS pre-claim check on retry. TICKET-0182 prevents the dead-lock, and TICKET-0183 writes a checkpoint, but neither actively detects and resolves the "PR merged but ticket not updated" state.

This ticket adds an explicit auto-remediation step: the conductor probes GitHub for merged PRs associated with the ticket's branch and, if found, automatically marks the ticket DONE without requiring a retry dispatch.

See `docs/engineering/orchestrator-resilience-plan.md` Risk R3 and Section 2.3 (R3 handling).

## Acceptance Criteria

### Merged-PR Detection
- [ ] New method `_check_merged_pr(ticket_id, branch) -> dict | None` that calls `gh pr list --head {branch} --json number,url,state,merged --state all` and returns the PR data if a merged PR exists, `None` otherwise.
- [ ] Handle cases where the branch has been deleted from remote (PR may still be queryable via `--state merged`).

### Auto-Remediation in Result Processing
- [ ] During abnormal-exit processing in `_do_working`, after writing the checkpoint (TICKET-0183), check whether the ticket has a merged PR via `_check_merged_pr`.
- [ ] If merged PR found AND ticket is IN_PROGRESS on disk:
  1. Update the ticket file: set `status: DONE`, set `updated_at:` to today.
  2. Append to the ticket's Activity Log: `YYYY-MM-DD [conductor] Auto-completed — PR #{number} was merged but agent session terminated before updating ticket status`.
  3. Add the ticket to `completed_this_session`.
  4. Delete the checkpoint file (no longer needed).
  5. Log `[CLEANUP ] TICKET-NNNN auto-completed — PR #{number} merged, ticket updated to DONE`.
  6. Do NOT queue a retry (work is done).

### Auto-Remediation on Startup
- [ ] During the startup checkpoint scan (TICKET-0183), for each checkpoint where ticket is IN_PROGRESS, also run `_check_merged_pr` using the branch from the checkpoint.
- [ ] If merged PR found → same auto-remediation steps as above.

### Guard Rails
- [ ] Only auto-remediate when there is clear evidence of a merged PR. If the PR is open (not merged), do NOT auto-remediate — the work may be incomplete.
- [ ] Log all auto-remediation actions to both `activity.log` and `suspension.log` (TICKET-0187) with event type `auto_remediated`.

### Testing
- [ ] All existing conductor tests pass.
- [ ] Add test case: worker exits abnormally, `gh pr list` returns merged PR → ticket auto-remediated to DONE, no retry queued.
- [ ] Add test case: worker exits abnormally, `gh pr list` returns open (not merged) PR → ticket NOT auto-remediated, retry queued normally.
- [ ] Add test case: checkpoint exists on startup with merged PR → auto-remediated during startup scan.

## Implementation Notes

- The `gh` CLI is already available and used in the conductor for other operations.
- Ticket file modification should use the same approach as agents: read the file, regex-replace the `status:` line, and append to the Activity Log section.
- This feature works in concert with TICKET-0183 (checkpoint writer provides the branch name) and TICKET-0182 (silent-success check catches DONE-on-disk cases). R3 auto-remediation specifically handles the case where ticket is NOT yet DONE on disk but the PR IS merged.

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created ticket — auto-remediation for silently-merged PRs (split from TICKET-0183)
- 2026-03-02 [tools-devops-engineer] Starting work — implementing _check_merged_pr, auto-remediation in _do_working and _scan_checkpoints_on_startup
