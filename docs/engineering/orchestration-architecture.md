# Orchestration System: Architecture & Implementation Plan

## Context

Today, spawning agents is manual: the Studio Head opens a PowerShell terminal, selects an agent from a menu (`agent_skills/Microsoft.PowerShell_profile.ps1`), waits for completion, then repeats. Phase gates and dependency enforcement rely on human attention. This plan replaces that with a fully automated orchestration system where:

- A Python orchestrator script runs the main loop
- The Producer agent (via `claude -p`) makes all scheduling decisions as structured JSON
- Worker agents (via `claude -p`) execute tickets autonomously
- Human gates hard-stop the system and require explicit approval
- Everything is logged to an audit trail

---

## Phase 1: Architecture Design

### 1.1 Orchestration Topology

```
  STUDIO HEAD (human)
       |
       | start / approve gate / abort
       |
  [CONDUCTOR]  ── orchestrator/conductor.py  (Python script)
       |
       |── spawns ──> [PRODUCER]  claude -p --output-format json
       |                 |
       |                 └── reads tickets/, milestones.md
       |                     outputs: structured JSON action plan
       |
       |── parses JSON plan
       |
       |── spawns (parallel) ──> [WORKER A]  claude -p --worktree
       |── spawns (parallel) ──> [WORKER B]  claude -p --worktree
       |
       |── waits for all workers to exit
       |── merges worktree branches into main
       |── loops back to Producer for next wave
       |
       └── on gate: halt, notify human, wait for approval
```

**Key principle:** The Conductor (Python) is a dumb executor. The Producer (Claude) is the intelligent scheduler. The Conductor never decides which agent to spawn or which ticket to assign — it only executes what the Producer outputs.

**Why Python (not bash/PowerShell)?**
- The project already uses Python (`tools/milestone_status.py`)
- Native JSON parsing for Producer output (critical)
- Robust subprocess management on Windows via `asyncio`
- Works from any shell (bash, PowerShell, cmd)

### 1.2 State Machine

```
  IDLE ──(start)──> PLANNING ──(wave plan)──> DISPATCHING ──(workers spawned)──> WORKING
    ^                  |                                                            |
    |                  └──(no work)──> IDLE                                         |
    |                                                                               |
    |               EVALUATING <──(all workers exited)──────────────────────────────┘
    |                  |
    |                  ├──(more work)──> PLANNING
    |                  ├──(phase complete)──> GATE_BLOCKED
    |                  ├──(usage limit mass failure)──> LIMIT_WAIT
    |                  └──(error)──> HALTED
    |
    |               GATE_BLOCKED ──(human approves)──> PLANNING
    |                  |
    |                  └──(human rejects / gate fail)──> HALTED
    |
    |               LIMIT_WAIT ──(cooldown expires)──> PLANNING
    |                  |
    |                  └──(max cycles exceeded)──> HALTED
    |
    └──(human resume)── HALTED ──(human abort)──> IDLE
```

| State | Description |
|-------|-------------|
| `IDLE` | No work in progress. Waiting for `start` command. |
| `PLANNING` | Producer analyzing tickets, outputting next wave plan. |
| `DISPATCHING` | Conductor creating worktrees and spawning workers. |
| `WORKING` | Workers executing. Conductor monitoring PIDs. |
| `EVALUATING` | All workers done. Conductor merging branches, Producer assessing results. |
| `GATE_BLOCKED` | Phase gate fired. System halted. Waiting for Studio Head approval. |
| `LIMIT_WAIT` | Usage limit detected (Producer or ≥50% of wave workers). Conductor sleeping for `cooldown_minutes` before retrying. Transitions back to PLANNING after cooldown expires. Transitions to HALTED if `max_cooldown_cycles` is exceeded. |
| `HALTED` | Error or manual stop. Requires human intervention to resume or abort. |

### 1.3 File-Based State Artifacts

All orchestration state lives on disk. No in-memory-only state.

