---
id: TICKET-0248
title: "TASK — Replace non-functional per-agent USD budget caps with per-agent max-turns limits"
type: TASK
status: OPEN
priority: P3
owner: tools-devops-engineer
created_by: producer
created_at: 2026-03-01
updated_at: 2026-03-01
milestone: "Backlog"
phase: "TBD"
depends_on: []
blocks: []
tags: [orchestrator, conductor, budget, tooling, technical-debt]
---

## Summary

The orchestrator's per-agent USD budget cap system is non-functional. Budget values are read from config, threaded through `get_budget()`, stored in worker dicts as `budget_usd`, and logged at dispatch — but they are never enforced. The `claude -p` CLI has no `--budget` flag. The only thing the budget value actually controls is a boolean gate (`if budget > 0`) that sets a hardcoded `--max-turns 200` for all agents identically. This plumbing should be removed and replaced with configurable per-agent turn limits.

## Root Cause

In `orchestrator/conductor.py`, `run_claude()` (line ~547):

```python
if budget > 0:
    cmd.extend(["--max-turns", "200"])
```

The `budget` float is used only as a truthy check. Because all configured budgets are positive, every agent always gets `--max-turns 200`. The per-agent dollar amounts in `config.json` under `budgets` (e.g., `default_worker_usd: 3.00`, `gameplay-programmer: 5.00`) have no effect on actual spend or run length.

The session ceiling check (`session_ceiling_usd` in the main loop) is the only real cost gate and it works correctly — that logic should not change.

## Acceptance Criteria

- [ ] Remove `get_budget()`, `budget_usd` fields, and all `budget` parameters from `conductor.py`.
- [ ] Remove the `budgets` section from `config.json` and `test_config.json` (except `session_ceiling_usd`, which should be renamed to something clearer like `cost_ceiling_usd` and kept under a `limits` section).
- [ ] Add a `max_turns` section to `config.json` with `default_worker`, `producer`, and per-agent overrides (mirroring the existing `models` and `timeouts` structure).
- [ ] Add `get_max_turns(config, agent_slug)` to `conductor.py` and wire it into `run_claude()` in place of the hardcoded `200`.
- [ ] The `--max-turns` value passed to each agent is now agent-configurable, not uniformly 200.
- [ ] All existing orchestrator tests pass; update test fixtures and assertions as needed.
- [ ] No change to the session ceiling halt logic.

## Implementation Notes

**Files to change:**
- `orchestrator/conductor.py` — remove `get_budget()`, replace budget param with max_turns param throughout
- `orchestrator/config.json` — replace `budgets` block with `max_turns` block; keep `cost_ceiling_usd` under a `limits` block
- `orchestrator/test_config.json` — same structural change
- `orchestrator/test_harness.py` and `orchestrator/test_fixtures/` — update any budget assertions

**Suggested `config.json` shape:**

```json
"limits": {
  "cost_ceiling_usd": 20.00
},
"max_turns": {
  "producer": 50,
  "default_worker": 200,
  "overrides": {
    "qa-engineer": 150,
    "technical-artist": 100
  }
}
```

**Suggested conductor helper:**

```python
def get_max_turns(config: dict, agent_slug: str) -> int:
    overrides = config["max_turns"].get("overrides", {})
    return overrides.get(agent_slug, config["max_turns"]["default_worker"])
```

## Activity Log

- 2026-03-01 [producer] Created — deferred item D-033; per-agent USD budget caps identified as non-functional during orchestrator review; session ceiling is unaffected
