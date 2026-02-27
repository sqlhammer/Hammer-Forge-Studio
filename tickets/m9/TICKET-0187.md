---
id: TICKET-0187
title: "Structured suspension logging and gate deferral on unresolved checkpoints"
type: FEATURE
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
tags: [orchestrator, conductor, resilience, logging, suspension, gate-deferral]
---

## Summary

Adds machine-readable structured logging for all suspension/resume events and a gate safety mechanism that prevents phase gates from passing when unresolved checkpoints exist. Together these ensure the Producer and Studio Head have full visibility into suspension states during gate evaluation.

See `docs/engineering/orchestrator-resilience-plan.md` Task 3 (Logging Specification) and Section 2.3 (R7 gate deferral).

## Acceptance Criteria

### Structured Suspension Log
- [ ] New log file: `orchestrator/suspension.log` — JSON-lines format (one JSON object per line).
- [ ] Add `orchestrator/suspension.log` to `.gitignore`.
- [ ] New `SuspensionLogger` class (or method on `ActivityLogger`) that writes entries matching the schema:
  ```json
  {
    "timestamp": "ISO-8601",
    "event": "limit_hit | suspended | resume_dispatched | resume_success | resume_failure | auto_remediated | zombie_detected",
    "agent": "agent-slug",
    "ticket": "TICKET-NNNN",
    "milestone": "mN",
    "phase": "Phase Name",
    "wave": 12,
    "checkpoint_path": "orchestrator/checkpoints/TICKET-NNNN.checkpoint.json",
    "retry_count": 1,
    "retry_reason": "usage_limit | implementation_failure",
    "notes": "Free-text"
  }
  ```
- [ ] All suspension-related events across the conductor (checkpoint write, checkpoint clear, resume dispatch, resume success/failure, auto-remediation, zombie detection, usage-limit detection) write to both `activity.log` (human-readable) and `suspension.log` (structured).

### Gate Deferral on Unresolved Checkpoints
- [ ] Before emitting a phase gate (whether from Producer or conductor fallback), check `orchestrator/checkpoints/` for any checkpoint files whose ticket belongs to the current phase.
- [ ] If any such checkpoints exist: do NOT emit the gate. Log `[WARNING ] Gate deferred — {N} unresolved checkpoint(s) exist for phase "{phase}"` and list the affected ticket IDs.
- [ ] Transition to `PLANNING` instead of `GATE_BLOCKED` so the conductor can re-dispatch the suspended tickets.
- [ ] Gate fires normally once all checkpoints for the phase are cleared.

### Testing
- [ ] All existing conductor tests pass.
- [ ] Add test case: checkpoint exists for phase ticket → gate is deferred, not emitted.
- [ ] Add test case: suspension event → entry appears in both `activity.log` and `suspension.log`.

## Implementation Notes

- `suspension.log` is append-only, same as `activity.log`. Open in append mode, write with flush.
- The gate deferral check is a simple directory scan + ticket-phase comparison. Keep it lightweight.
- Log archive rotation at milestone close is handled by TICKET-0191 (separate ticket).

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created ticket — structured suspension logging and gate deferral
- 2026-02-27 [producer] Moved log archive rotation to dedicated TICKET-0191
