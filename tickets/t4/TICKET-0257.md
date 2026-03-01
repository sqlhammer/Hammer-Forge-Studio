---
id: TICKET-0257
title: "BUG: status.py does not display effective config values (session_ceiling_usd not visible)"
type: BUG
status: OPEN
priority: P2
owner: systems-programmer
created_by: qa-engineer
created_at: 2026-03-01
updated_at: 2026-03-01
milestone: "T4"
phase: "Foundation"
depends_on: ["TICKET-0251"]
blocks: []
tags: [orchestrator, status, config, bug, t4-foundation]
---

## Summary

`status.py` does not display effective configuration values. TICKET-0256 acceptance criterion
requires that `python orchestrator/status.py --instance M8` shows `session_ceiling_usd: 10`
when `config.local.json` contains `{"budgets": {"session_ceiling_usd": 10}}`. The command
produces no config output, making config layering unverifiable via CLI.

TICKET-0251 implementation notes specified importing `load_config` from `instance_paths`, but
the merged implementation only imports `resolve_instance` and does not call or display config.

---

## Reproduction Steps

1. Ensure `orchestrator/instances/M8/state.json` exists (run `start_milestone.py M8 --force`)
2. Create `orchestrator/config.local.json` with content: `{"budgets": {"session_ceiling_usd": 10}}`
3. Run: `python orchestrator/status.py --instance M8`
4. Observe the output

---

## Expected Behavior

The status output should include the effective configuration values, showing:
- `session_ceiling_usd: 10` (from config.local.json override)
- All other config values at their defaults from `config.json`

This makes config layering verifiable without requiring a Python REPL session.

---

## Actual Behavior

`status.py` output shows only state values (status, milestone, phase, wave, cost, workers,
completed waves, retries). No config values are displayed. Sample output:

```
==================================================
  Hammer Forge Studio — Orchestrator Status
==================================================

  Instance:   M8
  Status:     PLANNING
  Milestone:  M8
  Phase:
  Wave:       0
  Started:    2026-03-01T21:14:58
  Total cost: $0.00
```

---

## Evidence

- Confirmed via: `python orchestrator/status.py --instance M8` — no config section in output
- Confirmed config layering itself works: `load_config()` returns `session_ceiling_usd: 10`
  when `config.local.json` is present (verified via direct Python call in TICKET-0256 smoke test)
- `status.py` source confirms: only `resolve_instance` is imported; `load_config` is never called

---

## Impact

P2 — Defect in expected behavior; workaround exists. The config layering mechanism works
correctly at the library level. Users can verify the effective config by importing
`instance_paths.load_config()` directly in Python, but there is no CLI-level visibility.

---

## Suggested Fix

In `status.py`, import `load_config` from `instance_paths` and add a config section to
`_print_full_status()` that displays the effective merged config (or at least the `budgets`
section) when not in `--json` mode.

---

## Activity Log

- 2026-03-01 [qa-engineer] Created — filed during TICKET-0256 integration smoke test; config
  layering display criterion failed against status.py output
