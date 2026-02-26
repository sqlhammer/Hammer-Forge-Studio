---
id: TICKET-0148
title: "Conductor + Producer — autonomous ticket creation during orchestration"
type: TASK
status: DONE
priority: P1
owner: tools-devops-engineer
created_by: systems-programmer
created_at: 2026-02-26
updated_at: 2026-02-26
milestone: "M7"
phase: "QA"
depends_on: [TICKET-0145]
blocks: []
tags: [orchestrator, conductor, producer, ticket-creation, automation, infrastructure]
---

## Summary

The producer currently has no way to create new tickets during orchestration. If it identifies a needed REVIEW ticket after a worker completes, or a BUGFIX for a defect found mid-wave, it must either ignore the gap or exit orchestration and ask the Studio Head. This blocks the producer from operating autonomously in cases that are clearly within its authority (operational follow-up, not scope changes).

This ticket extends the wave plan schema with an optional `new_tickets` array and implements the conductor-side write logic. The producer's CLAUDE.md is also updated to define when it may and may not create tickets autonomously.

Human-in-the-loop gates (phase gate approval, milestone close sign-off) are unaffected and remain fully enforced.

## Acceptance Criteria

### Schema
- [ ] **`orchestrator/schemas/wave_plan.json`** — add optional `new_tickets` array to the schema. Permitted with `action: "spawn_agents"` only. Each entry in the array must have:
  - `id` (string, required) — full ticket ID, e.g. `"TICKET-0155"`
  - `title` (string, required)
  - `type` (string, required) — one of `TASK`, `BUGFIX`, `REVIEW`, `BLOCKER`, `SPIKE`
  - `owner` (string, required) — agent slug
  - `phase` (string, required) — milestone phase name
  - `priority` (string, required) — `P0`, `P1`, or `P2`
  - `depends_on` (array of strings, optional, default `[]`)
  - `summary` (string, required) — one-sentence description
  - `acceptance_criteria` (array of strings, required) — each entry is one criterion line
- [ ] **Schema `additionalProperties: false`** must still validate cleanly after adding `new_tickets`

### Conductor
- [ ] **`write_ticket_file(ticket_data, milestone)` utility**: Add a function that takes a `new_tickets` entry dict and the current milestone, and writes a valid ticket file to `tickets/{milestone}/{ticket_data["id"]}.md`. Uses a template matching the existing ticket frontmatter format (see existing `tickets/m8/` files as canonical format). Includes the standard `## Summary`, `## Acceptance Criteria`, `## Handoff Notes`, and `## Activity Log` sections. Activity Log entry: `YYYY-MM-DD [conductor] Created via orchestration wave {wave_number}`.
- [ ] **Duplicate guard**: Before writing, check if the target file already exists. If it does, log `WARNING: {id} already exists — skipping ticket creation` and do not overwrite.
- [ ] **Next-ID validation**: Before writing, verify the `id` field from the producer doesn't collide with any existing ticket in `tickets/**/TICKET-*.md`. Log a WARNING and skip if collision detected.
- [ ] **Ticket creation in `_do_dispatching()`**: After popping `_pending_wave` and before creating workers, check for `_pending_new_tickets` in state. For each entry, call `write_ticket_file()`. Log a `TICKET` event in activity.log: `Created {id}: {title}`.
- [ ] **Store new_tickets in state**: In `_do_planning()`, when action is `spawn_agents` and the plan includes a `new_tickets` array, store it in `state["_pending_new_tickets"]` (in addition to storing `_pending_wave`).

### Producer Prompt
- [ ] **`orchestrator/prompts/plan_wave.md`** — add a `## Autonomous Ticket Creation` section documenting:
  - The `new_tickets` array is optional and may be included with `action: "spawn_agents"`
  - Producer MUST determine the next ticket ID by noting the highest ID in completed_waves and retries context (the conductor will validate — do not guess)
  - Types permitted: `REVIEW`, `BUGFIX`, `TASK`, `BLOCKER`, `SPIKE`
  - Valid use cases: post-completion code review setup, defects discovered during wave work, follow-up tasks identified by workers, blocking issues that need routing
  - Prohibited use cases: scope additions, new feature work, phase gate modifications, anything that would require Studio Head approval per CLAUDE.md

### Producer CLAUDE.md
- [ ] **`agents/producer/CLAUDE.md`** — add a `### Autonomous Ticket Creation` subsection under *Orchestration Mode*, documenting:
  - Producer MAY create tickets autonomously (via `new_tickets`): `REVIEW` (code review after implementation commit), `BUGFIX` (defect found during a wave), `TASK` (operational gap identified), `BLOCKER` (routing a blocking issue)
  - Producer MUST escalate to Studio Head (not create autonomously): new features or scope additions, changes to phase gate structure, milestone target changes, anything requiring sign-off per the Studio Head Touchpoints section
  - All human-in-the-loop gates remain active: phase gate approval requires Studio Head via `approve_gate.py`; milestone close requires Studio Head QA sign-off
  - New tickets created via orchestration land in `tickets/{current_milestone}/` and are picked up in subsequent waves like any other ticket

## Implementation Notes

- The `write_ticket_file()` utility should produce ticket files that are byte-for-byte compatible with manually-created tickets (same frontmatter order, same section headers)
- Ticket ID assignment is the producer's responsibility — the conductor only validates for collisions, it does not auto-increment. The producer must read the filesystem context provided in the planning prompt to determine the next available ID
- `new_tickets` entries created in wave N are available for the producer to assign in wave N+1 (they won't be in the same wave that creates them)
- This ticket does not add a new `action` value — ticket creation is bundled with `spawn_agents` to keep the common case of "create a review ticket and dispatch the next wave" atomic

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-26 [systems-programmer] Created ticket to enable producer autonomous ticket creation during orchestration
- 2026-02-26 [tools-devops-engineer] Starting work
- 2026-02-26 [tools-devops-engineer] DONE — commit 31dac1a, PR https://github.com/sqlhammer/Hammer-Forge-Studio/pull/113
