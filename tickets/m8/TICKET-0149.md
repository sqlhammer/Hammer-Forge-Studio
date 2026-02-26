---
id: TICKET-0149
title: "Conductor — Godot MCP mutex: gate Godot editor access to one agent at a time"
type: TASK
status: PENDING
priority: P1
owner: tools-devops-engineer
created_by: producer
created_at: 2026-02-26
updated_at: 2026-02-26
milestone: "M8"
phase: "TDD Foundation"
depends_on: []
blocks: []
tags: [orchestrator, conductor, godot-mcp, locking, concurrency, infrastructure]
---

## Summary

The Godot Editor MCP server is a single-process resource: it holds one connection to one running Godot instance. When the conductor dispatches multiple agents in the same wave, any agent that calls a Godot MCP tool (e.g., `execute_editor_script`, `get_scene_tree`) races against every other agent doing the same. The result is interleaved or conflicting editor state — scenes modified mid-read, scripts executed out of order, or MCP calls dropped entirely.

This ticket implements a file-based mutex so that only one agent at a time may hold the Godot MCP lock. Agents that need Godot MCP declare it on their ticket; the conductor serializes them within a wave rather than running them fully in parallel.

## Acceptance Criteria

### Ticket Schema
- [ ] Add optional boolean field `godot_mcp: true` to the ticket frontmatter schema (default `false`). Agents that require Godot MCP set this flag.
- [ ] Update `tools/milestone_status.sh` (or equivalent) to surface the flag in status output when set.

### Lock File Protocol
- [ ] Lock file path: `orchestrator/godot_mcp.lock`
- [ ] Lock file contents when held: `{"holder": "<ticket-id>", "agent": "<agent-slug>", "acquired_at": "<ISO-8601>", "wave": <wave_number>}`
- [ ] Lock file absent or empty means the resource is free.
- [ ] Lock is acquired by the conductor immediately before spawning an agent whose ticket has `godot_mcp: true`.
- [ ] Lock is released by the conductor immediately after the agent process exits (success or failure).
- [ ] If the lock file already exists when the conductor tries to acquire it, the conductor defers the agent to the next wave rather than starting it (no busy-wait, no error — just requeue).
- [ ] Stale lock detection: if `acquired_at` is older than 30 minutes, the conductor logs a WARNING, removes the stale lock, and proceeds with acquisition.
- [ ] `orchestrator/godot_mcp.lock` is listed in `.gitignore` so it is never committed.

### Conductor Integration
- [ ] In `_do_dispatching()`, before spawning each worker, check whether its ticket has `godot_mcp: true`.
- [ ] If `godot_mcp: true` and the lock is free: acquire the lock, spawn the agent, release on exit.
- [ ] If `godot_mcp: true` and the lock is held: skip this agent for the current wave, append it back to `_pending_wave` for retry in the next planning cycle, and log an `INFO` event: `Deferred {ticket_id} — Godot MCP lock held by {holder}`.
- [ ] Agents without `godot_mcp: true` are unaffected and continue to dispatch concurrently as before.
- [ ] Add `release_godot_mcp_lock()` call to the conductor's worker cleanup path so crashes or early exits cannot leave a stale lock indefinitely.

### Documentation
- [ ] Add a `## Godot MCP Concurrency` section to `agents/producer/CLAUDE.md` explaining:
  - Why the lock exists and what it protects.
  - How to mark a ticket as needing Godot MCP (`godot_mcp: true`).
  - What happens when two Godot-MCP tickets land in the same wave (one runs, the other defers to the next wave automatically — no manual intervention needed).

## Implementation Notes

- File-based locking is chosen over an in-process lock because agents run as independent subprocesses; shared memory is not available across them.
- The 30-minute stale threshold is intentional — Godot MCP operations (scene scans, script execution) should complete in seconds. A lock older than 30 minutes indicates the holder crashed without cleanup.
- Do not introduce a busy-wait or sleep loop. The conductor's existing wave-replanning cycle is the retry mechanism — defer once and let the next wave handle it.
- Agents themselves do not acquire or release the lock; the conductor is the sole lock manager. This prevents agents from forgetting to release on error.

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-26 [producer] Created ticket to address Godot MCP single-connection constraint under parallel agent dispatch
