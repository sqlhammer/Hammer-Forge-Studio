---
id: TICKET-0272
title: "T3 Foundation — Add godot config section to config.json and .gitignore entry"
type: TASK
status: OPEN
priority: P1
owner: tools-devops-engineer
created_by: producer
created_at: 2026-03-02
updated_at: 2026-03-02
milestone: "T3"
phase: "Foundation"
depends_on: []
blocks: [TICKET-0274]
tags: [tooling, orchestrator, godot-mcp, config]
---

## Summary

Add the `godot` configuration section to `orchestrator/config.json` and add
`orchestrator/godot_instances.json` to `.gitignore`. Also remove the now-obsolete
`godot_mcp_exclusive` concurrency flag, which will be superseded by the slot-based
`GodotInstanceManager` introduced in TICKET-0273.

---

## Acceptance Criteria

### `orchestrator/config.json`
- [ ] Add a top-level `godot` section with the following fields:
  ```json
  "godot": {
    "executable": "C:/Users/derik/OneDrive/Desktop/Godot_v4.5.1-stable_win64_console.exe",
    "base_mcp_port": 3580,
    "base_runtime_port": 3600,
    "startup_wait_seconds": 15,
    "max_instances": 4
  }
  ```
- [ ] Remove `"godot_mcp_exclusive": true` from the `concurrency` section — this flag is
      replaced by the `max_instances` cap in `GodotInstanceManager`

### `.gitignore`
- [ ] Add `orchestrator/godot_instances.json` — this is a runtime PID/port registry
      written by `GodotInstanceManager`; must never be committed

### No Other Changes
- [ ] Do not modify `conductor.py` — that is scoped to TICKET-0274
- [ ] Do not implement `GodotInstanceManager` — that is scoped to TICKET-0273

---

## Implementation Notes

`orchestrator/godot_instances.json` is written at runtime to track which Godot processes
are alive and which port slots they occupy. It persists across conductor crashes to allow
orphan recovery. It should be gitignored alongside other runtime state files.

The Godot executable path matches the console variant (no GUI window). Slot N uses port
`base_mcp_port + N` for MCP and `base_runtime_port + N` for runtime.

---

## Handoff Notes

(Leave blank until handoff occurs.)

---

## Activity Log

- 2026-03-02 [producer] Created ticket — T3 Foundation: config.json + .gitignore prep
