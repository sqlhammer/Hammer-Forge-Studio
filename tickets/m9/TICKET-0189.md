---
id: TICKET-0189
title: "Conductor-level gate detection fallback when Producer is unavailable"
type: FEATURE
status: DONE
priority: P2
owner: tools-devops-engineer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "M9"
phase: "Orchestrator Resilience"
depends_on: [TICKET-0183]
blocks: []
tags: [orchestrator, conductor, resilience, gate-detection, fallback]
---

## Summary

If the Producer hits a usage limit during the planning wave where it would emit `gate_blocked`, the gate never fires. The phase sits in limbo even though every ticket is DONE on disk. The conductor should be able to detect phase completion independently and emit the gate as a fallback, without relying on the Producer.

This was previously bundled into TICKET-0186 but is an independent feature addressing Risk R7. Split out for cleaner scope.

See `docs/engineering/orchestrator-resilience-plan.md` Risk R7 and Section 2.3 (R7 handling).

## Acceptance Criteria

### Phase-Ticket Mapping
- [x] New utility function `get_phase_tickets(milestone, phase) -> list[str]` that reads all ticket files in `tickets/{milestone}/` and returns IDs where `phase:` matches the given phase name.
- [x] Cache the mapping per wave to avoid re-reading ticket files on every evaluation cycle.

### Gate Detection in Evaluating
- [x] After each `_do_evaluating` cycle, before transitioning to `PLANNING`, call `get_phase_tickets()` for the current phase.
- [x] For each ticket in the phase, read its `status:` from disk via `read_ticket_status()`.
- [x] If ALL tickets in the current phase have `status: DONE` on disk, and the Producer has not already emitted a `gate_blocked` action in this wave, the conductor emits the gate itself.
- [x] Gate emitted by the conductor uses the same `pending_gate.json` format and `GATE_BLOCKED` state transition as Producer-emitted gates.
- [x] The `pending_gate.json` must include: `milestone`, `phase`, `next_phase` (read from milestone doc or inferred from ticket ordering), `summary: "Conductor fallback — Producer unavailable"`, `requested_at`.

### Logging
- [x] Log `[GATE ] Conductor detected phase completion — emitting gate (Producer fallback)` when the fallback fires.
- [x] Log `[GATE ] Phase {phase} has {N}/{total} tickets DONE — not ready` at DEBUG level when the check runs but the phase is not yet complete (do not log this every cycle — only on first check per wave).

### Guard Rails
- [x] This is a fallback only. If the Producer successfully emits a gate in a wave, the conductor must NOT double-emit. Track whether a gate was already emitted in the current wave via a `_gate_emitted_this_wave` flag, reset at wave start.
- [x] The fallback must respect the checkpoint-based gate deferral from TICKET-0187: if unresolved checkpoints exist for phase tickets, do NOT emit the gate even if all tickets are DONE on disk.

### Testing
- [x] All existing conductor tests pass.
- [x] Add test case: all phase tickets DONE on disk, Producer planning fails → conductor emits gate on next evaluation cycle.
- [x] Add test case: Producer successfully emits gate → conductor does not double-emit.

## Implementation Notes

- Determining `next_phase` requires knowing the phase ordering. Options: (a) read milestone notes from `milestones.md` and parse phase tables, (b) derive from ticket files by finding the next distinct phase value in ID order, or (c) store the phase sequence in `state.json` at milestone start. Option (c) is simplest and most reliable — `start_milestone.py` already reads milestone structure.
- The phase-ticket cache should be invalidated when `state["phase"]` changes.

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created ticket — split from TICKET-0186 for independent scope
- 2026-03-02 [tools-devops-engineer] Starting work — implementing conductor-level gate detection fallback
- 2026-03-02 [tools-devops-engineer] DONE — implemented get_phase_tickets(), get_next_phase(), _check_fallback_gate(), _do_gate_blocked(); added GATE_BLOCKED state; all 19 tests pass. Commit: 94903f3, PR: https://github.com/sqlhammer/Hammer-Forge-Studio/pull/284
