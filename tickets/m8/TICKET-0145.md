---
id: TICKET-0145
title: "Conductor — ticket locking to prevent duplicate concurrent dispatch"
type: TASK
status: OPEN
priority: P1
owner: tools-devops-engineer
created_by: systems-programmer
created_at: 2026-02-26
updated_at: 2026-02-26
milestone: "M8"
phase: "Orchestrator Infrastructure"
depends_on: []
blocks: [TICKET-0146, TICKET-0148]
tags: [orchestrator, conductor, locking, concurrency, infrastructure]
---

## Summary

The conductor currently has no ticket-level locking. `active_workers` tracks in-flight workers within a single wave, but the producer's planning prompt explicitly tells it to ignore `IN_PROGRESS` ticket file status — treating all stale IN_PROGRESS as "available". This creates a real risk of two workers being dispatched on the same ticket across interrupted or overlapping sessions.

This ticket introduces a proper active-ticket lock set that the conductor maintains in state.json, passes to the producer at planning time, and validates at dispatch time. Workers also check the ticket file before claiming to catch races within a wave.

## Acceptance Criteria

- [ ] **state.json — `active_ticket_ids` field**: Add `active_ticket_ids: []` to `create_initial_state()` in `orchestrator/conductor.py`
- [ ] **Dispatch guard**: In `_do_dispatching()`, before adding a worker for each assignment, check whether `assignment["ticket"]` is in `state["active_ticket_ids"]`. If it is, skip the assignment and log `WARNING: {ticket} already in active_ticket_ids — skipping duplicate dispatch`
- [ ] **Lock population**: After building the `workers` list in `_do_dispatching()`, set `state["active_ticket_ids"]` to the set of ticket IDs from the workers list
- [ ] **Lock release**: In `_do_working()`, after each worker task completes (regardless of outcome), remove its ticket from `state["active_ticket_ids"]`. Ensure this happens per-worker as results come in, not only at the end of the wave
- [ ] **Planning prompt — pass locked tickets**: In `_do_planning()`, add `"active_ticket_ids"` to the `template_vars` dict (as a JSON-serialized list)
- [ ] **Planning prompt — update instructions**: In `orchestrator/prompts/plan_wave.md`, replace the line *"IN_PROGRESS tickets from prior waves are NOT active locks"* with: *"Tickets listed in `active_ticket_ids` are currently in-flight — do NOT assign them in this wave under any circumstances."*
- [ ] **Worker dispatch prompt — pre-claim check**: In `orchestrator/prompts/worker_dispatch.md`, add a step before "Update the ticket status to IN_PROGRESS" instructing the worker to: read the ticket file and verify status is not already `IN_PROGRESS`; if it is, output `outcome: "blocked"` with `summary: "Ticket is already IN_PROGRESS — possible duplicate dispatch"` and stop
- [ ] **Activity log**: Log a `LOCK` event in the orchestrator activity.log when `active_ticket_ids` is populated at dispatch, listing all locked ticket IDs

## Implementation Notes

- `active_ticket_ids` should be a list (not a set) for JSON serialization compatibility
- Lock release in `_do_working()` should be defensive: remove ticket only if present (avoid KeyError-style failures)
- This is a prerequisite for both TICKET-0146 (multi-instance) and TICKET-0148 (producer ticket creation) — both assume locking is in place

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-26 [systems-programmer] Created ticket to address missing ticket-level locking in conductor