```
orchestrator/
├── conductor.py             # Main orchestration loop (entry point)
├── approve_gate.py          # CLI: approve a pending gate
├── status.py                # CLI: show current orchestrator state
├── config.json              # User configuration (budgets, models, timeouts)
├── state.json               # Current state machine position + active workers
├── activity.log             # Append-only audit trail
├── suspension.log           # Structured JSON-lines log for suspension events (auto-created)
├── checkpoints/             # Per-ticket suspension checkpoints (auto-created, never committed)
│   └── TICKET-NNNN.checkpoint.json
├── prompts/
│   ├── plan_wave.md         # Prompt template for Producer planning
│   └── worker_dispatch.md   # Prompt template for worker execution
├── schemas/
│   ├── wave_plan.json       # JSON schema for Producer plan output
│   └── worker_result.json   # JSON schema for worker result output
├── results/                 # Per-ticket worker result files (auto-created)
├── logs/                    # Per-agent execution logs (auto-created)
└── README.md                # Usage guide
```

### 1.3a Checkpoint System

The checkpoint system enables graceful recovery from agent failures (usage limits, timeouts, crashes) without restarting tickets from scratch.

**Directory:** `orchestrator/checkpoints/`
**Gitignored:** Yes — checkpoint files are runtime state and must never be committed.

**Lifecycle:**
1. A worker exits abnormally (non-zero exit or empty stdout).
2. Conductor probes the worktree for git state (last commit, uncommitted changes) and GitHub for PR state.
3. Conductor writes `orchestrator/checkpoints/{TICKET-NNNN}.checkpoint.json`.
4. On the next planning wave, the Producer prompt includes a summary of all pending checkpoints.
5. When the ticket is re-dispatched, the conductor injects the checkpoint content into the `{checkpoint_context}` variable in `worker_dispatch.md`.
6. The resumed agent reads the checkpoint context and picks up from the last completed step.
7. On successful completion, the conductor deletes the checkpoint file.

**Schema:**
```json
{
  "ticket": "TICKET-0170",
  "agent": "gameplay-programmer",
  "milestone": "m9",
  "phase": "Gameplay",
  "wave": 12,
  "suspended_at": "2026-02-27T14:30:00Z",
  "reason": "usage_limit | timeout | crash | unknown",
  "progress": {
    "steps_completed": ["read_ticket", "verified_deps", "marked_in_progress", "implemented", "committed"],
    "commit_hash": "abc1234",
    "branch": "orch/gameplay-programmer/TICKET-0170",
    "pr_url": null,
    "pr_merged": false,
    "ticket_status_on_disk": "IN_PROGRESS",
    "files_changed": ["game/scripts/foo.gd"],
    "new_gd_scripts": true
  },
  "notes": "Committed implementation. PR not yet created."
}
```

**Gate deferral:** If any checkpoints exist for tickets in the current phase when the conductor would normally fire a phase gate, the gate is **deferred** and logged as `[WARNING ] Gate deferred — N unresolved checkpoint(s) exist`. A human operator must inspect and clear the checkpoints before the gate will fire. See `docs/engineering/orchestrator-resilience-runbook.md` for resolution steps.

### 1.3b Suspension Log

`orchestrator/suspension.log` is a structured JSON-lines file (one JSON object per line) recording all suspension-related events. It complements `activity.log` with machine-readable detail for post-mortem analysis.

**Format:** JSON-lines — each line is a complete JSON object.

**Events logged:** `limit_hit`, `suspended`, `resume_dispatched`, `resume_success`, `resume_failure`, `auto_remediated`, `zombie_detected`.

**Retention:** Archived at milestone close to `orchestrator/logs/suspension-{milestone}.log` alongside `activity.log`.

