---
id: TICKET-0137
title: "Bugfix — TICKET-0117 worker produces empty output and crashes"
type: BUGFIX
status: OPEN
priority: P2
owner: systems-programmer
created_by: qa-engineer
created_at: 2026-02-26
updated_at: 2026-02-26
milestone: "M7"
phase: "Refactoring"
depends_on: []
blocks: []
tags: [orchestrator, bugfix, p2, conductor, process-management]
---

## Summary

Both TICKET-0117 worker invocations produced completely empty stdout and stderr:

- Attempt 1 (wave 3): exit code `1`, 0 bytes output
- Attempt 2 (wave 4): exit code `3221225786` (`0xC000013A` = Windows `STATUS_CONTROL_C_EXIT`), 0 bytes output

The Claude CLI process either crashed immediately or was killed before producing any output. Possible causes:

1. **Signal propagation**: The conductor's `signal.signal(SIGINT, handler)` at line 467 may propagate Ctrl+C to child processes. On Windows, console signals are sent to all processes in the console group. The handler kills `self._active_proc`, but with concurrent workers, only one proc is tracked (the last one to call `on_proc_start`).
2. **Worktree state**: The worktree may have been in a bad state from a previous failed attempt (the `create_worktree` function force-removes and recreates, but the branch may have stale state).
3. **Resource contention**: Another process may have held a lock on the worktree directory.

## Acceptance Criteria

- [ ] Conductor logs a diagnostic message when a worker produces empty stdout (distinguishing "crash" from "no output")
- [ ] `_active_proc` tracking supports multiple concurrent workers (e.g., a set instead of a single reference)
- [ ] Signal handler kills ALL active worker processes on shutdown, not just the last one registered
- [ ] Worker startup validates the worktree is in a clean state before dispatching Claude CLI

## Implementation Notes

- Change `self._active_proc` to `self._active_procs: set` and update `_track_proc` / shutdown handler accordingly
- Add a pre-flight check in `_run_worker` that verifies the worktree directory exists and `git status` is clean
- Consider adding a minimum output size check — if stdout is empty and exit code is non-zero, log it as `CRASH` not `FAILED`
- Exit code `3221225786` = `0xC000013A` is the Windows STATUS_CONTROL_C_EXIT code

## Activity Log

- 2026-02-26 [qa-engineer] Created from orchestrator diagnostic — empty worker output on TICKET-0117
