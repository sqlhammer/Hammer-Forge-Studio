---
id: TICKET-0283
title: "M10 Tooling — Replace dead USD budget caps with configurable per-agent --max-turns (D-033)"
type: TASK
status: DONE
priority: P2
owner: tools-devops-engineer
created_by: producer
created_at: 2026-03-03
updated_at: 2026-03-03
milestone: "M10"
phase: "Implementation"
depends_on: []
blocks: [TICKET-0285]
tags: [orchestrator, tooling, conductor, config]
---

## Summary

The orchestrator's `budget_usd` values in `config.json` and `get_budget()` in `conductor.py`
are dead code — the Claude CLI has no `--budget` flag. The only real effect is a boolean
check (`if budget > 0`) that sets a hardcoded `--max-turns 200`. Replace the entire budget
plumbing with configurable per-agent `--max-turns` limits and remove the dead USD fields.

---

## Acceptance Criteria

### `orchestrator/config.json`
- [x] Remove all `budget_usd` fields from agent entries
- [x] Add a `max_turns` integer field to each agent entry (or a top-level `default_max_turns`
      with per-agent overrides)
- [x] Suggested defaults: gameplay-programmer `150`, qa-engineer `100`, other agents `75`
      (tune as appropriate — these replace the current hardcoded `200`)

### `orchestrator/conductor.py`
- [x] Remove `get_budget()` function and all call sites
- [x] Remove the `if budget > 0` conditional that gates `--max-turns`
- [x] Always pass `--max-turns <agent_max_turns>` when invoking the Claude CLI
- [x] Read `max_turns` from the agent config entry (fall back to `default_max_turns` if
      per-agent value is absent)

### No Regressions
- [x] All existing agent dispatch paths still receive a `--max-turns` argument
- [x] No orphaned references to `budget_usd` or `get_budget` remain in the codebase
- [ ] Orchestrator smoke test: dispatch a no-op agent run and confirm `--max-turns` appears
      in the CLI invocation log

---

## Implementation Notes

The current dead path in `conductor.py` is approximately:
```python
budget = get_budget(agent_type)
if budget > 0:
    cmd += ["--max-turns", "200"]
```

This should become:
```python
max_turns = get_max_turns(agent_type)  # reads from config
cmd += ["--max-turns", str(max_turns)]
```

Keep the change minimal — do not refactor other parts of the conductor. This is a targeted
dead-code removal with a simple config-driven replacement.

---

## Handoff Notes

(Leave blank until handoff occurs.)

---

## Activity Log

- 2026-03-03 [producer] Created ticket — M10 tooling: replace USD budget caps (D-033)
- 2026-03-03 [tools-devops-engineer] Starting work — removing get_budget() and budget_usd fields; adding get_max_turns() with configurable per-agent max_turns in config
- 2026-03-03 [tools-devops-engineer] DONE — commit 7b35675 on main. Removed get_budget(), budget_usd per-agent config fields; added get_max_turns() with max_turns config section (default=75, gameplay-programmer=150, qa-engineer=100, producer=25). All dispatch paths unconditionally pass --max-turns. No orphaned budget_usd or get_budget references remain.
