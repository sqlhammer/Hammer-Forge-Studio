---
id: TICKET-0147
title: "Conductor — dependency validation at dispatch time with session-completed tracking"
type: TASK
status: DONE
priority: P1
owner: tools-devops-engineer
created_by: systems-programmer
created_at: 2026-02-26
updated_at: 2026-02-26
milestone: "M7"
phase: "QA"
depends_on: []
blocks: []
tags: [orchestrator, conductor, dependencies, validation, infrastructure]
---

## Summary

Dependency enforcement currently lives only in the producer's planning logic and in each worker's pre-flight check. The conductor never independently validates dependencies before dispatching. If the producer makes an assignment error (or if ticket status on disk is stale), the conductor dispatches a worker that immediately returns `blocked` — wasting a worker budget and a wave slot.

This ticket adds two reinforcing improvements:

1. **Conductor-layer dependency validation**: before dispatching each assignment, the conductor reads the assigned ticket's `depends_on` list and verifies every dependency has `status: DONE`. If not, the assignment is skipped with a warning.
2. **Session-completed tracking + git pull before planning**: the conductor tracks which tickets completed in the current session and passes this to the producer. It also pulls latest git before each planning call so ticket status on disk reflects the most recent agent commits.

## Acceptance Criteria

- [x] **`read_ticket_status(ticket_id, milestone)` utility**: Add a function to `conductor.py` that reads `tickets/{milestone}/{ticket_id}.md`, parses the YAML frontmatter, and returns the `status` field value (e.g., `"DONE"`, `"IN_PROGRESS"`, `"OPEN"`). Returns `"UNKNOWN"` if the file doesn't exist or can't be parsed.
- [x] **`validate_dependencies(ticket_id, milestone)` utility**: Add a function that reads the target ticket file, extracts the `depends_on` list, and calls `read_ticket_status()` for each. Returns `(True, [])` if all are `DONE`, or `(False, [list of unmet dep IDs])` if any are not. Also treats tickets in `state["completed_this_session"]` as `DONE` regardless of filesystem status.
- [x] **Dispatch-time validation**: In `_do_dispatching()`, call `validate_dependencies(ticket_id, milestone)` for each assignment before creating a worker. If it returns False, skip the assignment and log: `SKIP: {ticket} dependency unmet — {dep} is not DONE (producer planning error)`
- [x] **`completed_this_session` state field**: Add `completed_this_session: []` to `create_initial_state()`. In `_do_working()`, when a worker returns `outcome: "done"`, append its ticket ID to `state["completed_this_session"]`.
- [x] **Pass to producer prompt**: In `_do_planning()`, add `"completed_this_session"` to `template_vars` (JSON-serialized list). In `orchestrator/prompts/plan_wave.md`, add `completed_this_session` to the Current Context block with instruction: *"Tickets in `completed_this_session` are definitively DONE in this session — treat them as DONE even if the ticket file hasn't been updated yet."*
- [x] **Git pull before planning**: In `_do_planning()`, before calling the producer, run `git -C {REPO_ROOT} pull` as a subprocess. Log the result at INFO level. If the pull fails (non-zero exit), log a WARNING but continue — a stale filesystem is better than a blocked conductor.
- [x] **Worker dispatch prompt — abort early on unmet deps**: Confirm `orchestrator/prompts/worker_dispatch.md` still instructs workers to check `depends_on` and return `outcome: "blocked"` immediately if any dependency is not DONE. This is a defense-in-depth layer below the conductor-level check; keep it in place.

## Implementation Notes

- `read_ticket_status()` should parse frontmatter using simple line-by-line YAML extraction (no external library needed — just scan for `^status:` in the first 30 lines)
- `validate_dependencies()` must handle the case where `depends_on` is empty or null — return `(True, [])` immediately
- The `git pull` before planning should use `check=False` (don't raise on non-zero) and log stdout/stderr at DEBUG level to keep conductor output clean
- Session-completed tracking handles the common race condition where a worker commits and pushes but the next planning call happens before the git pull catches up

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-26 [systems-programmer] Created ticket to add conductor-layer dependency enforcement and session state tracking
- 2026-02-26 [tools-devops-engineer] Starting work on TICKET-0147
- 2026-02-26 [tools-devops-engineer] DONE — commit 647a159, PR https://github.com/sqlhammer/Hammer-Forge-Studio/pull/112