**`state.json` schema:**
```json
{
  "status": "WORKING",
  "milestone": "M6",
  "phase": "Foundation",
  "wave_number": 2,
  "started_at": "2026-02-25T14:30:00",
  "active_workers": [
    {
      "agent": "ui-ux-designer",
      "ticket": "TICKET-0090",
      "pid": 12345,
      "worktree": "orch-uiux-0090",
      "branch": "orch/ui-ux-designer/TICKET-0090",
      "started_at": "2026-02-25T14:30:10",
      "budget_usd": 2.0
    }
  ],
  "completed_waves": [
    { "wave": 1, "tickets": ["TICKET-0086", "TICKET-0087"], "completed_at": "..." }
  ],
  "total_cost_usd": 4.23,
  "retries": { "TICKET-0092": 1 }
}
```

### 1.4 Human Gate Mechanism

When the Producer detects a phase gate condition (all tickets in a phase are DONE):

1. Conductor writes `orchestrator/pending_gate.json`:
   ```json
   {
     "type": "PHASE_GATE",
     "milestone": "M6",
     "phase": "Foundation",
     "summary": "All 6 Foundation tickets are DONE. Test suite: PASS.",
     "next_phase": "Experiments",
     "requested_at": "2026-02-25T15:20:00"
   }
   ```
2. Conductor prints a high-visibility console notification:
   ```
   ════════════════════════════════════════════════════════════
     GATE — ACTION REQUIRED
     Phase "Foundation" (M6) is complete.
     Next phase: "Experiments"
     Run: python orchestrator/approve_gate.py
   ════════════════════════════════════════════════════════════
   ```
3. On Windows, a system toast notification is fired via PowerShell subprocess.
4. Conductor enters a polling loop checking for `orchestrator/gate_response.json`.
5. Studio Head reviews, then runs:
   ```bash
   python orchestrator/approve_gate.py              # approve (default)
   python orchestrator/approve_gate.py --reject     # reject
   python orchestrator/approve_gate.py --comment "Looks good, proceed"
   ```
6. This creates `orchestrator/gate_response.json`:
   ```json
   { "action": "approve", "comment": "Looks good", "responded_at": "..." }
   ```
7. Conductor detects the response, logs it, cleans up both files, and resumes.

**Hard rule:** The gate NEVER auto-approves. The Conductor blocks indefinitely until the response file appears.

### 1.5 Activity Log Format

Append-only file at `orchestrator/activity.log`. One line per event.

```
2026-02-25T14:30:00 [SYSTEM]    Started (milestone=M6, phase=Foundation)
2026-02-25T14:30:05 [PLAN]      Wave 1: 2 assignments [TICKET-0086→ui-ux-designer, TICKET-0087→producer]
2026-02-25T14:30:06 [DISPATCH]  ui-ux-designer → TICKET-0086 (model=sonnet, budget=$2.00)
2026-02-25T14:30:06 [DISPATCH]  producer → TICKET-0087 (model=sonnet, budget=$1.00)
2026-02-25T14:42:00 [DONE]      producer ← TICKET-0087 (11m 54s, $0.12)
2026-02-25T14:45:00 [DONE]      ui-ux-designer ← TICKET-0086 (14m 54s, $1.84)
2026-02-25T14:45:01 [WAVE]      Wave 1 complete: 2/2 succeeded
2026-02-25T14:45:05 [MERGE]     Merged orch/ui-ux-designer/TICKET-0086 → main
2026-02-25T15:20:00 [GATE]      Phase "Foundation" complete — awaiting Studio Head approval
2026-02-25T15:35:00 [APPROVED]  Studio Head approved phase gate
2026-02-25T15:35:05 [PLAN]      Wave 3: 1 assignment [TICKET-0092→technical-artist]
2026-02-25T16:10:00 [FAILED]    gameplay-programmer ← TICKET-0093 (exit=1, 30m 0s, $4.50)
2026-02-25T16:10:01 [RETRY]     TICKET-0093 queued for retry (attempt 2/3)
```

Events logged: state transitions, wave plans, worker dispatch/completion (with duration and cost), merges, gate events, failures, retries. No verbose bash output.

