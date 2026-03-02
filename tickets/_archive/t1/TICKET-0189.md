---
id: TICKET-0189
title: "T-series milestone convention — orchestrator, docs, and process updates"
type: TASK
status: DONE
priority: P1
owner: tools-devops-engineer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-03-01
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
- [x] Verify `tools/milestone_status.py` correctly normalizes T-series IDs (`T1`, `t1` → `T1`)
- [x] Verify `tools/milestone_status.py` auto-detection regex matches T-series rows in milestones.md
- [x] Verify `orchestrator/conductor.py` handles T-series milestone IDs correctly (lowercase directory creation at `tickets/t1/`, ticket reading, status parsing)
- [x] Run `python tools/milestone_status.py T1` and confirm correct output for all 10 T1 tickets
- [x] Run `python tools/milestone_status.py` (auto-detect) and confirm it finds the active milestone correctly when both M-series and T-series milestones are active

### Documentation Verification
- [x] Root `CLAUDE.md` branch cleanup pattern includes `feature/t<N>/`
- [x] `agents/producer/CLAUDE.md` ticket path convention includes T-series examples
- [x] `docs/studio/prd.md` Release Goals table includes Tooling Milestones section
- [x] `docs/studio/milestones.md` includes Tooling Milestones table and T1 milestone notes

### Edge Cases
- [x] Milestone auto-detection prioritizes M-series Active milestones over T-series Planning milestones (or handles multiple active milestones gracefully)
- [x] Archive path `tickets/_archive/t1/` works correctly at milestone close
- [x] No regression in existing M-series milestone handling

## Implementation Notes

- Initial changes were made by the Producer during T1 milestone kickoff. This ticket is for the tools-devops-engineer to verify correctness, run tests, and handle edge cases.
- The `normalize_milestone()` function now checks for `T` prefix before stripping `M`/`m`. Verify this doesn't break inputs like `T` alone (without a number).
- The auto-detect regex changed from `r"^\|\s*(M\d+)\s*\|"` to `r"^\|\s*([MT]\d+)\s*\|"`. Confirm this works with the milestones.md table format.

## Handoff Notes

All T-series convention support verified and working. Key findings:
- `normalize_milestone()` correctly handles `T1`→`T1`, `t1`→`T1`, and edge case `T`→`T` (no regression)
- Auto-detection returns M9 (first active M-series) when both M9 and T1 are Active — correct since M-series rows precede T-series in milestones.md
- conductor.py uses `milestone.lower()` throughout for directory operations, ensuring `T1` → `tickets/t1/`
- Updated usage docstrings in `tools/milestone_status.py` and help text in `orchestrator/conductor.py` to mention T-series examples

## Activity Log

- 2026-02-27 [producer] Created ticket — T-series convention verification and testing
- 2026-03-01 [tools-devops-engineer] Starting work — verifying T-series convention support across orchestrator, docs, and edge cases
- 2026-03-01 [tools-devops-engineer] DONE — all acceptance criteria verified; updated docstrings in milestone_status.py and conductor.py to document T-series support
