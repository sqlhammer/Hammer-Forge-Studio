# Orchestrator — Hammer Forge Studio

Automated agent orchestration system. A Python Conductor script runs the main loop, the Producer agent (via `claude -p`) makes all scheduling decisions as structured JSON, and worker agents execute tickets autonomously in parallel.

## Quick Start

```bash
cd /c/repos/Hammer-Forge-Studio
python orchestrator/conductor.py M6 Foundation
```

This starts the orchestration loop for milestone M6, beginning at the Foundation phase.

## How It Works

1. **Conductor** (Python) asks the **Producer** (Claude) to plan the next wave of work
2. Producer reads tickets and outputs a JSON wave plan
3. Conductor spawns **worker agents** (Claude) in parallel, each in its own git worktree
4. Workers execute their assigned tickets autonomously
5. Conductor merges branches into `main` and loops back to step 1
6. When a phase is complete, the system halts for **Studio Head approval** (human gate)

## Commands

### Start Orchestration

```bash
python orchestrator/conductor.py <milestone> <phase>
# Example: python orchestrator/conductor.py M6 Foundation
```

### Resume After Crash

```bash
python orchestrator/conductor.py --resume
```

### Check Status

```bash
python orchestrator/status.py
python orchestrator/status.py --json       # raw JSON
python orchestrator/status.py --log 20     # include last 20 log entries
```

### Approve a Phase Gate

When a phase completes, the system halts and prints a notification. To continue:

```bash
python orchestrator/approve_gate.py                    # approve (default)
python orchestrator/approve_gate.py --reject           # reject
python orchestrator/approve_gate.py --comment "LGTM"   # approve with note
```

### View Logs

```bash
# Activity log (all events)
tail -50 orchestrator/activity.log

# Specific agent's execution log
cat orchestrator/logs/gameplay-programmer-TICKET-0092-*.log
```

### Stop Gracefully

Press `Ctrl+C` in the conductor terminal. It catches the signal, waits for active workers to finish, saves state, and exits. Use `--resume` to continue later.

## Configuration

Edit `orchestrator/config.json` to adjust:

- **Models**: Which Claude model each agent uses (sonnet, opus, haiku)
- **Budgets**: Per-worker and session-level cost limits
- **Timeouts**: Per-agent time limits (minutes)
- **Concurrency**: Max parallel workers, Godot MCP exclusivity
- **Retries**: Max retry attempts per failed ticket
- **Tool tiers**: Which Godot MCP tools each agent tier can access

## File Structure

```
orchestrator/
├── conductor.py          # Main loop (entry point)
├── approve_gate.py       # CLI: approve/reject a gate
├── status.py             # CLI: show current state
├── config.json           # Configuration
├── state.json            # Runtime state (auto-created, gitignored)
├── activity.log          # Audit trail (auto-created, gitignored)
├── pending_gate.json     # Gate notification (auto-created, gitignored)
├── gate_response.json    # Gate response (auto-created, gitignored)
├── prompts/
│   ├── plan_wave.md      # Producer planning prompt template
│   └── worker_dispatch.md # Worker execution prompt template
├── schemas/
│   ├── wave_plan.json    # JSON schema for Producer output
│   └── worker_result.json # JSON schema for worker output
├── results/              # Per-ticket result files (gitignored)
├── logs/                 # Per-agent execution logs (gitignored)
└── README.md             # This file
```

## State Machine

```
IDLE -> PLANNING -> DISPATCHING -> WORKING -> EVALUATING -> PLANNING (loop)
                                                         -> GATE_BLOCKED (phase done)
                                                         -> HALTED (error)
GATE_BLOCKED -> PLANNING (approved) | HALTED (rejected)
HALTED -> PLANNING (--resume) | IDLE (abort)
```

## Failure Recovery

| Failure | Recovery |
|---------|----------|
| Worker crash | Retry up to 3x, then HALT |
| Worker timeout | Kill and retry |
| Budget exceeded | Worker exits cleanly, logged |
| Session budget hit | HALT with warning |
| Merge conflict | HALT, manual resolution required |
| Producer bad JSON | Retry up to 3x, then HALT |
| Conductor crash | `--resume` reads state.json |

## Human Gates

Gates **never** auto-approve. The Conductor blocks indefinitely until `approve_gate.py` is run. On Windows, a toast notification is fired when a gate is reached.
