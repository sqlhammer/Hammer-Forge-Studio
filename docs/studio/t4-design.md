# T4 Design — Multi-Milestone Orchestrator

**Status:** Active
**Owner:** systems-programmer (implementation), qa-engineer (verification)
**Tickets:** TICKET-0249–TICKET-0256

---

## Problem

The orchestrator assumes a single active milestone at a time. All runtime state lives under
`orchestrator/` as flat files (`state.json`, `activity.log`, `results/`, `logs/`, lock files).
Two `conductor.py` processes running simultaneously would collide on every one of these files.

Additionally, `config.json` is source-controlled but has no override mechanism — users who want
different settings (e.g., lower budgets, different models) must edit the tracked file and risk
clobbering overrides on future pulls.

---

## Solution

### 1. Instance Directory Model

All runtime-mutable files for one orchestrator run are isolated under:

```
orchestrator/instances/<instance-name>/
```

Instance name defaults to the milestone ID (e.g., `M8`, `T3`) but can be overridden with
`--instance <name>`.

**Before (flat under orchestrator/):**
```
orchestrator/
├── config.json        ← source-controlled
├── state.json         ← runtime, gitignored
├── activity.log       ← runtime, gitignored
├── godot_mcp.lock     ← runtime, gitignored
├── pending_gate.json  ← runtime, gitignored
├── gate_response.json ← runtime, gitignored
├── results/           ← runtime, gitignored
├── logs/              ← runtime, gitignored
├── prompts/           ← source-controlled
└── schemas/           ← source-controlled
```

**After:**
```
orchestrator/
├── config.json            ← source-controlled (defaults only)
├── config.local.json      ← gitignored (global local overrides)
├── prompts/               ← source-controlled (shared)
├── schemas/               ← source-controlled (shared)
├── instance_paths.py      ← NEW shared utility module
└── instances/             ← gitignored (all runtime state)
    ├── M8/
    │   ├── state.json
    │   ├── activity.log
    │   ├── godot_mcp.lock
    │   ├── pending_gate.json
    │   ├── gate_response.json
    │   ├── results/
    │   └── logs/
    └── T3/
        ├── state.json
        ├── activity.log
        └── ...
```

Two `conductor.py` processes — one for M8, one for T3 — touch completely separate directories.
No file-level coordination needed.

### 2. Config Layering

Two-layer deep merge:

1. `orchestrator/config.json` — always loaded, source-controlled defaults
2. `orchestrator/config.local.json` — gitignored, global local overrides (absent = skip)

Merge is "last writer wins" on individual leaf values. A `config.local.json` containing only
`{"budgets": {"session_ceiling_usd": 50}}` overrides just that field and inherits everything
else from defaults.

### 3. Shared Module: `orchestrator/instance_paths.py`

Centralizes all path and config resolution. Each script imports one function instead of
redeclaring paths inline.

```python
@dataclass
class InstancePaths:
    orch_dir: Path
    instance_dir: Path
    config_path: Path          # orch_dir/config.json (defaults)
    config_local_path: Path    # orch_dir/config.local.json
    state_path: Path
    activity_log: Path
    pending_gate_path: Path
    gate_response_path: Path
    godot_mcp_lock_path: Path
    results_dir: Path
    logs_dir: Path
    prompts_dir: Path          # shared, under orch_dir
    schemas_dir: Path          # shared, under orch_dir

def resolve_instance(instance_name: str, orch_dir: Path | None = None) -> InstancePaths:
    """Build InstancePaths for the given instance name. Creates instance dir if absent."""

def load_config(paths: InstancePaths) -> dict:
    """Load config.json, deep-merge config.local.json on top. Return merged dict."""
```

---

## Files Changed

| File | Change |
|------|--------|
| `orchestrator/instance_paths.py` | **CREATE** — shared path + config utility |
| `orchestrator/conductor.py` | Replace flat path constants with `resolve_instance()`; load config via `load_config()`; add `--instance` flag |
| `orchestrator/status.py` | Add `--instance` flag; `--all` lists all instances; use `resolve_instance()` |
| `orchestrator/start_milestone.py` | Add `--instance` flag; create instance dir; use `resolve_instance()` |
| `orchestrator/approve_gate.py` | Add `--instance` flag; use `resolve_instance()` |
| `orchestrator/resume_planning.py` | Add `--instance` flag; use `resolve_instance()` |
| `.gitignore` | Add `orchestrator/instances/` and `orchestrator/config.local.json`; remove stale flat entries |

---

## Instance Name Conventions

- Milestone orchestrators: `M8`, `M9`, `M10`
- Track orchestrators: `T3`, `T4`
- Custom: any alphanumeric + hyphen string passed via `--instance`
- Default: equals the `<milestone>` positional argument

---

## Verification

1. **Isolated state:** Start `conductor.py M8` and `conductor.py T3` simultaneously; confirm each writes only to its own instance directory.
2. **Config override:** Create `config.local.json` with `{"budgets": {"session_ceiling_usd": 10}}`; confirm the overridden ceiling is visible, all other values come from defaults.
3. **`status --all`:** With two populated instance dirs, confirm `python orchestrator/status.py --all` shows a summary line per instance.
4. **Gate approval:** Run `approve_gate.py --instance M8`; confirm it reads from `instances/M8/`.
5. **Backward compat:** Old `orchestrator/state.json` (if present) is ignored; run `start_milestone.py` to bootstrap a new instance directory.

---

## Phase Structure

Single phase: **Foundation** — all tickets are self-contained infrastructure changes.

Ticket 8 (QA) is the phase gate; all implementation tickets (1–7) must be DONE before it runs.