### 1.6 Concurrency Model

**Wave-based parallelism:** Workers in the same wave run as concurrent subprocesses. Between waves, the Conductor merges and evaluates.

**Concurrency rules enforced by the Producer:**

| Rule | Enforcement |
|------|-------------|
| Same agent can't run twice concurrently | Producer assigns at most 1 ticket per agent per wave |
| Godot MCP is a singleton | At most 1 worker with `needs_godot_mcp: true` per wave |
| Non-overlapping file paths | Producer knows each agent's write scope from their CLAUDE.md |
| Ticket dependency order | Only OPEN tickets with all `depends_on` DONE are eligible |

**Configurable:** `config.json` has `max_parallel_workers` (default: 4). Set to 1 for fully sequential execution.

**Git isolation:** Each code-modifying worker gets its own worktree:
```
Worktree: .claude/worktrees/orch-{slug}-{ticket-id}
Branch:   orch/{slug}/{ticket-id}
```
Workers that only modify docs/tickets can run on main (no conflict risk). The Producer annotates each assignment with `needs_worktree: true/false`.

**Merge order (post-wave):**
1. Core systems agents first (systems-programmer)
2. Other code agents in ticket dependency order
3. Doc-only agents last (no code conflicts)

If a merge conflict occurs → Conductor enters HALTED, logs the conflict, waits for human resolution.

### 1.7 Tool Tier Enforcement

Each worker invocation includes `--disallowed-tools` based on the agent's tier from `agents/README.md`:

| Tier | Agents | Blocked Tools |
|------|--------|---------------|
| 0 (None) | producer | All `mcp__godot-mcp__*` tools |
| 1 (Read) | game-designer, narrative-designer, technical-writer | Tier 2 + Tier 3 MCP tools |
| 2 (Scene) | environment-artist, character-animator, ui-ux-designer, audio-engineer, vfx-artist, qa-engineer | Tier 3 MCP tools |
| 3 (Full) | systems-programmer, gameplay-programmer, tools-devops-engineer, technical-artist | None blocked |

Stored in `config.json` as a mapping. The Conductor builds the `--disallowed-tools` string per invocation.

### 1.8 Failure Modes & Recovery

| Failure | Detection | Recovery |
|---------|-----------|----------|
| Worker crashes (exit ≠ 0) | Process exit code | Reset ticket to OPEN, retry up to 3x, then HALTED |
| Worker timeout | Configurable timer (default 30min) | Kill process, reset ticket, retry |
| Worker succeeds but ticket not DONE | Read ticket file post-exit | Re-queue for evaluation |
| Budget overrun (per-worker) | `--max-budget-usd` enforced by CLI | Worker exits cleanly, logged as budget exceeded |
| Budget overrun (session) | Cumulative cost tracking in state.json | HALTED with BUDGET_WARNING |
| Git merge conflict | `git merge` exit code | HALTED, log conflicting files |
| Godot MCP unavailable | Worker reports tool failure | HALTED, notify user to start Godot |
| Conductor crash | state.json on disk | `python conductor.py --resume` reads state, recovers |
| Producer returns invalid JSON | JSON parse error | Retry up to 3x, then HALTED |
| Dependency cycle | Producer detects during planning | HALTED with description |

---

## Phase 2: Implementation Plan

### 2.1 Build Sequence

Steps are listed in dependency order. Each step notes what it depends on.

