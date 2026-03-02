# Orchestrator Resilience Runbook

**Audience:** Studio Head (human operator)
**Last Updated:** 2026-03-02
**See Also:** `docs/engineering/orchestrator-resilience-plan.md` (full risk analysis)

---

## Overview

The conductor includes a resilience layer that gracefully handles agent failures caused by Claude usage limits, timeouts, or crashes. This runbook explains the artifacts you may encounter and the steps to take in each scenario.

---

## Suspension Checkpoints

### What Is a Checkpoint?

A suspension checkpoint is a JSON file written by the conductor when a worker agent exits abnormally (usage limit, timeout, crash) before completing its ticket. The checkpoint captures the agent's partial progress so the conductor can resume work in the next dispatch cycle rather than starting from scratch.

**Location:** `orchestrator/checkpoints/{TICKET-NNNN}.checkpoint.json`

**When it is created:** Automatically by the conductor whenever a worker exits with a failure condition. You do not create these manually.

**When it is deleted:** Automatically when the resumed worker completes the ticket successfully, or when the conductor performs auto-remediation (e.g., detects that a PR was already merged).

### Checkpoint File Schema

```json
{
  "ticket": "TICKET-0170",
  "agent": "gameplay-programmer",
  "milestone": "m9",
  "phase": "Gameplay",
  "wave": 12,
  "suspended_at": "2026-02-27T14:30:00Z",
  "reason": "usage_limit",
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

| Field | Description |
|-------|-------------|
| `ticket` | Ticket ID |
| `agent` | Agent slug that was interrupted |
| `reason` | Why it was suspended: `usage_limit`, `timeout`, `crash`, or `unknown` |
| `progress.steps_completed` | Steps the agent confirmed completing before exit |
| `progress.commit_hash` | Git commit hash if agent committed before exit (null if not committed) |
| `progress.branch` | Worktree branch name |
| `progress.pr_url` | PR URL if created (null if not) |
| `progress.pr_merged` | Whether the PR was merged before exit |
| `progress.ticket_status_on_disk` | Status in the ticket file at time of suspension |

### Manually Inspecting Checkpoints

```bash
# List all active checkpoints
ls orchestrator/checkpoints/

# Read a specific checkpoint
cat orchestrator/checkpoints/TICKET-0170.checkpoint.json

