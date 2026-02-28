# T3 Design: Per-Agent Headless Godot MCP Instances

> **Status:** Approved design — Studio Head approved 2026-02-28
> **Authored by:** Studio Head (Claude Code session)
> **Purpose:** Implementation reference for T3 milestone planning

---

## Context

The current workflow serializes all Godot-MCP work through a single file-based lock
(`orchestrator/godot_mcp.lock`). Only one agent per wave can use Godot MCP tools, and the user
must keep the Godot Editor open manually before running the conductor. This single-threads what
could be parallel work and requires manual setup every session.

**Goal:** Each agent that needs Godot MCP spawns its own headless Godot editor process from
its worktree's game directory, on a dynamically allocated port pair. No manual Godot setup.
Multiple agents can work in parallel with full Godot MCP access.

---

## Architecture

```
Conductor
  ├─ allocates port slot (base 3580+) for each needs_godot agent
  ├─ launches headless Godot from worktree/game/ on that port
  ├─ waits for Godot HTTP ready (polls http://localhost:{mcp_port}/)
  ├─ writes per-worktree .mcp.json pointing to those ports
  └─ spawns claude -p (which reads .mcp.json from its cwd)

After agent finishes:
  ├─ kills Godot process
  └─ frees port slot (worktree removal also removes .mcp.json)
```

---

## Files to Modify

### 1. `orchestrator/config.json`

Add a `godot` section:

```json
"godot": {
  "executable": "C:/Users/derik/OneDrive/Desktop/Godot_v4.5.1-stable_win64_console.exe",
  "base_mcp_port": 3580,
  "base_runtime_port": 3600,
  "startup_wait_seconds": 15,
  "max_instances": 4
}
```

- `base_mcp_port`: Port for `GDAI_MCP_SERVER_PORT`. Slot N uses `base_mcp_port + N`.
- `base_runtime_port`: Port for `GDAI_RUNTIME_SERVER_PORT`. Slot N uses `base_runtime_port + N`.
- `max_instances`: Cap on concurrent Godot processes. If all slots busy, extra agents defer to next wave.
- Console executable avoids any GUI window.

---

### 2. `orchestrator/conductor.py`

#### Remove (Godot lock system — replaced entirely)
- `GODOT_MCP_LOCK_PATH` constant
- `acquire_godot_mcp_lock()`
- `release_godot_mcp_lock()`
- `read_godot_mcp_lock()`
- All lock logic in `_do_dispatching` (the `godot_lock_acquired_for` variable and the `if needs_godot:` guard)

#### Add: `GodotInstanceManager` class

**State file:** `orchestrator/godot_instances.json` (gitignored) — persists across crashes:
```json
{
  "0": {"pid": 12345, "ticket": "TICKET-0150", "mcp_port": 3580, "runtime_port": 3600},
  "1": {"pid": 12346, "ticket": "TICKET-0151", "mcp_port": 3581, "runtime_port": 3601}
}
```

**Methods:**
- `allocate_slot() -> int | None` — returns first free slot 0..max_instances-1, or None if all full
- `free_slot(slot)` — removes slot from registry, writes state file
- `launch(slot, worktree_path, config) -> int` — runs Godot headless:
  ```
  Godot_console.exe --headless --editor --path {worktree_path}/game
  ```
  with env vars `GDAI_MCP_SERVER_PORT` and `GDAI_RUNTIME_SERVER_PORT` set per slot.
  Returns PID of Godot process.
- `wait_for_ready(mcp_port, timeout_seconds) -> bool` — polls `http://localhost:{mcp_port}/`
  until 200 response or timeout. Uses `httpx` (already in MCP server deps).
- `terminate(slot)` — reads PID from registry, kills process, frees slot.
- `write_mcp_config(worktree_path, mcp_port, runtime_port)` — writes `.mcp.json` to
  `{worktree_path}/.mcp.json`.
- `recover_orphans()` — called on conductor startup: reads `godot_instances.json`,
  kills any PIDs still alive, clears registry. Prevents port leaks across runs.

#### Modify: `_do_dispatching`

Replace lock logic with slot allocation. Deferral behavior (to next wave) is preserved:
```python
if needs_godot:
    slot = godot_mgr.allocate_slot()
    if slot is None:
        # All slots busy — defer to next planning wave (same as old lock behavior)
        deferred.append(assignment)
        continue
    mcp_port = base_mcp_port + slot
    runtime_port = base_runtime_port + slot
    pid = godot_mgr.launch(slot, worktree_path, godot_config)
    ready = await godot_mgr.wait_for_ready(mcp_port, startup_wait_seconds)
    if not ready:
        godot_mgr.terminate(slot)
        self._queue_retry(ticket_id)
        continue
    godot_mgr.write_mcp_config(worktree_path, mcp_port, runtime_port)
    worker["godot_slot"] = slot
```

#### Modify: `_do_working` results loop

After each worker task completes (success or failure), terminate its Godot instance:
```python
if worker.get("godot_slot") is not None:
    godot_mgr.terminate(worker["godot_slot"])
```

---

### 3. Per-worktree `.mcp.json`

Written to `{worktree_path}/.mcp.json` by `write_mcp_config()`:

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
        "GDAI_MCP_SERVER_PORT": "3580",
        "GDAI_RUNTIME_SERVER_PORT": "3600"
      }
    }
  }
}
```

Notes:
- Server name `"godot-mcp"` matches existing tool permission grants (`mcp__godot-mcp__*`).
- MCP server script path always references the main repo (shared across all worktrees — no per-worktree copy needed).
- Ports are unique per slot; the exact values substituted at write time.

---

### 4. `.gitignore`

Add `orchestrator/godot_instances.json` to `.gitignore`.

(Per-worktree `.mcp.json` files are safe — worktrees live inside `.claude/worktrees/` which is
already gitignored.)

---

## Godot Startup Command

```
"C:/Users/derik/OneDrive/Desktop/Godot_v4.5.1-stable_win64_console.exe"
  --headless
  --editor
  --path "{worktree_path}/game"
```

- `--headless`: no display server, no window
- `--editor`: runs in editor mode so EditorPlugins (including GDAI) are loaded and the HTTP server starts
- `--path`: path to the Godot project directory containing `project.godot`

Godot is launched as a detached subprocess (not awaited) so the conductor can continue setup
while Godot starts. The health check confirms readiness.

---

## Health Check

Poll `http://localhost:{mcp_port}/` with short timeout (1s per attempt) up to
`startup_wait_seconds` (15s). GDAI's HTTP server returns a valid response once Godot and the
plugin are ready. If no response within timeout, abort and queue a retry.

---

## Concurrency Impact

| Before | After |
|--------|-------|
| 1 Godot-MCP agent per wave | Up to 4 concurrent (configurable via `max_instances`) |
| Manual Godot setup required | Fully automated — no user action needed |
| File lock serializes all Godot work | Slot pool limits gracefully with deferral |
| Lock expires after 30m (stale detection) | Process lifecycle managed directly via PID |

Agents without `needs_godot_mcp: true` are unaffected — no `.mcp.json` written, no Godot launched.

---

## Verification Plan

1. Create test wave with 3 `needs_godot_mcp: true` tickets
2. Run conductor — verify 3 separate Godot processes appear (headless, no window)
3. Check logs: each agent should log different `GDAI_MCP_SERVER_PORT` values
4. Check `orchestrator/godot_instances.json` — 3 slot entries during run
5. After wave completes — all Godot processes terminated, file empty or missing
6. Confirm no stale processes: `tasklist | findstr Godot`