| # | Step | Description | Depends On |
|---|------|-------------|------------|
| 1 | Directory scaffold | Create `orchestrator/` with subdirs: `prompts/`, `schemas/`, `results/`, `logs/` | — |
| 2 | Config file | Write `orchestrator/config.json` with model assignments, budgets, timeouts, tier mappings | — |
| 3 | JSON schemas | Write `schemas/wave_plan.json` and `schemas/worker_result.json` | — |
| 4 | Prompt templates | Write `prompts/plan_wave.md` and `prompts/worker_dispatch.md` | — |
| 5 | Core conductor | Write `conductor.py` — state machine loop, state persistence, activity logging | 1, 2 |
| 6 | Producer integration | Add Producer spawn + JSON parsing to conductor (PLANNING state) | 3, 4, 5 |
| 7 | Worker spawning | Add worktree creation, tool tier enforcement, worker process management (DISPATCHING + WORKING states) | 5, 2 |
| 8 | Result collection | Add worker result parsing, branch merging, cost tracking (EVALUATING state) | 7 |
| 9 | Gate system | Add gate detection, notification, file-based approval (GATE_BLOCKED state) | 5, 8 |
| 10 | Recovery | Add crash recovery, timeout handling, retry logic, stale worktree cleanup | 5, 7 |
| 11 | CLI helpers | Write `approve_gate.py`, `status.py` | 9 |
| 12 | README | Write usage guide with bootstrap instructions | All |
| 13 | Integration test | Dry run against current tickets with minimal budget | All |

### 2.2 File Inventory

Every new file, its location, and purpose:

| File | Purpose |
|------|---------|
| `orchestrator/conductor.py` | Main orchestration loop. Entry point. ~400 lines. |
| `orchestrator/approve_gate.py` | CLI helper to approve/reject a pending gate. ~40 lines. |
| `orchestrator/status.py` | CLI helper to display current orchestrator state. ~60 lines. |
| `orchestrator/config.json` | Configuration: models, budgets, timeouts, tool tiers, parallel limits. |
| `orchestrator/state.json` | Runtime state (auto-created by conductor). |
| `orchestrator/activity.log` | Audit trail (auto-created by conductor). |
| `orchestrator/prompts/plan_wave.md` | Prompt template sent to Producer for wave planning. |
| `orchestrator/prompts/worker_dispatch.md` | Prompt template sent to each worker agent. |
| `orchestrator/schemas/wave_plan.json` | JSON schema the Producer's planning output must conform to. |
| `orchestrator/schemas/worker_result.json` | JSON schema each worker's output must conform to. |
| `orchestrator/results/` | Directory for per-ticket result JSON files (auto-populated). |
| `orchestrator/logs/` | Directory for per-agent execution logs (auto-populated). |
| `orchestrator/README.md` | Usage guide: how to start, approve gates, check status, handle failures. |

**Existing files that need minor updates:**

| File | Change |
|------|--------|
| `agents/producer/CLAUDE.md` | Add a section on structured JSON output format for orchestration planning/evaluation prompts |
| `.gitignore` | Add `orchestrator/state.json`, `orchestrator/pending_gate.json`, `orchestrator/gate_response.json`, `orchestrator/logs/`, `orchestrator/results/` |

### 2.3 Producer Planning Prompt

The Conductor calls the Producer with this prompt (from `prompts/plan_wave.md`):

```markdown
You are the Producer agent in orchestration mode. Analyze the ticket queue and output a JSON wave plan.

## Current Context
- Milestone: {milestone}
- Phase: {phase}
- Wave number: {wave_number}
- Retry queue: {retry_tickets}

## Instructions
1. Run `python tools/milestone_status.py {milestone}` to get current ticket status
2. Identify tickets that are OPEN with all depends_on satisfied (every dependency status = DONE)
3. Check if all tickets in the current phase are DONE (phase gate condition)
4. If a phase gate fires, set action to "gate_blocked"
5. Otherwise, assign workable tickets to their owners
6. Respect concurrency rules:
   - At most 1 ticket per agent per wave
   - At most 1 worker needing Godot MCP per wave
   - Max {max_parallel} workers per wave
7. Output ONLY valid JSON matching the required schema. No prose before or after.
```

