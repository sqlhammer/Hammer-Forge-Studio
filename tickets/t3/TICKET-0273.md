---
id: TICKET-0273
title: "T3 Foundation — Implement GodotInstanceManager class"
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
tags: [tooling, orchestrator, godot-mcp, parallelization]
---

## Summary

Implement the `GodotInstanceManager` class in a new file `orchestrator/godot_instance_manager.py`.
This class manages the lifecycle of per-agent headless Godot processes: slot allocation, launch,
health check, per-worktree `.mcp.json` writing, termination, and orphan recovery on startup.

Reference: `docs/studio/t3-design.md` — Architecture section and `GodotInstanceManager` spec.

---

## Acceptance Criteria

### New File: `orchestrator/godot_instance_manager.py`
- [ ] Class `GodotInstanceManager` implemented with the following public methods:
  - `allocate_slot() -> int | None` — returns first free slot 0..max_instances-1; returns None
    if all slots are occupied
  - `free_slot(slot: int)` — removes the slot entry from the registry and writes state file
  - `launch(slot: int, worktree_path: str, config: dict) -> int` — launches Godot headless,
    returns PID; command:
    ```
    <executable> --headless --editor --path <worktree_path>/game
    ```
    with env vars `GDAI_MCP_SERVER_PORT=base_mcp_port+slot` and
    `GDAI_RUNTIME_SERVER_PORT=base_runtime_port+slot` set on the subprocess
  - `wait_for_ready(mcp_port: int, timeout_seconds: int) -> bool` — polls
    `http://localhost:{mcp_port}/` once per second until a 200 response is received or
    timeout expires; uses `urllib.request` (stdlib only — no httpx or other external deps);
    returns True if ready, False on timeout
  - `write_mcp_config(worktree_path: str, mcp_port: int, runtime_port: int)` — writes
    `.mcp.json` to `{worktree_path}/.mcp.json` with the following structure:
    ```json
    {
      "mcpServers": {
        "godot-mcp": {
          "type": "stdio",
          "command": "uv",
          "args": [
            "run",
            "C:/repos/Hammer-Forge-Studio/game/addons/gdai-mcp-plugin-godot/gdai_mcp_server.py"
          ],
          "env": {
            "GDAI_MCP_SERVER_PORT": "<mcp_port>",
            "GDAI_RUNTIME_SERVER_PORT": "<runtime_port>"
          }
        }
      }
    }
    ```
    Server name `"godot-mcp"` must match exactly (existing tool permission grants use
    `mcp__godot-mcp__*`). MCP server script path always references the main repo.
  - `terminate(slot: int)` — reads PID from registry, kills the process, calls `free_slot`
  - `recover_orphans()` — reads `godot_instances.json`, kills any PIDs still alive
    (cross-platform; handle ProcessNotFoundError gracefully), clears the registry file;
    intended to be called once at conductor startup to prevent port leaks across runs

### State File: `orchestrator/godot_instances.json`
- [ ] Written and read by `GodotInstanceManager` exclusively
- [ ] Format:
  ```json
  {
    "0": {"pid": 12345, "ticket": "TICKET-0150", "mcp_port": 3580, "runtime_port": 3600},
    "1": {"pid": 12346, "ticket": "TICKET-0151", "mcp_port": 3581, "runtime_port": 3601}
  }
  ```
  (keys are slot numbers as strings)
- [ ] File is written after every `allocate_slot`, `free_slot`, and `recover_orphans` call
- [ ] If file does not exist on read, treat as empty registry (no error)

### Stdlib Only
- [ ] No external dependencies — use only Python stdlib (`subprocess`, `urllib.request`,
      `json`, `os`, `pathlib`, `time`, etc.)

### No conductor.py Changes
- [ ] This ticket does not touch `conductor.py` — wiring is scoped to TICKET-0274

---

## Implementation Notes

The `GodotInstanceManager` constructor accepts the `godot` config dict loaded from
`config.json` (added in TICKET-0272). It reads `executable`, `base_mcp_port`,
`base_runtime_port`, `startup_wait_seconds`, and `max_instances` from that dict.

State file path: `orchestrator/godot_instances.json` (relative to the orchestrator directory,
or use an absolute path based on the script's `__file__` location).

For process launch on Windows, use `subprocess.Popen` with `creationflags=subprocess.DETACHED_PROCESS`
to avoid the Godot process being killed when the conductor subprocess tree is interrupted.

`recover_orphans()` should be idempotent — safe to call even if the state file is empty or
missing.

---

## Handoff Notes

(Leave blank until handoff occurs.)

---

## Activity Log

- 2026-03-02 [producer] Created ticket — T3 Foundation: implement GodotInstanceManager class
