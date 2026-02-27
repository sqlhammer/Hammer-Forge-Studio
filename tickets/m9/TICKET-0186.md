---
id: TICKET-0186
title: "UID commit idempotency and conductor-level gate detection fallback"
type: TASK
status: OPEN
priority: P2
owner: tools-devops-engineer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "M9"
phase: "Orchestrator Resilience"
depends_on: [TICKET-0183]
blocks: []
tags: [orchestrator, conductor, resilience, uid-commit, gate-detection, idempotency]
---

## Summary

Two independent conductor hardening improvements bundled into one ticket:

1. **UID commit idempotency (R5):** The `_handle_uid_commits` method runs `git add`, `git commit`, `git push` as three sequential subprocess calls with no atomicity or precondition checks. If the conductor is interrupted mid-sequence, the main repo is left in dirty state that blocks restart.

2. **Conductor-level gate detection fallback (R7):** If the Producer hits a usage limit during the planning wave where it would emit `gate_blocked`, the gate never fires. The conductor should be able to detect phase completion independently as a fallback.

See `docs/engineering/orchestrator-resilience-plan.md` Risks R5 and R7.

## Acceptance Criteria

### UID Commit Idempotency
- [ ] Add `_uid_commit_pending` boolean flag to `state.json` (default `false`).
- [ ] Set flag to `true` before entering `_handle_uid_commits`, persist to disk.
- [ ] Make each step in the UID sequence check preconditions:
  - `git add`: check if .uid files are already staged (`git diff --cached --name-only -- '*.gd.uid'`). Only add if not already staged.
  - `git commit`: check if there are staged changes (`git diff --cached --quiet`). Only commit if there are staged changes.
  - `git push`: check if local is ahead of remote (`git rev-list --count origin/main..HEAD`). Only push if ahead.
- [ ] Clear `_uid_commit_pending` flag after successful completion of all steps.
- [ ] On conductor startup: if `_uid_commit_pending` is `true`, run `_handle_uid_commits` before entering the main loop.
- [ ] Log each step's precondition check result for auditability.

### Conductor-Level Gate Detection
- [ ] After each `_do_evaluating` cycle, before transitioning to `PLANNING`, count all tickets in the current phase by reading ticket files from disk.
- [ ] If all tickets in the current phase have `status: DONE` on disk, and the Producer has not already emitted a `gate_blocked` action in this wave, the conductor emits the gate itself.
- [ ] Gate emitted by conductor uses the same `pending_gate.json` format and `GATE_BLOCKED` state transition as Producer-emitted gates.
- [ ] Log: `[GATE ] Conductor detected phase completion — emitting gate (Producer fallback)`.
- [ ] This is a fallback only — if the Producer successfully emits a gate, the conductor does not double-emit.

### Testing
- [ ] All existing conductor tests pass.
- [ ] Add test case: conductor restarted with `_uid_commit_pending: true` and staged .uid files → completes the commit and push.
- [ ] Add test case: all phase tickets DONE, Producer fails → conductor emits gate on its own.

## Implementation Notes

- For gate detection, the conductor needs to know which tickets belong to the current phase. It can read ticket files and filter by `phase:` field matching `state["phase"]`. Cache the phase-ticket mapping per wave to avoid re-reading every ticket on every cycle.
- The UID commit flag must be written to `state.json` atomically (already using `save_state` with `os.fsync`).
- Be careful not to create empty commits — the precondition checks prevent this.

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created ticket — UID idempotency and conductor gate fallback
