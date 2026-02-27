# Orchestrator Resilience Plan — Usage Limit Edge Cases

**Author:** producer
**Created:** 2026-02-27
**Status:** Approved for M9 implementation
**Milestone:** M9 — Orchestrator Resilience phase

---

## Overview

This document identifies failure modes that emerge when one or more agents hit the Claude Max subscription usage wall mid-work, and defines handling protocols for graceful failure, resume, and structured logging. The conductor already handles generic worker failures (timeout, crash, non-zero exit) via retry queuing — the risks below are specifically about gaps that usage limits expose.

---

## Task 1 — Risk Registry

| # | Trigger Condition | Affected Artifact | Failure Mode | Blast Radius |
|---|---|---|---|---|
| **R1** | Worker hits usage limit mid-ticket after committing + pushing but before outputting structured JSON result | Ticket file (IN_PROGRESS), branch (merged or unmerged), result JSON (missing) | Conductor sees exit=0 + empty stdout, logs CRASH, queues retry. Retry session starts fresh, re-reads ticket (still IN_PROGRESS), hits pre-claim check in `worker_dispatch.md` and reports `outcome: "blocked"` with "already IN_PROGRESS." Dead-locks the ticket — exhausts 3 retries reporting "blocked" then HALTs. | Ticket is dead-locked. All tickets with `depends_on` pointing to it are permanently blocked. Phase gate cannot pass. Milestone stalls. |
| **R2** | Worker hits limit after pushing branch but before self-merging PR | Worktree branch (pushed to remote), PR (not created or created but not merged), ticket (IN_PROGRESS) | Conductor sees empty stdout/crash, retries. New retry creates a new worktree + branch, but old remote branch `orch/{agent}/{ticket}` still exists. `_merge_pending_branches` may find old branch and clean it up prematurely. Orphaned remote branch persists on GitHub. | Retry may succeed from scratch, but orphaned remote branch clutters the repo. If PR was created but not merged, GitHub shows an abandoned PR. If retry also fails, R1 compounds. |
| **R3** | Worker hits limit after creating PR and merging it, but before writing DONE to ticket file and outputting JSON | Ticket (IN_PROGRESS), code (merged to main), result JSON (missing) | Code is on main but ticket reads IN_PROGRESS. Conductor's session-completion verification won't catch it because ticket was never added to `completed_this_session`. Retry hits pre-claim "already IN_PROGRESS" dead-lock (same as R1), but worse: work is actually done on main. | Duplicate work risk if someone manually resets ticket. Phase blocked by a ticket whose work is already merged. |
| **R4** | Producer hits usage limit during `_do_planning` after `claude -p` call starts but before returning valid JSON | `state.json` (status=PLANNING), wave plan (missing/corrupt) | Conductor catches JSON parse failure, retries up to 3 times. If limit persists across all 3 retries (likely for daily/weekly cap), conductor HALTs. | All work stops. Clean HALT, no data corruption. But conductor does not distinguish "bad JSON" (retry useful) from "usage limit" (retry futile). Three futile retries burn ~$3 of Producer budget for nothing. |
| **R5** | Agent hits limit during UID commit procedure — after `_handle_uid_commits` pulls main and finds `.gd.uid` files, but commit or push fails due to conductor SIGINT/crash | `.gd.uid` files (staged but not committed, or committed but not pushed) | `_handle_uid_commits` runs `git add`, `git commit`, `git push` as three sequential subprocess calls with no atomicity. If interrupted mid-sequence, main repo has dirty state. Next conductor start does `git pull` which may fail on uncommitted staged changes. | Conductor cannot restart cleanly. HALTED on git pull failure. Manual intervention required. |
| **R6** | Multiple workers hit usage limits in the same wave | Multiple tickets (all IN_PROGRESS), multiple branches/PRs in various states | Each failed worker independently triggers retry. If all 8 parallel workers fail due to account-wide limit, all 8 retries also fail immediately. 3 retries x 8 tickets = 24 futile invocations before HALT. | Massive budget waste ($72+ at $3/ticket default). All retry counters exhausted. When limit lifts, tickets that could have succeeded are permanently HALTED because retries are spent. |
| **R7** | Producer hits limit mid-gate-evaluation — specifically during the planning wave where it would emit `gate_blocked` action | `state.json` (status=PLANNING), pending gate (not written) | Producer was supposed to detect phase completion and emit `gate_blocked`. Instead it crashes. Conductor retries Producer. If limit persists, HALT. Gate that should have fired never fires. | Gate is delayed but not corrupted, unless session is restarted fresh (clearing `completed_this_session`), in which case Producer may re-dispatch already-DONE tickets or fail to recognize phase completion. |
| **R8** | Resumed agent session has no memory of partial work from the interrupted session | Ticket (IN_PROGRESS), partial code changes (committed or uncommitted in worktree) | Claude sessions are stateless — each `claude -p` invocation starts fresh. Retry reads ticket (IN_PROGRESS), hits pre-claim guard. Even without the guard, new session has zero knowledge of previous accomplishments — may redo work, create conflicting commits, or miss steps. | Duplicate commits, merge conflicts, inconsistent implementations. `worker_dispatch.md` has no mechanism to communicate "you are resuming interrupted work." |
| **R9** | Ticket stuck IN_PROGRESS with dead agent session — "zombie ticket" | Ticket file (IN_PROGRESS indefinitely), phase (cannot complete) | Conductor tracks `active_ticket_ids` in state but clears them when processing results. If conductor itself crashes, `active_ticket_ids` may contain stale entries. On restart, planning prompt includes these IDs, but Producer has no protocol to detect zombies vs. legitimately in-flight work. | Ticket appears "owned" but no agent is working on it. Phase gate blocked. Producer may avoid re-dispatching because it's "active." Requires manual intervention. |
| **R10** | Agent hits limit after marking ticket DONE but before outputting JSON — "silent success" | Ticket (DONE on disk), result JSON (missing), `completed_this_session` (missing entry) | Conductor sees crash, queues retry. Retry reads ticket, sees DONE, but dispatch prompt doesn't say "if ticket is already DONE, report done immediately." Retry may re-do work or get confused. | Wasted retry. Session-completion verification in `_do_planning` will eventually catch it on the next wave cycle, but not during current retry processing. |

