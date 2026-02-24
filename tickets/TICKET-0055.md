---
id: TICKET-0055
title: "Abolish sprints — formalize Phase Gate model"
type: TASK
status: DONE
priority: P1
owner: producer
created_by: studio-head
created_at: 2026-02-23
updated_at: 2026-02-23
milestone: ""
milestone_gate: ""
depends_on: []
blocks: []
tags: ["process", "documentation"]
---

## Summary

Studio Head directive to replace the sprint model with a Phase Gate model. All project documentation must be updated to remove sprint references and introduce the new concepts: Phases (scope-bounded work containers within a milestone), Phase Gates (automated checkpoints when all tickets in a phase reach DONE), Studio Head Touchpoints (three defined engagement points per milestone), and Process Violation Enforcement Rules (mechanical rules enforced by the Producer).

## Acceptance Criteria

- [ ] `docs/studio/milestones.md` updated: Phases field added to schema, M4 has explicit phases block, M5+ flagged for Studio Head phase definition, Phase Gate Checklist appendix added, no sprint language
- [ ] `CLAUDE.md` updated: no sprint language, Phase Gate Protocol section added, Studio Head Touchpoints section added, Process Violation Enforcement Rules section added
- [ ] `docs/studio/onboarding.md` updated: no sprint references, Phase model explanation added for new agents
- [ ] `docs/studio/templates/phase-gate-summary.md` created with all required fields
- [ ] Sprint report files moved to `docs/studio/archive/` with `[ARCHIVED]` header line
- [ ] `tickets/README.md` updated: optional `phase:` field added to schema, dependency gate rule documented, sprint language removed

## Implementation Notes

Studio Head directive received 2026-02-23. All changes are documentation-only — no code changes.

Files to update:
- `docs/studio/milestones.md`
- `CLAUDE.md`
- `docs/studio/onboarding.md`
- `tickets/README.md`

Files to create:
- `docs/studio/templates/phase-gate-summary.md`
- `docs/studio/archive/2026-02-21-sprint.md`
- `docs/studio/archive/2026-02-22-sprint.md`

Files to remove (after archiving):
- `docs/studio/reports/2026-02-21-sprint.md`
- `docs/studio/reports/2026-02-22-sprint.md`

## Handoff Notes

N/A — Producer owns this ticket end-to-end.

## Activity Log

- 2026-02-23 [producer] Created ticket per Studio Head directive
- 2026-02-23 [producer] Status changed to IN_PROGRESS
- 2026-02-23 [producer] All documentation updated — TICKET-0055 DONE
