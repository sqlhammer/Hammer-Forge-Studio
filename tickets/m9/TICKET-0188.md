---
id: TICKET-0188
title: "Documentation — resilience runbook, CLAUDE.md updates, and config reference"
type: TASK
status: OPEN
priority: P2
owner: producer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "M9"
phase: "Orchestrator Resilience"
depends_on: [TICKET-0182, TICKET-0183, TICKET-0184, TICKET-0185, TICKET-0186, TICKET-0187, TICKET-0189, TICKET-0190, TICKET-0191]
blocks: []
tags: [orchestrator, documentation, resilience, runbook, CLAUDE.md]
---

## Summary

After all resilience implementation tickets are complete, this ticket updates all project documentation to reflect the new checkpoint system, LIMIT_WAIT state, suspension logging, and resume protocols. It also creates a resilience runbook for human operators (Studio Head) to understand and respond to suspension events.

## Acceptance Criteria

### Resilience Runbook
- [ ] Create `docs/engineering/orchestrator-resilience-runbook.md` covering:
  - What is a suspension checkpoint and when is one created
  - How to read `orchestrator/suspension.log` (field reference, event types)
  - How to manually inspect/clear checkpoints in `orchestrator/checkpoints/`
  - What LIMIT_WAIT means and how to override it (e.g., if you know the limit has lifted)
  - What "gate deferred" means and how to force a gate if checkpoints are false positives
  - Troubleshooting: common scenarios and resolution steps
  - Reference to the full risk analysis in `docs/engineering/orchestrator-resilience-plan.md`

### CLAUDE.md Updates
- [ ] Add a "Suspension & Resume" subsection under the "Git Workflow" section in root `CLAUDE.md` explaining:
  - Checkpoint files exist at `orchestrator/checkpoints/` and are runtime state (not committed)
  - If an agent is dispatched with `{checkpoint_context}`, it must follow resume instructions instead of starting fresh
  - Agents must never delete checkpoint files manually — the conductor manages them
- [ ] Add checkpoint cleanup as step 7 in the "On Milestone Close" checklist: "Verify `orchestrator/checkpoints/` is empty. If any checkpoint files remain, investigate before closing — they indicate unresolved suspended work."

### Agent CLAUDE.md Template Update
- [ ] Update `agents/_template/CLAUDE.md` to include a "Resume Protocol" section explaining:
  - If your dispatch prompt includes a "Resume Context" section, you are resuming interrupted work
  - Follow the remaining steps listed in the resume context exactly
  - Do not redo completed steps (e.g., do not re-commit already-committed code)
  - Report outcome normally — the conductor tracks that this was a resume

### Orchestration Architecture Doc
- [ ] Update `docs/engineering/orchestration-architecture.md` to document:
  - The new `LIMIT_WAIT` state in the state machine diagram
  - The checkpoint system (directory, schema, lifecycle)
  - The suspension log (`suspension.log` — format, retention)
  - Gate deferral on unresolved checkpoints

### Config Reference
- [ ] Update `orchestrator/config.json` inline comments or create `docs/engineering/orchestrator-config-reference.md` documenting all config fields including new `limit_wait` section.

### Testing
- [ ] All documentation references actual file paths and schemas that exist in the codebase (no stale references).
- [ ] Runbook scenarios are tested against the actual conductor behavior (manual verification).

## Implementation Notes

- This ticket depends on all other resilience tickets because it documents their final implementations.
- The CLAUDE.md checkpoint cleanup step requires Studio Head approval per the resilience plan (Task 4, P3 row for "Checkpoint cleanup at milestone close").
- Keep documentation concise and actionable — match the existing doc style in `docs/engineering/`.

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created ticket — documentation updates for resilience system
