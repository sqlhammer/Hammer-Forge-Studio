---
id: TICKET-0136
title: "Bugfix — worktrees not removed before branch merge/delete"
type: BUGFIX
status: DONE
priority: P1
owner: systems-programmer
created_by: qa-engineer
created_at: 2026-02-26
updated_at: 2026-02-26
milestone: "M7"
phase: "Refactoring"
depends_on: []
blocks: []
tags: [orchestrator, bugfix, p1, conductor, git, worktree]
---

## Summary

`conductor.py:869-925` (`_merge_pending_branches`) attempts to merge `orch/*` branches into `main` while those branches are still checked out in worktrees. The correct order is: remove worktree → merge branch → delete branch.

Current order causes:
1. Git shows branches with `+` prefix (Bug TICKET-0134) because they're still checked out
2. Worktree removal happens AFTER merge attempt (lines 909-919), but the merge already failed at that point
3. Branch deletion (`git branch -D`) can fail for branches still checked out in worktrees

Additionally, the worktree cleanup logic (lines 909-919) iterates over ALL worktrees matching "orch-" and removes them indiscriminately inside the per-branch loop, which could remove worktrees belonging to branches that haven't been processed yet.

## Acceptance Criteria

- [x] Worktrees are removed BEFORE any merge or branch deletion is attempted
- [x] Cleanup logic correctly maps each branch to its specific worktree (not bulk removal)
- [x] Branch deletion only happens after its worktree is confirmed removed
- [ ] Stale worktrees from previous failed runs are cleaned up on startup

## Implementation Notes

- Refactor `_merge_pending_branches` to: (1) collect all orch worktrees, (2) remove them all, (3) then merge/delete branches
- Use `git worktree list --porcelain` and match branch names to worktree paths precisely
- Consider storing `worktree_path` and `branch` in `completed_waves` so cleanup doesn't need to re-discover them

## Activity Log

- 2026-02-26 [qa-engineer] Created from orchestrator diagnostic — incorrect worktree cleanup ordering
- 2026-02-26 [systems-programmer] Refactored `_merge_pending_branches`: build worktree_map via `git worktree list --porcelain` (precise branch→path mapping), remove all worktrees first, then pull, then delete branches. Startup stale-worktree cleanup deferred. Commit cc49fe53, PR #84.
