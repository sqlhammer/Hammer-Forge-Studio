---
id: TICKET-0135
title: "Bugfix — double merge: workers self-merge PR then conductor retries local merge"
type: BUGFIX
status: OPEN
priority: P1
owner: systems-programmer
created_by: qa-engineer
created_at: 2026-02-26
updated_at: 2026-02-26
milestone: "M7"
phase: "Refactoring"
depends_on: []
blocks: []
tags: [orchestrator, bugfix, p1, conductor, git, merge]
---

## Summary

There is a conflicting merge strategy between the worker dispatch prompt and the conductor's evaluating phase:

1. `worker_dispatch.md` tells agents: "Push your branch and create a PR targeting `main`. Self-merge the PR immediately." Workers do this — TICKET-0111 (PR#79), TICKET-0112 (PR#82), TICKET-0113 (PR#78) all merged successfully via GitHub.

2. `conductor.py:869` (`_merge_pending_branches`) then tries to ALSO merge the same `orch/*` branches locally into `main`. But the local `main` hasn't pulled the GitHub-merged changes (no `git pull` before merge), so the local merge can conflict or produce duplicate commits.

The system must use ONE merge strategy, not both.

## Acceptance Criteria

- [ ] Exactly one merge path exists: either worker PR self-merge OR conductor local merge, not both
- [ ] If using worker PR merges: conductor pulls `main` after workers finish instead of merging locally; `_merge_pending_branches` becomes cleanup-only (remove worktrees, delete branches)
- [ ] If using conductor local merges: remove the PR self-merge instruction from `worker_dispatch.md`; workers only push their branch
- [ ] Document the chosen strategy in `orchestrator/README.md`

## Implementation Notes

- Recommended approach: keep worker PR self-merge (it provides a GitHub audit trail) and convert `_merge_pending_branches` into a cleanup step that does `git pull origin main` then removes worktrees and branches
- If keeping conductor merges, add `git pull origin main` before attempting local merges

## Activity Log

- 2026-02-26 [qa-engineer] Created from orchestrator diagnostic — dual merge strategy causes conflicts
