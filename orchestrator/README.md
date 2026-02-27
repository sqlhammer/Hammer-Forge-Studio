# Orchestrator — Hammer Forge Studio

Automated agent orchestration system. A Python Conductor script runs the main loop, the Producer agent (via `claude -p`) makes all scheduling decisions as structured JSON, and worker agents execute tickets autonomously in parallel.

## Quick Start

**Starting a new milestone (always do this first):**

```bash
cd /c/repos/Hammer-Forge-Studio
python orchestrator/start_milestone.py M8
python orchestrator/conductor.py M8
```

`start_milestone.py` writes a fresh `state.json` for the new milestone. Without it, the conductor resumes the previous milestone's saved state and ignores the CLI argument.

**Resuming an in-progress milestone after a crash:**

```bash
python orchestrator/conductor.py M8   # state.json already exists — resumes automatically
```

## How It Works

1. **Conductor** (Python) asks the **Producer** (Claude) to plan the next wave of work
2. Producer reads tickets and outputs a JSON wave plan
3. Conductor spawns **worker agents** (Claude) in parallel, each in its own git worktree
4. Workers execute their assigned tickets autonomously
5. Conductor merges branches into `main` and loops back to step 1
6. When a phase is complete, the system halts for **Studio Head approval** (human gate)

## Commands

### Start a New Milestone

```bash
python orchestrator/start_milestone.py <milestone>
python orchestrator/start_milestone.py <milestone> "<phase>"  # specify starting phase
python orchestrator/start_milestone.py <milestone> --force    # skip confirmation

# Then run the conductor:
python orchestrator/conductor.py <milestone>
```

`start_milestone.py` must be run before the conductor whenever beginning a new milestone. The conductor only creates fresh state when `state.json` is absent — if a previous milestone's state file exists, it will resume that state regardless of the milestone argument.

### Resume or Continue Orchestration

```bash
python orchestrator/conductor.py <milestone>
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

### Resume Planning After New Tickets Are Added

If the conductor has gone `IDLE` (all known tickets were DONE) and new tickets are then created, use this helper to reset it to `PLANNING` so it picks them up:

```bash
python orchestrator/resume_planning.py          # confirms before writing
python orchestrator/resume_planning.py --force  # no prompt
```

Then re-run the conductor as normal:

```bash
python orchestrator/conductor.py <milestone>
```

The script is a no-op if the conductor is not currently `IDLE`.

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
├── start_milestone.py    # CLI: initialize fresh state for a new milestone (run before conductor)
├── approve_gate.py       # CLI: approve/reject a gate
├── resume_planning.py    # CLI: reset IDLE → PLANNING when new tickets added
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
[fresh] -> PLANNING (start_milestone.py — new milestone kickoff)
IDLE -> PLANNING -> DISPATCHING -> WORKING -> EVALUATING -> PLANNING (loop)
IDLE -> PLANNING (resume_planning.py — new tickets added)
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
