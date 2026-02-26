---
id: TICKET-0133
title: "Bugfix — conductor outcome check rejects 'completed' as invalid"
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
tags: [orchestrator, bugfix, p0, conductor]
---

## Summary

`conductor.py:726` checks `if outcome == "done"` to classify a worker's result as successful. The `worker_result.json` schema defines valid outcomes as `["done", "blocked", "failed", "partial"]`, but the worker dispatch prompt (`prompts/worker_dispatch.md`) never tells agents which exact value to use. Agents naturally output `"completed"`, which falls through to the `else` branch (line 733), gets logged as `PARTIAL`, and is queued for retry — even though the work succeeded.

This is the **primary cause of the 0% success rate** across all 4 orchestrator waves. All 3 tickets that actually completed (TICKET-0111, 0112, 0113) were treated as failures.

**Evidence from `activity.log`:**
```
[DONE    ] technical-artist <- TICKET-0111 (5m 44s, exit=0)
[PARTIAL ] technical-artist <- TICKET-0111: outcome=completed
[RETRY   ] TICKET-0111 queued for retry (attempt 1/3)
```

## Acceptance Criteria

- [x] Conductor accepts `"completed"` as equivalent to `"done"` (normalize on intake, e.g., map `"completed"` → `"done"`)
- [x] `worker_dispatch.md` prompt includes the exact expected outcome values (`done`, `blocked`, `failed`, `partial`) with clear instructions to use `"done"` for success
- [x] `worker_result.json` schema is embedded or referenced in the dispatch prompt so agents see the contract
- [x] Existing result files in `orchestrator/results/` parse correctly after the fix

## Implementation Notes

- Two-pronged fix: harden the conductor (accept synonyms) AND fix the prompt (tell agents the right value)
- Conductor fix location: `conductor.py`, `_do_working` method, around line 717
- Prompt fix location: `orchestrator/prompts/worker_dispatch.md`
- Consider adding `"completed"` to the schema's enum as a valid alias, or normalize before comparison

## Activity Log

- 2026-02-26 [qa-engineer] Created from orchestrator diagnostic — outcome mismatch is root cause of 0% success rate
- 2026-02-26 [systems-programmer] Implemented: added outcome normalization in `_do_working` (maps "completed"→"done"), updated `worker_dispatch.md` with explicit outcome enum and embedded schema. Commit cc49fe53, PR #84.
