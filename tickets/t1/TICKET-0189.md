---
id: TICKET-0189
title: "T-series milestone convention — orchestrator, docs, and process updates"
type: TASK
status: OPEN
priority: P1
owner: tools-devops-engineer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "T1"
phase: "Foundation"
depends_on: []
blocks: []
tags: [tooling, convention, orchestrator, t-series]
---

## Summary

Verify and complete T-series milestone convention support across the orchestrator codebase, process documentation, and agent instructions. The Producer made initial changes during T1 kickoff (milestone_status.py regex, CLAUDE.md branch patterns, producer CLAUDE.md conventions, prd.md Release Goals table). This ticket covers verification, testing, and any remaining edge cases.

## Acceptance Criteria

### Orchestrator Code Verification
- [ ] Verify `tools/milestone_status.py` correctly normalizes T-series IDs (`T1`, `t1` → `T1`)
- [ ] Verify `tools/milestone_status.py` auto-detection regex matches T-series rows in milestones.md
- [ ] Verify `orchestrator/conductor.py` handles T-series milestone IDs correctly (lowercase directory creation at `tickets/t1/`, ticket reading, status parsing)
- [ ] Run `python tools/milestone_status.py T1` and confirm correct output for all 10 T1 tickets
- [ ] Run `python tools/milestone_status.py` (auto-detect) and confirm it finds the active milestone correctly when both M-series and T-series milestones are active

### Documentation Verification
- [ ] Root `CLAUDE.md` branch cleanup pattern includes `feature/t<N>/`
- [ ] `agents/producer/CLAUDE.md` ticket path convention includes T-series examples
- [ ] `docs/studio/prd.md` Release Goals table includes Tooling Milestones section
- [ ] `docs/studio/milestones.md` includes Tooling Milestones table and T1 milestone notes

### Edge Cases
- [ ] Milestone auto-detection prioritizes M-series Active milestones over T-series Planning milestones (or handles multiple active milestones gracefully)
- [ ] Archive path `tickets/_archive/t1/` works correctly at milestone close
- [ ] No regression in existing M-series milestone handling

## Implementation Notes

- Initial changes were made by the Producer during T1 milestone kickoff. This ticket is for the tools-devops-engineer to verify correctness, run tests, and handle edge cases.
- The `normalize_milestone()` function now checks for `T` prefix before stripping `M`/`m`. Verify this doesn't break inputs like `T` alone (without a number).
- The auto-detect regex changed from `r"^\|\s*(M\d+)\s*\|"` to `r"^\|\s*([MT]\d+)\s*\|"`. Confirm this works with the milestones.md table format.

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created ticket — T-series convention verification and testing
