---
id: TICKET-0134
title: "Bugfix — branch name parsing does not strip '+' worktree prefix"
type: BUGFIX
status: DONE
priority: P0
owner: systems-programmer
created_by: qa-engineer
created_at: 2026-02-26
updated_at: 2026-02-26
milestone: "M7"
phase: "Refactoring"
depends_on: []
blocks: []
tags: [orchestrator, bugfix, p0, conductor, git]
---

## Summary

`conductor.py:876` parses `git branch --list orch/*` output to find branches to merge. The code uses `lstrip("* ")` to strip leading `*` and space characters. However, git prefixes branches checked out in worktrees with `+`. Since `+` is not in the character set being stripped, the branch name becomes `+ orch/gameplay-programmer/TICKET-0113` (with `+` and space prefix), causing `git merge` to fail with "not something we can merge".

**Evidence from `activity.log`:**
```
[MERGE ] Merging + orch/gameplay-programmer/TICKET-0113 -> main
[ERROR ] Merge conflict on + orch/gameplay-programmer/TICKET-0113: merge: + orch/gameplay-programmer/TICKET-0113 - not something we can merge
```

This error repeats for every branch across all 4 waves.

## Acceptance Criteria

- [x] Branch name parsing correctly strips `+`, `*`, and space prefixes from `git branch --list` output
- [x] Merges succeed for branches checked out in worktrees
- [x] Add a test or assertion that branch names contain no leading whitespace or prefix characters before passing to `git merge`

## Implementation Notes

- Minimal fix: change `lstrip("* ")` to `lstrip("*+ ")` at `conductor.py:876`
- More robust fix: use regex `re.sub(r'^[*+ ]+', '', branch)` to strip any combination of prefix characters
- Git branch prefixes: `*` = current branch, `+` = checked out in a linked worktree
- Consider using `git for-each-ref --format='%(refname:short)' refs/heads/orch/` instead of `git branch --list` for cleaner output without decorations

## Activity Log

- 2026-02-26 [qa-engineer] Created from orchestrator diagnostic — branch prefix parsing causes 100% merge failure rate
- 2026-02-26 [systems-programmer] Implemented: `re.sub(r'^[*+ ]+', '', b.strip())` in `_merge_pending_branches`. Commit cc49fe53, PR #84.
