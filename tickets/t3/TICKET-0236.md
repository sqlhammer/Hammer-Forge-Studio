---
id: TICKET-0236
title: "T3 kickoff — plan parallel Godot MCP instances milestone"
type: TASK
status: OPEN
priority: P1
owner: producer
created_by: studio-head
created_at: 2026-02-28
updated_at: 2026-02-28
milestone: "T3"
phase: "Kickoff"
depends_on: []
blocks: []
tags: [tooling, orchestrator, godot-mcp, parallelization, kickoff]
---

## Summary

Plan and ticket the T3 milestone: per-agent headless Godot MCP instances. The Studio Head has
designed and approved the architecture. The Producer's job is to read the design doc, break the
work into concrete implementation tickets across appropriate phases, add those tickets to
`tickets/t3/`, and update the T3 milestone entry in `docs/studio/milestones.md` with the phase
structure.

**Design doc:** `docs/studio/t3-design.md`

---

## Context

The current conductor serializes all Godot-MCP work through a file-based lock
(`orchestrator/godot_mcp.lock`): only one agent per wave can use Godot MCP tools, and the user
must manually keep the Godot Editor open. T3 replaces this with per-agent headless Godot
instances — each Godot-MCP agent gets its own Godot process on a unique port, no manual setup
required, multiple agents can run in parallel.

---

## Acceptance Criteria

### Ticket Creation
- [ ] Read `docs/studio/t3-design.md` fully before creating tickets
- [ ] Create all implementation tickets in `tickets/t3/` using sequential IDs (TICKET-0237+)
- [ ] Each ticket has clear owner, type, phase, and acceptance criteria
- [ ] Dependency chain is correct — config changes before code changes, GodotInstanceManager
      before conductor wiring, conductor changes before verification
- [ ] A QA/verification ticket exists as the final phase

### Milestone Document
- [ ] `docs/studio/milestones.md` T3 row updated: phase names, ticket count
- [ ] T3 notes section in milestones.md updated with ticket table and dependency graph

### Phase Structure (suggested — Producer may adjust)
- **Foundation:** Config schema update, `GodotInstanceManager` class, `.gitignore` entry
- **Integration:** Wire `GodotInstanceManager` into `_do_dispatching` and `_do_working`,
  remove old lock system, write per-worktree `.mcp.json`
- **QA:** End-to-end verification, test with real Godot instances, confirm no regressions

### No Implementation
- [ ] This ticket is planning only — the Producer does NOT implement any code changes
- [ ] Implementation happens via the tickets created by this planning work

---

## Implementation Notes

The design doc at `docs/studio/t3-design.md` contains the full architecture including:
- Exact `config.json` additions (`godot` section with executable, ports, max_instances)
- `GodotInstanceManager` class API (methods, state file format, port allocation logic)
- Changes to `_do_dispatching` and `_do_working` in `conductor.py`
- Per-worktree `.mcp.json` format (server name `"godot-mcp"`, env vars, MCP server path)
- Godot startup command (`--headless --editor --path {worktree_path}/game`)
- Health check approach (poll HTTP until ready, 15s timeout)
- What to remove: `acquire_godot_mcp_lock`, `release_godot_mcp_lock`, `read_godot_mcp_lock`
- Verification plan

Key file paths to reference in tickets:
- `orchestrator/conductor.py` — main changes file
- `orchestrator/config.json` — add `godot` section
- `orchestrator/godot_instances.json` — new state file (already added to `.gitignore`)
- `game/addons/gdai-mcp-plugin-godot/gdai_mcp_server.py` — MCP server (no changes, reference)
- Godot executable: `C:/Users/derik/OneDrive/Desktop/Godot_v4.5.1-stable_win64_console.exe`

Agents available for implementation:
- `tools-devops-engineer` — primary implementer (conductor, config, GodotInstanceManager)
- `qa-engineer` — verification ticket

---

## Handoff Notes

(Leave blank until handoff occurs.)

---

## Activity Log

- 2026-02-28 [studio-head] Created ticket — T3 kickoff: plan parallel Godot MCP instances milestone
