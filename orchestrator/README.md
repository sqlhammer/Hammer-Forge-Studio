# Orchestrator — Hammer Forge Studio

Automated agent orchestration system. A Python Conductor script runs the main loop, the Producer agent (via `claude -p`) makes all scheduling decisions as structured JSON, and worker agents execute tickets autonomously in parallel.

## Quick Start

**Starting a new milestone (always do this first):**

```bash
cd /c/repos/Hammer-Forge-Studio
python orchestrator/start_milestone.py M11
python orchestrator/conductor.py M11
```

`start_milestone.py` writes a fresh `state.json` for the new milestone instance. Without it, the conductor resumes the previous instance's saved state.

**Resuming an in-progress milestone after a crash:**

```bash
python orchestrator/conductor.py M11   # state.json already exists — resumes automatically
```

## How It Works

1. **Conductor** (Python) asks the **Producer** (Claude) to plan the next wave of work
2. Producer reads tickets and outputs a JSON wave plan
3. Conductor spawns **worker agents** (Claude) in parallel, each in its own git worktree
4. Workers execute their assigned tickets autonomously
5. Workers push branches and self-merge via GitHub PR
6. When a phase is complete, the system emits a gate and blocks until a `gate_response.json` is written

## Commands

### Start a New Milestone

```bash
python orchestrator/start_milestone.py <milestone>
python orchestrator/start_milestone.py <milestone> "<phase>"      # specify starting phase
python orchestrator/start_milestone.py <milestone> --force        # skip confirmation
python orchestrator/start_milestone.py <milestone> --instance X   # custom instance name

# Then run the conductor:
python orchestrator/conductor.py <milestone>
```

`start_milestone.py` must be run before the conductor whenever beginning a new milestone. If a previous instance's `state.json` exists, the conductor resumes that state.

### Resume or Continue Orchestration

```bash
python orchestrator/conductor.py <milestone>
python orchestrator/conductor.py <milestone> --instance X   # target a named instance
```

Re-running the same command resumes from saved state automatically — no special flag needed.

### Check Status

```bash
python orchestrator/status.py                  # auto-detect instance
python orchestrator/status.py --instance M11   # target a specific instance
python orchestrator/status.py --all            # one-line summary of all instances
python orchestrator/status.py --json           # raw JSON state
python orchestrator/status.py --log 20         # include last 20 log entries
```

### Approve a Phase Gate

When a phase completes, the conductor transitions to `GATE_BLOCKED` and writes `pending_gate.json` inside the instance directory. Use `approve_gate.py` to approve the gate:

```bash
python orchestrator/approve_gate.py                  # auto-detect instance, confirm first
python orchestrator/approve_gate.py --force          # no prompt
python orchestrator/approve_gate.py --instance M11  # target a specific instance
```

The script reads `pending_gate.json`, displays the current milestone, phase, next phase, and gate timestamp, then prompts for confirmation before writing `gate_response.json`. The conductor polls for this file every 30 seconds. Once found, it reads `next_phase`, cleans up both gate files, and advances to `PLANNING`.

### Resume Planning After New Tickets Are Added

If the conductor has gone `IDLE` (all known tickets were DONE) and new tickets are then created:

```bash
python orchestrator/resume_planning.py                    # auto-detect instance, confirm first
python orchestrator/resume_planning.py --force            # no prompt
python orchestrator/resume_planning.py --instance M11     # target a specific instance
```

Then re-run the conductor as normal. The script is a no-op if the conductor is not currently `IDLE`.

### View Logs

```bash
# Instance activity log (all events)
tail -50 orchestrator/instances/M11/activity.log

# Specific agent's execution log
cat orchestrator/instances/M11/logs/gameplay-programmer-TICKET-0092-*.log
```

### Stop Gracefully

Press `Ctrl+C` in the conductor terminal. It catches the signal, waits for active workers to finish, saves state, and exits. Re-run the same command to continue later.

## Configuration

Edit `orchestrator/config.json` to adjust:

- **Models**: Which Claude model each agent uses (sonnet, opus, haiku)
- **Budgets**: Per-worker and session-level cost limits
- **Timeouts**: Per-agent time limits (minutes)
- **Concurrency**: Max parallel workers, Godot MCP exclusivity
- **Retries**: Max retry attempts per failed ticket
- **Tool tiers**: Which Godot MCP tools each agent tier can access

Create `orchestrator/config.local.json` for local overrides — it deep-merges on top of `config.json` and is gitignored.

## File Structure

```
orchestrator/
├── conductor.py          # Main loop (entry point)
├── start_milestone.py    # CLI: initialize fresh state for a new milestone
├── resume_planning.py    # CLI: reset IDLE → PLANNING when new tickets added
├── status.py             # CLI: show current state
├── instance_paths.py     # Shared path resolution for multi-instance support
├── config.json           # Configuration (shared across instances)
├── config.local.json     # Local config overrides (gitignored)
├── prompts/
│   ├── plan_wave.md      # Producer planning prompt template
│   └── worker_dispatch.md # Worker execution prompt template
├── schemas/
│   ├── wave_plan.json    # JSON schema for Producer output
│   └── worker_result.json # JSON schema for worker output
├── checkpoints/          # Agent checkpoint files for crash recovery (gitignored)
├── instances/<name>/     # Per-instance runtime directories (e.g. instances/M11/)
│   ├── state.json        # Runtime state (auto-created, gitignored)
│   ├── activity.log      # Audit trail (auto-created, gitignored)
│   ├── pending_gate.json # Gate notification (auto-created, gitignored)
│   ├── gate_response.json # Gate approval (user-created, gitignored)
│   ├── results/          # Per-ticket result files (gitignored)
│   └── logs/             # Per-agent execution logs (gitignored)
├── test_harness.py       # Test harness for dry-run orchestration
├── test_usage_limit.py   # Usage limit simulation tests
├── usage.jsonl           # API usage tracking (gitignored)
└── README.md             # This file
```

## State Machine

```
PLANNING → DISPATCHING → WORKING → EVALUATING → PLANNING (main loop)
                                               → GATE_BLOCKED (phase done)
                                               → LIMIT_WAIT (API rate limit)
                                               → HALTED (error)
GATE_BLOCKED → PLANNING (gate_response.json written)
LIMIT_WAIT   → WORKING (cooldown elapsed, retries remaining)
             → HALTED (max cooldown cycles exhausted)
HALTED       → PLANNING (re-run conductor after resolving issue)
IDLE         → PLANNING (resume_planning.py when new tickets added)
```

## Failure Recovery

| Failure | Recovery |
|---------|----------|
| Worker crash | Retry up to 3x, then HALT |
| Worker timeout | Kill and retry |
| API rate limit | LIMIT_WAIT with cooldown, then retry |
| Budget exceeded | Worker exits cleanly, logged |
| Session budget hit | HALT with warning |
| Merge conflict | HALT, manual resolution required |
| Producer bad JSON | Retry up to 3x, then HALT |
| Conductor crash | Re-run same command — reads state.json |

## Human Gates

Gates **never** auto-approve. The conductor blocks in `GATE_BLOCKED` and polls every 30 seconds for `gate_response.json`. On Windows, a toast notification is fired when a gate is reached. Write the response file to the instance directory to unblock.
