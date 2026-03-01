---
id: TICKET-0209
title: "Plan capacity configuration"
type: FEATURE
status: IN_PROGRESS
priority: P2
owner: tools-devops-engineer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "T2"
phase: "Foundation"
depends_on: []
blocks: [TICKET-0210]
tags: [tooling, usage, config, capacity, orchestrator]
---

## Summary

Add a `plan_limits` configuration section to `orchestrator/config.json` that declares the Claude plan tier and its associated rate limits. This configuration is consumed by the reporting script to calculate capacity utilization gauges.

## Acceptance Criteria

### Config Schema
- [ ] Add `plan_limits` section to `orchestrator/config.json`
- [ ] Fields: `plan_tier` (string), `five_hour_output_token_limit` (int), `weekly_output_token_limit` (int)
- [ ] Default values: `"Max 20"`, `220000`, `3080000`

### Documentation
- [ ] Add inline comments or a companion section in the config explaining each field
- [ ] Document the source of default values: Max 20 plan = 220K output tokens per 5-hour window, 3.08M output tokens per week (14x daily)
- [ ] Note that Opus tokens count at 1.7x weighting for capacity calculations

### Validation
- [ ] Conductor startup logs a warning if `plan_limits` section is missing (does not crash — uses defaults)
- [ ] Conductor does not enforce limits — this is informational for reporting only

### Testing
- [ ] Verify `orchestrator/config.json` is valid JSON after changes
- [ ] Verify conductor starts successfully with the new config section
- [ ] Verify conductor starts successfully without the section (graceful default)

## Implementation Notes

- This is configuration-only — no enforcement logic. The reporting script (TICKET-0210) reads these values to compute capacity gauges.
- The 1.7x Opus weighting is a reporting concern, not a config concern. Config stores raw limits; the report script applies weighting.
- Keep the config addition minimal — do not restructure existing config fields.

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created ticket — plan capacity configuration
- 2026-03-01 [tools-devops-engineer] Starting work — adding plan_limits to config.json and conductor startup warning