# Count unresolved checkpoints
ls orchestrator/checkpoints/*.checkpoint.json 2>/dev/null | wc -l
```

### Manually Clearing a Checkpoint

Only clear a checkpoint if you have confirmed the ticket is actually `DONE` (the agent finished its work but the conductor didn't receive the result). After confirming:

1. Verify the ticket file shows `status: DONE`.
2. Delete the checkpoint file:
   ```bash
   rm orchestrator/checkpoints/TICKET-NNNN.checkpoint.json
   ```
3. Re-run the conductor. It will pick up newly unblocked tickets normally.

**Do not delete a checkpoint if the ticket is still `IN_PROGRESS`** — you will lose the resume context and the next retry will start from scratch, potentially duplicating work.

---

## The `suspension.log` File

### What It Is

`orchestrator/suspension.log` is a structured JSON-lines log (one JSON object per line) that records every suspension-related event. It is machine-readable and intended for post-mortem analysis, not real-time monitoring.

**Location:** `orchestrator/suspension.log`

### How to Read It

Each line is a JSON object. View recent entries:

```bash
# Last 20 events
tail -20 orchestrator/suspension.log | python -m json.tool --no-ensure-ascii
```

Or pretty-print all entries:
```bash
while IFS= read -r line; do echo "$line" | python -m json.tool; echo "---"; done < orchestrator/suspension.log
```

### Field Reference

| Field | Description |
|-------|-------------|
| `timestamp` | ISO 8601 UTC timestamp |
| `event` | Event type (see table below) |
| `agent` | Agent slug |
| `ticket` | Ticket ID |
| `milestone` | Milestone ID (e.g., `m9`) |
| `phase` | Phase name |
| `wave` | Wave number |
| `checkpoint_path` | Path to checkpoint file (if applicable) |
| `retry_count` | How many retries have occurred for this ticket |
| `retry_reason` | `usage_limit` or `implementation_failure` |
| `notes` | Free-text details about the event |

### Event Types

| Event | Meaning |
|-------|---------|
| `limit_hit` | Agent subprocess exited due to detected usage limit |
| `suspended` | Checkpoint written for an interrupted ticket |
| `resume_dispatched` | Worker re-dispatched with checkpoint context |
| `resume_success` | Resumed worker completed the ticket |
| `resume_failure` | Resumed worker failed again |
| `auto_remediated` | Conductor auto-completed ticket (e.g., PR was merged but agent died before marking DONE) |
| `zombie_detected` | Stale IN_PROGRESS ticket found with no live worker on startup |

### Retention

`suspension.log` is archived at milestone close alongside `activity.log`. Both are moved to `orchestrator/logs/activity-{milestone}.log` and `orchestrator/logs/suspension-{milestone}.log`.

---

## The `LIMIT_WAIT` State

### What It Means

`LIMIT_WAIT` is a conductor state indicating that one or more agents (or the Producer itself) hit the Claude subscription usage limit. The conductor is pausing before retrying to avoid burning retry budget against a hard cap that won't clear for minutes or hours.

You will see this in the console:

```
════════════════════════════════════════════════════════════
  LIMIT_WAIT — Usage limit detected
  Cooldown cycle 1 — sleeping 15m before resuming
  Press Ctrl+C to abort
════════════════════════════════════════════════════════════
```

And in `activity.log`:
```
2026-03-02T14:30:00 [LIMIT_WAIT] Cooldown cycle 1 — sleeping 15m before resuming
```

### When It Triggers

- **Producer limit:** Producer subprocess exits abnormally and stderr/stdout contains usage-limit keywords.
- **Mass worker limit:** ≥50% of workers in a wave fail simultaneously with suspected usage limits.

### How to Override (If You Know the Limit Has Lifted)

If you know the usage limit has cleared (e.g., the 5-hour rolling window reset) and you do not want to wait:

1. Stop the conductor with Ctrl+C.
2. Edit `orchestrator/state.json` — find `"status": "LIMIT_WAIT"` and change it to `"PLANNING"`. Also reset `"_cooldown_cycle_count"` to `0` if present.
3. Re-run the conductor with `--resume`:
   ```bash
   python orchestrator/conductor.py --resume
   ```

The conductor will re-enter planning immediately.

### Configuring Cooldown Behavior

Cooldown parameters live in `orchestrator/config.json` under `limit_wait`:

```json
"limit_wait": {
  "cooldown_minutes": 15,
  "mass_threshold_pct": 50,
  "max_cooldown_cycles": 3
}
```

See `docs/engineering/orchestrator-config-reference.md` for full details on these fields.

---

## Gate Deferral on Unresolved Checkpoints

### What "Gate Deferred" Means

Normally, a phase gate fires when all tickets in the current phase are `DONE`. However, if any checkpoints exist for tickets in the current phase, the conductor **defers the gate** — even if the ticket files all show `DONE` on disk.

You will see in `activity.log`:
```
2026-03-02T14:45:00 [WARNING ] Gate deferred — 2 unresolved checkpoint(s) exist for phase "Gameplay"
```

The gate is deferred because a checkpoint indicates an agent exited abnormally — the `DONE` status may have been written by auto-remediation, and a human should verify the work before advancing to the next phase.

### How to Force the Gate If Checkpoints Are False Positives

If you have investigated and confirmed the checkpoints are stale (e.g., the auto-remediation correctly completed the tickets), clear them:

1. Inspect each checkpoint file in `orchestrator/checkpoints/`.
2. Confirm the corresponding ticket is `DONE` and the work is on `main`.
3. Delete the checkpoint files:
   ```bash
   rm orchestrator/checkpoints/TICKET-NNNN.checkpoint.json
   ```
4. Re-run the conductor. With no checkpoints, the gate will fire normally.

---

## Troubleshooting: Common Scenarios

### Scenario 1 — Conductor HALTed After 3 Cooldown Cycles

**Symptom:** `activity.log` shows three consecutive `LIMIT_WAIT` entries ending in `HALTED`.

**Cause:** Usage limit persisted through all cooldown cycles.

**Resolution:**
1. Wait for the usage window to reset (check Anthropic console for reset time).
2. Edit `orchestrator/state.json`: set `status` to `PLANNING`, remove `_cooldown_cycle_count`.
3. Re-run with `python orchestrator/conductor.py --resume`.

---

### Scenario 2 — Ticket Stuck IN_PROGRESS with No Active Worker

**Symptom:** `milestone_status.py` shows a ticket as `IN_PROGRESS` but the conductor is not running or shows no active worker for it.

**Cause:** Zombie ticket — agent exited abnormally and conductor did not clean up (or conductor itself crashed before cleanup).

**Resolution:**
1. Check `orchestrator/checkpoints/` for a checkpoint file for this ticket.
2. If a checkpoint exists, re-run the conductor — it will dispatch a resume automatically.
3. If no checkpoint exists, reset the ticket manually: edit the ticket file to `status: OPEN`, remove the IN_PROGRESS Activity Log entry, then re-run the conductor.

---

### Scenario 3 — Ticket Shows DONE But Code Is Missing from `main`

**Symptom:** Ticket is `DONE` but the expected files are not in `main`.

**Cause:** Likely auto-remediation — the conductor detected a merged PR and marked the ticket `DONE`, but the PR may have been merged with wrong content, or the wrong branch was detected.

**Resolution:**
1. Read the `suspension.log` for `auto_remediated` events referencing this ticket.
2. Check `git log main` and `git show {commit}` to inspect what was actually merged.
3. If the work is missing, create a new `BUGFIX` ticket to re-implement the missing piece.

---

### Scenario 4 — Multiple Tickets Stuck After Wave Failure

**Symptom:** All workers in a wave failed; all corresponding tickets are `IN_PROGRESS`; `orchestrator/checkpoints/` has many entries.

**Cause:** Mass usage limit hit — all workers hit the cap in the same wave.

**Resolution:**
1. Wait for the usage window to reset.
2. Re-run the conductor (`--resume` or fresh start). It will find all checkpoints, inject resume context, and re-dispatch the tickets.
3. Note: retry counters are **not** incremented for usage-limit failures, so retries are not wasted.

---

### Scenario 5 — Checkpoint Exists at Milestone Close

**Symptom:** During milestone close checklist, `orchestrator/checkpoints/` is not empty.

**Cause:** At least one ticket had an abnormal suspension that was not fully resolved before the milestone closed.

**Resolution:**
1. Read each checkpoint file.
2. Confirm the corresponding ticket is `DONE` and the work is on `main`.
3. If confirmed → delete the checkpoint and proceed with close.
4. If not confirmed → do not close the milestone. Investigate and resolve the suspended work first.

---

## Reference

- Full risk analysis: `docs/engineering/orchestrator-resilience-plan.md`
- Config options: `docs/engineering/orchestrator-config-reference.md`
- Orchestration architecture: `docs/engineering/orchestration-architecture.md`
- Activity log: `orchestrator/activity.log`
- Suspension log: `orchestrator/suspension.log`
- Checkpoint files: `orchestrator/checkpoints/`
