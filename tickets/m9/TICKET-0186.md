---
id: TICKET-0186
title: "UID commit idempotency — make _handle_uid_commits restartable"
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
tags: [orchestrator, conductor, resilience, uid-commit, idempotency]
---

## Summary

The `_handle_uid_commits` method runs `git add`, `git commit`, `git push` as three sequential subprocess calls with no atomicity or precondition checks. If the conductor is interrupted mid-sequence (usage limit, crash, SIGINT), the main repo is left in dirty state — staged but uncommitted files, or committed but unpushed changes — that blocks conductor restart via git pull failure.

This ticket makes the UID commit procedure idempotent and restartable by adding precondition checks to each step and a persistent flag that triggers completion on next startup.

See `docs/engineering/orchestrator-resilience-plan.md` Risk R5.

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

### Testing
- [ ] All existing conductor tests pass.
- [ ] Add test case: conductor restarted with `_uid_commit_pending: true` and staged .uid files → completes the commit and push.
- [ ] Add test case: conductor restarted with `_uid_commit_pending: true` and already-pushed commit → flag cleared without duplicate push.

## Implementation Notes

- The UID commit flag must be written to `state.json` atomically (already using `save_state` with `os.fsync`).
- Be careful not to create empty commits — the precondition checks prevent this.
- The startup check for `_uid_commit_pending` should run before the main loop and before any `git pull` attempt (since dirty state from an interrupted UID commit is precisely what blocks git pull).

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created ticket — UID idempotency and conductor gate fallback
- 2026-02-27 [producer] Split conductor-level gate detection into TICKET-0189 — this ticket now covers UID idempotency only
