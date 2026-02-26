---
id: TICKET-0138
title: "Bugfix — worker dispatch prompt missing output schema and field name contract"
type: BUGFIX
status: DONE
priority: P2
owner: systems-programmer
created_by: qa-engineer
created_at: 2026-02-26
updated_at: 2026-02-26
milestone: "M7"
phase: "Refactoring"
depends_on: []
blocks: []
tags: [orchestrator, bugfix, p2, prompt, schema]
---

## Summary

The worker dispatch prompt (`orchestrator/prompts/worker_dispatch.md`) tells agents to output JSON matching "the worker_result schema" but does not include the actual schema or specify exact field names and enum values. This leads to systematic mismatches:

1. **Outcome values**: Workers write `"completed"` instead of `"done"` (root cause of TICKET-0133)
2. **Field names**: Workers write `"ticket_id"` instead of `"ticket"` (all 3 result files have this)
3. **Extra fields**: Workers include non-schema fields like `"pr_number"`, `"pr_merged"`, `"notes"`, `"files_created"` vs `"files_changed"`
4. **Markdown wrapping**: Workers wrap their JSON in ` ```json ` code fences despite the prompt saying "No prose before or after the JSON"

The conductor's `extract_json_from_output` has workarounds for code fences and the `ticket_id`→`ticket` normalization, but the outcome mismatch has no workaround.

## Acceptance Criteria

- [x] `worker_dispatch.md` includes the full `worker_result.json` schema inline (or a clear example with all field names and enum values)
- [x] The prompt explicitly states: "Use `outcome: \"done\"` for success, `outcome: \"blocked\"` if dependencies unmet, `outcome: \"failed\"` for errors"
- [x] The prompt includes a concrete example JSON block showing the exact expected output format
- [x] The prompt reinforces: output raw JSON only, no markdown code fences

## Implementation Notes

- Embed the schema directly in the prompt template rather than referencing an external file agents can't see
- Add a concrete example block:
  ```
  Example output:
  {"ticket": "TICKET-0099", "outcome": "done", "summary": "...", "commit_hash": "abc123", ...}
  ```
- The conductor's `extract_json_from_output` already handles code fences and field normalization — keep those as defense-in-depth but fix the source

## Activity Log

- 2026-02-26 [qa-engineer] Created from orchestrator diagnostic — prompt-schema mismatch causes systematic field errors
- 2026-02-26 [systems-programmer] Implemented: added "Required outcome values" section with exact enum, full schema block with all field names, success+blocked concrete JSON examples, and reinforced raw-JSON-only instruction. Commit cc49fe53, PR #84.