---

## Task 2 — Graceful Failure + Resume Plan

### 2.1 Suspension Checkpoint Format

**File path:** `orchestrator/checkpoints/{TICKET-NNNN}.checkpoint.json`

**Schema:**

```json
{
  "ticket": "TICKET-0170",
  "agent": "gameplay-programmer",
  "milestone": "m8",
  "phase": "Gameplay",
  "wave": 12,
  "suspended_at": "2026-02-27T14:30:00Z",
  "reason": "usage_limit | timeout | crash | unknown",
  "progress": {
    "steps_completed": [
      "read_ticket",
      "verified_deps",
      "marked_in_progress",
      "implemented",
      "committed"
    ],
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

**Who writes it:** The conductor writes a minimal checkpoint whenever a worker exits abnormally. The conductor infers most fields from `state.json` (`active_workers` contains agent, ticket, branch, worktree path). The `progress` section is best-effort — the conductor probes git state in the worktree to fill it.

### 2.2 Conductor Checkpoint Writer Protocol

When a worker exits abnormally, **before** queuing a retry, the conductor must:

1. **Probe the worktree** (if it still exists) for git state:
   - `git -C {worktree_path} log --oneline -1` — did the agent commit? Extract hash.
   - `git -C {worktree_path} status --porcelain` — are there uncommitted changes?
   - `git -C {worktree_path} branch --show-current` — confirm branch name.
2. **Probe the remote** for PR state:
   - `gh pr list --head {branch} --json number,state,merged` — is there an open/merged PR?
3. **Read the ticket file** to get current `status:` on disk.
4. **Write** `orchestrator/checkpoints/{TICKET-NNNN}.checkpoint.json`.
5. **Log** the checkpoint creation: `[CHECKPOINT ] TICKET-NNNN suspended — wrote checkpoint`.

### 2.3 Handling Protocols per Risk

| Risk | Graceful Failure Protocol | Resume Protocol |
|---|---|---|
| **R1** (limit after commit, no JSON) | Conductor writes checkpoint with `commit_hash` from worktree. Does NOT increment retry counter yet — first checks if ticket is DONE on disk. If DONE → skip retry, add to `completed_this_session`. If IN_PROGRESS with commit → queue retry with checkpoint context. | Retry dispatch includes checkpoint: "You are resuming TICKET-XXXX. Previous session committed {hash} on branch {branch}. Ticket is currently {status}. Remaining steps: push if unpushed, create/merge PR, mark ticket DONE, output JSON." |
| **R2** (limit after push, PR open/missing) | Conductor probes `gh pr list --head {branch}`. If PR exists and is merged → treat as R3. If PR exists unmerged → checkpoint records `pr_url`, `pr_merged: false`. If no PR → checkpoint records branch was pushed. | Resume prompt: "PR exists at {url} but is not merged. Merge it, then mark DONE." Or: "Branch {branch} is pushed but no PR exists. Create PR, merge, mark DONE." |
| **R3** (limit after merge, ticket still IN_PROGRESS) | Conductor detects: ticket on disk = IN_PROGRESS, but `gh pr list --head {branch} --json merged` shows merged. **Auto-remediate**: update ticket file to DONE, write Activity Log entry. Add to `completed_this_session`. No retry needed. | No resume needed — conductor self-heals. Log: `[CLEANUP ] TICKET-NNNN auto-completed — PR merged but agent exited before marking DONE`. |
| **R4** (Producer limit during planning) | Conductor checks stderr for usage limit keywords ("rate limit", "usage limit", "capacity"). If detected → do NOT retry immediately. Enter `LIMIT_WAIT` state with 15-minute cooldown. Log: `[BUDGET ] Producer hit usage limit — cooling down 15m`. | After cooldown, retry planning. If 3 cooldown cycles pass without success, HALT. Prevents burning all 3 retries rapidly against a hard cap. |
| **R5** (UID commit interruption) | Add `_uid_commit_pending` flag to `state.json`. Make each step (add/commit/push) check preconditions before executing. On conductor restart, if flag is set, run `_handle_uid_commits` before entering main loop. | Sequence: check for uncommitted staged .uid files → commit if needed → push if needed → clear flag. Idempotent. |
| **R6** (mass usage limit) | When processing wave results, if >=50% of workers fail with suspected usage limit, enter `LIMIT_WAIT` instead of queuing individual retries. Prevents 24 futile retry invocations. | After cooldown, re-dispatch failed tickets as a normal wave. Retry counters NOT incremented for usage-limit failures — separate `retry_reason` tracking. |
| **R7** (Producer limit during gate evaluation) | Same as R4 cooldown. Additionally, conductor itself detects gate condition as fallback: count DONE tickets in current phase, emit gate if all DONE. | Conductor-level gate detection: after each EVALUATING cycle, if all phase tickets are DONE on disk, emit gate without waiting for Producer. |
| **R8** (resumed agent has no context) | Checkpoint file IS the context transfer mechanism. | Modify `worker_dispatch.md` to include `{checkpoint_context}` variable. When checkpoint exists, conductor injects it into dispatch prompt with previous commit hash, branch state, PR state, completed steps, and remaining instructions. |
| **R9** (zombie ticket) | On startup, compare `active_ticket_ids` against running processes (none after restart). Any ticket with no live process is a zombie. | For each zombie: write checkpoint (probe git/PR state), remove from `active_ticket_ids`, log `[CLEANUP ] TICKET-NNNN was zombie — wrote checkpoint, cleared from active set`. Re-dispatched next planning wave with checkpoint context. |
| **R10** (silent success — DONE on disk, no JSON) | During result processing, before queuing retry, always check ticket status on disk. If DONE → don't retry. **This check exists at conductor.py:1147 but only for `outcome == "done"`**. Must also run in crash/empty-stdout path. | Add `_check_silent_success` in crash handler (lines 1121-1126) and non-zero exit handler (lines 1175-1182): read ticket status, if DONE → log success, add to wave_tickets, skip retry. |

### 2.4 Resume Handshake Protocol

1. **On startup**, conductor checks `orchestrator/checkpoints/` for `.checkpoint.json` files.
2. For each checkpoint:
   - If ticket status on disk is `DONE` → auto-remediate (add to completed set, delete checkpoint, log).
   - If ticket status is `IN_PROGRESS` or `OPEN` → leave checkpoint for Producer to discover during planning.
3. **During planning**, the Producer prompt includes `{pending_checkpoints}` listing active checkpoints with progress summaries.
4. **When dispatching** a ticket with a checkpoint, conductor injects checkpoint context into `{prompt_supplement}`.
5. **On successful completion**, conductor deletes checkpoint file and logs `[CHECKPOINT ] TICKET-NNNN checkpoint cleared`.

---

## Task 3 — Logging Specification

### 3.1 Event Types

| Event Type | Tag | Description |
|---|---|---|
| Usage limit detected | `LIMIT` | Agent or Producer subprocess exited due to suspected usage limit |
| Suspension checkpoint written | `CHECKPOINT` | Checkpoint file created for interrupted ticket |
| Checkpoint cleared | `CHECKPOINT` | Checkpoint deleted after successful resume/completion |
| Cooldown entered | `LIMIT_WAIT` | Conductor entering cooldown period after usage limit detection |
| Cooldown expired | `LIMIT_WAIT` | Cooldown period ended, retrying |
| Resume dispatched | `RESUME` | Worker dispatched with checkpoint context |
| Resume success | `RESUME` | Resumed worker completed the ticket successfully |
| Resume failure | `RESUME` | Resumed worker failed to complete (escalate) |
| Auto-remediation | `CLEANUP` | Conductor auto-completed a ticket (e.g., R3 — PR merged, agent died) |
| Zombie detected | `CLEANUP` | Stale IN_PROGRESS ticket with no live worker |

### 3.2 Log Locations

**Primary log:** `orchestrator/activity.log` (existing — add new tags above)

**Structured suspension log:** `orchestrator/suspension.log` — JSON-lines format, one entry per line, for machine-readable analysis during gate evaluation.

### 3.3 Suspension Log Entry Format

```json
{
  "timestamp": "2026-02-27T14:30:00Z",
  "event": "limit_hit | suspended | resume_dispatched | resume_success | resume_failure | auto_remediated | zombie_detected",
  "agent": "gameplay-programmer",
  "ticket": "TICKET-0170",
  "milestone": "m8",
  "phase": "Gameplay",
  "wave": 12,
  "checkpoint_path": "orchestrator/checkpoints/TICKET-0170.checkpoint.json",
  "retry_count": 1,
  "retry_reason": "usage_limit | implementation_failure",
  "notes": "Free-text details"
}
```

### 3.4 Retention Policy

- `activity.log`: Append-only within a milestone. Archive to `orchestrator/logs/activity-{milestone}.log` at milestone close.
- `suspension.log`: Same lifecycle as `activity.log`.
- `orchestrator/checkpoints/`: Deleted on successful completion or auto-remediation. Any checkpoints present at milestone close are flagged as anomalies in the close report.
- `orchestrator/results/`: Retained for milestone duration, archived with tickets.

### 3.5 Producer Gate-Evaluation Integration

During gate evaluation, the Producer must check for unresolved suspension states. Add to `plan_wave.md`:

```
## Suspension State
{suspension_summary}
```

The conductor generates `{suspension_summary}` by:
1. Reading all files in `orchestrator/checkpoints/`.
2. For each: report ticket ID, agent, last known progress, time since suspension.
3. If any checkpoints exist for tickets in the current phase, the gate **cannot pass**. Enforced at conductor level — if all phase tickets are DONE on disk but checkpoints exist, conductor does not emit gate. Instead: `[WARNING ] Gate deferred — {N} unresolved checkpoints exist`.

---

## Task 4 — Implementation Recommendations

| Priority | Change | File/Artifact | Addresses Risk | Studio Head Approval |
|---|---|---|---|---|
| **P0** | Add silent-success check to crash/timeout handlers — before queuing retry, read ticket status on disk; if DONE, skip retry | `orchestrator/conductor.py` lines 1121-1126, 1171-1182 | R1, R3, R10 | No |
| **P0** | Remove or gate the IN_PROGRESS pre-claim check — when a checkpoint exists, retry must proceed even if ticket is IN_PROGRESS | `orchestrator/prompts/worker_dispatch.md` line 10 | R1, R8 | No |
| **P0** | Add checkpoint writer to `_do_working` result processing — probe worktree git state + PR state before queuing retry | `orchestrator/conductor.py` (new `_write_checkpoint`), new dir `orchestrator/checkpoints/` | R1, R2, R3, R8, R9 | No |
| **P1** | Add checkpoint context injection to worker dispatch — `{checkpoint_context}` variable in dispatch prompt | `orchestrator/prompts/worker_dispatch.md`, `orchestrator/conductor.py` | R8 | No |
| **P1** | Add usage-limit detection heuristic — scan stderr/stdout for limit keywords; add `retry_reason` field | `orchestrator/conductor.py` (new `_detect_usage_limit`) | R4, R6 | No |
| **P1** | Add `LIMIT_WAIT` state to conductor — 15-minute cooldown, wave-level detection (>=50% failures) | `orchestrator/conductor.py`, `orchestrator/config.json` | R4, R6 | No |
| **P1** | Add zombie detection on startup — compare `active_ticket_ids` against live processes, write checkpoints | `orchestrator/conductor.py` (startup sequence) | R9 | No |
| **P2** | Make `_handle_uid_commits` idempotent — `_uid_commit_pending` flag, check preconditions per step | `orchestrator/conductor.py` | R5 | No |
| **P2** | Add conductor-level gate detection fallback — count DONE tickets in phase, emit gate without Producer | `orchestrator/conductor.py` | R7 | No |
| **P2** | Add `suspension.log` (JSONL) alongside `activity.log` | `orchestrator/conductor.py` (new `SuspensionLogger`) | All | No |
| **P2** | Add `{suspension_summary}` and `{pending_checkpoints}` to Producer planning prompt | `orchestrator/prompts/plan_wave.md` | R7, R8, R9 | No |
| **P2** | Do not increment retry counter for usage-limit failures — separate `retry_reason` tracking | `orchestrator/conductor.py`, `orchestrator/state.json` | R6 | No |
| **P3** | Auto-remediation for R3 (PR merged, ticket IN_PROGRESS) — detect via `gh` CLI, auto-update ticket | `orchestrator/conductor.py` | R3 | No |
| **P3** | Checkpoint cleanup at milestone close — flag unresolved checkpoints in close report | `CLAUDE.md` (milestone close section) | All | **Yes** |
| **P3** | Add `limit_wait_minutes` and `limit_mass_threshold_pct` to config.json | `orchestrator/config.json` | R4, R6 | No |
| **P3** | Gate deferral on unresolved checkpoints — refuse to fire gate if checkpoints exist for phase tickets | `orchestrator/conductor.py` | R7 | No |
| **P3** | Archive rotation for `activity.log` and `suspension.log` at milestone close | Producer close protocol | All | No |

### Implementation Sequence

**Phase 1 (Critical — fixes dead-locks):** P0 items. Surgical fixes to `conductor.py` and `worker_dispatch.md` preventing the R1 dead-lock. Single ticket.

**Phase 2 (Checkpoint infrastructure):** P1 items. Checkpoint system, usage-limit detection, LIMIT_WAIT state. 2-3 tickets.

**Phase 3 (Polish):** P2-P3 items. Structured logging, gate deferral, auto-remediation, config tunables. 2-3 tickets.

**Total: 5-7 implementation tickets** plus 1 documentation ticket, implemented as a non-blocking "Orchestrator Resilience" phase within M9.