**Producer output schema** (`schemas/wave_plan.json`):
```json
{
  "type": "object",
  "required": ["action"],
  "properties": {
    "action": {
      "enum": ["spawn_agents", "gate_blocked", "no_work", "milestone_complete", "error"]
    },
    "wave": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["agent", "ticket", "budget_usd", "needs_worktree", "needs_godot_mcp"],
        "properties": {
          "agent": { "type": "string" },
          "ticket": { "type": "string" },
          "budget_usd": { "type": "number" },
          "needs_worktree": { "type": "boolean" },
          "needs_godot_mcp": { "type": "boolean" },
          "prompt_supplement": { "type": "string" }
        }
      }
    },
    "gate": {
      "type": "object",
      "properties": {
        "milestone": { "type": "string" },
        "phase": { "type": "string" },
        "next_phase": { "type": "string" },
        "summary": { "type": "string" }
      }
    },
    "summary": { "type": "string" }
  }
}
```

### 2.4 Worker Dispatch

Each worker is invoked as:

```bash
claude -p \
  --model "{model}" \
  --max-budget-usd {budget} \
  --disallowed-tools "{blocked_tools}" \
  --output-format json \
  --json-schema '{worker_result_schema}' \
  --append-system-prompt "$(cat agents/{slug}/CLAUDE.md)" \
  --dangerously-skip-permissions \
  "{worker_prompt}" \
  > orchestrator/logs/{slug}-{ticket}-{timestamp}.log 2>&1
```

The `{worker_prompt}` is built from `prompts/worker_dispatch.md`:

```markdown
You are the {agent_slug} agent on Hammer Forge Studio.

## Your Assignment
Execute {ticket_id}. Read the ticket file at tickets/{milestone}/{ticket_id}.md for full details.

## Execution Steps
1. Read the ticket and verify all depends_on are DONE. If not, report outcome: "BLOCKED".
2. Update the ticket status to IN_PROGRESS with an Activity Log entry.
3. Complete all acceptance criteria listed in the ticket.
4. Commit your work with message: "{ticket_id}: {title}"
5. Push your branch and create a PR targeting main. Self-merge immediately.
6. Update the ticket status to DONE with a final Activity Log entry including the commit hash.

## Producer Notes
{prompt_supplement}

## Output
You MUST output a JSON result matching the required schema as your final response.
```

### 2.5 Configuration (`config.json`)

```json
{
  "models": {
    "producer": "sonnet",
    "default_worker": "sonnet",
    "overrides": {
      "qa-engineer": "opus",
      "gameplay-programmer": "opus",
      "systems-programmer": "sonnet",
      "technical-artist": "opus",
      "character-animator": "opus",
      "environment-artist": "opus",
      "tools-devops-engineer": "opus"
    }
  },
  "budgets": {
    "producer_usd": 1.00,
    "default_worker_usd": 3.00,
    "overrides": {
      "gameplay-programmer": 5.00,
      "systems-programmer": 5.00,
      "qa-engineer": 5.00
    },
    "session_ceiling_usd": 100.00
  },
  "timeouts": {
    "default_minutes": 30,
    "overrides": {
      "gameplay-programmer": 45,
      "qa-engineer": 45
    }
  },
  "concurrency": {
    "max_parallel_workers": 4,
    "godot_mcp_exclusive": true
  },
  "retries": {
    "max_per_ticket": 3
  },
  "tool_tiers": {
    "0": ["producer"],
    "1": ["game-designer", "narrative-designer", "technical-writer"],
    "2": ["environment-artist", "character-animator", "ui-ux-designer", "audio-engineer", "vfx-artist", "qa-engineer"],
    "3": ["systems-programmer", "gameplay-programmer", "tools-devops-engineer", "technical-artist"]
  }
}
```

### 2.6 Conductor Core Logic (Key Functions)

