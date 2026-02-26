---
id: TICKET-0146
title: "Conductor — multi-instance agent support for parallel ticket assignment"
type: TASK
status: OPEN
priority: P1
owner: tools-devops-engineer
created_by: systems-programmer
created_at: 2026-02-26
updated_at: 2026-02-26
milestone: "M8"
phase: "Orchestrator Infrastructure"
depends_on: [TICKET-0145]
blocks: []
tags: [orchestrator, conductor, concurrency, multi-instance, infrastructure]
---

## Summary

The current producer prompt enforces "at most 1 ticket per agent per wave", which prevents two instances of the same agent slug from running in parallel. This is unnecessarily restrictive: worktree names are already unique per ticket (`orch-{agent_slug}-{ticket}`), so parallel instances can run without collision. The constraint exists as a conservative default, not a technical necessity.

This ticket removes that restriction and allows the producer to assign the same agent slug to multiple tickets in a single wave, each in its own isolated worktree. The Godot MCP exclusivity rule (at most one `needs_godot_mcp: true` worker per wave) is unaffected and must remain.

## Acceptance Criteria

- [ ] **Producer prompt — remove single-agent-per-wave constraint**: In `orchestrator/prompts/plan_wave.md`, remove the rule *"At most 1 ticket per agent per wave (an agent cannot appear twice in the same wave)"*. Replace with: *"The same agent slug may appear multiple times; each assignment runs in its own worktree and branch. The `needs_godot_mcp: true` exclusivity rule still applies — at most 1 Godot MCP worker per wave."*
- [ ] **Config — optional per-agent ticket cap**: In `orchestrator/config.json`, add `"max_tickets_per_agent_per_wave": null` under `"concurrency"`. A null value means unlimited. If set to an integer, the producer should respect it as a ceiling. Document this key in the producer prompt under Concurrency Rules.
- [ ] **Producer prompt — document config cap**: In `orchestrator/prompts/plan_wave.md`, add under Concurrency Rules: *"If `max_tickets_per_agent_per_wave` is set in config (non-null), cap assignments per agent to that value per wave."*
- [ ] **Conductor — verify log file uniqueness**: In `_run_worker()`, confirm that `log_path` includes the ticket ID (not just agent slug) to prevent log collisions when the same agent runs multiple tickets concurrently. Update the log path format to `producer-wave{N}-{agent}-{ticket}-{timestamp}.log` or similar if it doesn't already include ticket ID.
- [ ] **wave_plan.json schema — no uniqueness constraint on agent field**: Confirm (and if needed, remove) any `uniqueItems` or per-agent uniqueness constraint on the `wave` array in `orchestrator/schemas/wave_plan.json`. The schema should permit duplicate agent slugs in the array.
- [ ] **Producer CLAUDE.md — update orchestration concurrency docs**: In `agents/producer/CLAUDE.md` under *Orchestration Mode > Concurrency rules to enforce*, remove the "At most 1 ticket per agent per wave" bullet and replace with the same wording as the prompt update above.

## Implementation Notes

- Worktrees are already named `orch-{agent_slug}-{ticket}`, so parallel instances of the same agent have distinct worktrees by design
- Branch names are `orch/{agent_slug}/{ticket}` — also unique per ticket
- This change is purely additive (removes a restriction); no new conductor state is required
- The tools-devops-engineer should run a manual end-to-end test after this change: trigger a wave with two assignments for the same agent and verify both worktrees are created and workers run independently

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-26 [systems-programmer] Created ticket to enable same-agent parallel execution