```python
# Pseudocode for conductor.py structure

class Conductor:
    def __init__(self, config_path, resume=False):
        self.config = load_json(config_path)
        self.state = load_or_create_state(resume)
        self.logger = ActivityLogger("orchestrator/activity.log")

    async def run(self, milestone, phase):
        """Main loop."""
        self.state.milestone = milestone
        self.state.phase = phase
        self.logger.log("SYSTEM", f"Started (milestone={milestone}, phase={phase})")

        while True:
            if self.state.status == "PLANNING":
                plan = await self.call_producer_plan()
                if plan["action"] == "no_work":
                    break
                elif plan["action"] == "gate_blocked":
                    self.state.status = "GATE_BLOCKED"
                    await self.handle_gate(plan["gate"])
                elif plan["action"] == "spawn_agents":
                    self.state.status = "DISPATCHING"
                    await self.dispatch_wave(plan["wave"])

            elif self.state.status == "WORKING":
                await self.wait_for_workers()
                self.state.status = "EVALUATING"

            elif self.state.status == "EVALUATING":
                await self.merge_branches()
                await self.handle_uid_commits()
                self.state.status = "PLANNING"

            elif self.state.status == "GATE_BLOCKED":
                await self.wait_for_gate_approval()
                self.state.status = "PLANNING"

            elif self.state.status == "HALTED":
                response = await self.wait_for_human("resume/abort")
                if response == "resume":
                    self.state.status = "PLANNING"
                else:
                    break

            self.save_state()

    async def call_producer_plan(self) -> dict:
        """Spawn Producer via claude -p, return parsed JSON plan."""
        prompt = render_template("prompts/plan_wave.md", self.state)
        result = await self.run_claude(
            agent="producer",
            prompt=prompt,
            output_format="json",
            json_schema=load_file("schemas/wave_plan.json"),
        )
        return json.loads(result.stdout)

    async def dispatch_wave(self, assignments: list):
        """Spawn workers in parallel."""
        tasks = []
        for assignment in assignments:
            task = self.spawn_worker(assignment)
            tasks.append(task)
        self.state.status = "WORKING"
        # Workers run concurrently via asyncio

    async def spawn_worker(self, assignment: dict):
        """Create worktree if needed, launch claude -p, return when done."""
        slug = assignment["agent"]
        ticket = assignment["ticket"]

        # Create worktree if needed
        if assignment["needs_worktree"]:
            worktree_path = create_worktree(slug, ticket)
            cwd = worktree_path
        else:
            cwd = REPO_ROOT

        # Build command
        cmd = build_claude_command(
            model=self.get_model(slug),
            budget=assignment["budget_usd"],
            blocked_tools=self.get_blocked_tools(slug),
            agent_claude_md=f"agents/{slug}/CLAUDE.md",
            prompt=render_template("prompts/worker_dispatch.md", assignment),
            output_format="json",
            json_schema=load_file("schemas/worker_result.json"),
        )

        # Log and spawn
        self.logger.log("DISPATCH", f"{slug} → {ticket} (${assignment['budget_usd']:.2f})")
        start = time.time()
        proc = await asyncio.create_subprocess_exec(*cmd, cwd=cwd, ...)
        await proc.wait()
        duration = time.time() - start

        # Log result
        self.logger.log("DONE" if proc.returncode == 0 else "FAILED",
                       f"{slug} ← {ticket} ({format_duration(duration)})")

    async def handle_gate(self, gate: dict):
        """Write pending gate file, notify human, wait for response."""
        write_json("orchestrator/pending_gate.json", gate)
        self.logger.log("GATE", f"Phase \"{gate['phase']}\" complete — awaiting approval")
        print_gate_notification(gate)
        fire_windows_toast(gate)

        # Poll for response file
        while not Path("orchestrator/gate_response.json").exists():
            await asyncio.sleep(5)

        response = load_json("orchestrator/gate_response.json")
        if response["action"] == "approve":
            self.logger.log("APPROVED", "Studio Head approved phase gate")
            self.state.phase = gate.get("next_phase", self.state.phase)
            cleanup_gate_files()
        else:
            self.state.status = "HALTED"

    async def handle_uid_commits(self):
        """GDScript UID commit procedure from CLAUDE.md."""
        # After merging branches that may contain new .gd files:
        # 1. Trigger Godot filesystem scan
        # 2. Wait 5 seconds
        # 3. Check for new .gd.uid files
        # 4. If any, commit and push
        pass  # Implementation follows CLAUDE.md procedure exactly
```

### 2.7 How the Producer Knows When a Phase Is Done

The Producer doesn't need special logic — it already reads tickets via `python tools/milestone_status.py`. When it sees that every ticket in the current phase has `status: DONE` and no more OPEN tickets exist for that phase, it outputs `action: "gate_blocked"` with the gate details. The Conductor trusts this output.

The Producer also verifies gate conditions:
- All tickets in phase = DONE
- Test suite passes (calls `python tools/milestone_status.py` and checks for dependency violations)
- No BLOCKER tickets exist

### 2.8 How Studio Head Launches and Interacts

**Bootstrap (first time):**
```bash
cd /c/repos/Hammer-Forge-Studio
python orchestrator/conductor.py M6 Foundation
```

**Approve a gate:**
```bash
python orchestrator/approve_gate.py                    # approve
python orchestrator/approve_gate.py --reject           # reject
python orchestrator/approve_gate.py --comment "LGTM"   # approve with note
```

**Check status (while running):**
```bash
python orchestrator/status.py
```
Outputs: current state, active workers, wave history, cost so far.

**View activity log:**
```bash
tail -50 orchestrator/activity.log
```

**View specific agent's log:**
```bash
cat orchestrator/logs/gameplay-programmer-TICKET-0092-*.log
```

**Resume after crash:**
```bash
python orchestrator/conductor.py --resume
```

**Stop gracefully:**
Ctrl+C in the conductor terminal. It catches SIGINT, waits for active workers, saves state, exits.

---

## Verification Plan

After implementation, test with these steps:

1. **Dry run with budget $0.10 per worker** — Confirm the Conductor correctly calls the Producer, parses the wave plan, and attempts to spawn workers (they'll exit quickly due to budget).

2. **Gate test** — Temporarily set all Foundation tickets to DONE, run the Conductor, verify it detects the gate, prints the notification, and halts until `approve_gate.py` is run.

3. **Failure test** — Kill a worker mid-execution, verify the Conductor detects the crash, logs it, and retries on the next wave.

4. **Merge test** — Run two doc-only workers in parallel, verify both branches merge cleanly.

5. **Full integration** — Run against the actual M6 Foundation tickets with real budgets and verify end-to-end operation.

---

## Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Python for Conductor | Already in project (`tools/milestone_status.py`), native JSON, robust subprocess mgmt on Windows |
| Producer as read-only JSON brain | Matches existing Producer boundaries (no `/game/` writes). Clean separation of intelligence and execution. |
| File-based gate approval | Works even when human isn't watching the terminal. Auditable (response file is an artifact). |
| One ticket per worker | Clean success/failure semantics, accurate cost attribution, simple retry logic |
| Wave-based (not continuous) | Merge between waves prevents conflicts. Deterministic ordering. |
| Reuse `tools/milestone_status.py` | Proven ticket parser, no need to reimplement frontmatter parsing |
| `--disallowed-tools` for tier enforcement | Simpler than enumerating all allowed tools. Blocks only what's restricted. |
| Worktrees for code agents, main for doc agents | Isolation where conflicts are possible, simplicity where they aren't |
| `--dangerously-skip-permissions` for workers | Automated agents can't approve permission prompts interactively |

---

## What This Plan Does NOT Change

- Ticket file schema (unchanged)
- Agent CLAUDE.md files (Producer gets a minor addendum for JSON output format)
- Git workflow (worktrees → PR → self-merge, same as today)
- Phase gate protocol (same conditions, same Studio Head approval)
- Milestone structure and milestone_status.py tool
- Existing PowerShell profile (preserved as manual fallback)
