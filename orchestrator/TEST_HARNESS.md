# Orchestrator Test Harness

End-to-end testing for the conductor state machine without touching production tickets or spending real agent budget.

## Overview

The test harness exercises the full conductor pipeline — planning, dispatching, working, evaluating, phase gates, retries — using 6 ephemeral fake tickets organized into two phases. It runs in two modes:

| Mode | Cost | Duration | What it does |
|------|------|----------|--------------|
| `mock` | Free | ~0.1s | Canned JSON responses, no subprocess calls, no LLM |
| `live` | ~$2-3 | ~5 min | Real `claude -p` calls with Haiku, trivial ticket work |

## Running

```bash
# Default: mock mode (free, instant)
python orchestrator/test_harness.py

# Explicit mock with verbose output (prints every wave plan and worker result)
python orchestrator/test_harness.py --mode mock --verbose

# Real agent integration test (costs money, takes minutes)
python orchestrator/test_harness.py --mode live

# Keep temp artifacts for debugging (state.json, activity.log, tickets/_test/)
python orchestrator/test_harness.py --mode mock --keep-artifacts
```

**Note (Windows):** If you see encoding errors with arrow characters, prefix with `PYTHONIOENCODING=utf-8`.

## What It Tests (14 Assertions)

| # | Assertion | What it validates |
|---|-----------|-------------------|
| 1 | Terminal state is IDLE | Conductor reached clean completion |
| 2 | Wave 1 dispatches 9901 + 9902 in parallel | Independent tickets run concurrently |
| 3 | Wave 1 does NOT dispatch 9903 | Dependency gate prevents premature dispatch |
| 4 | 9903 dispatched after deps satisfied | Fan-in dependency resolution works |
| 5 | Phase gate fires after Alpha | Gate triggers when all phase tickets are DONE |
| 6 | Gate auto-approved, transitions to Beta | TestConductor's auto-approval advances phase |
| 7 | 9904 + 9905 dispatched in parallel | Post-gate parallel dispatch works |
| 8 | 9906 dispatched (final fan-in) | Second fan-in dependency resolution works |
| 9 | Final wave returns milestone_complete | Conductor recognizes all work is done |
| 10 | Producer outputs match wave_plan.json schema | Structural validation of planning JSON |
| 11 | Worker results match worker_result.json schema | Structural validation of result JSON |
| 12 | 9902 fails then succeeds on retry | Failure injection + retry queue logic (mock only) |
| 13 | Budget within ceiling | Cost tracking stays under session_ceiling_usd |
| 14 | No orphan files after teardown | tickets/_test/ and temp dirs cleaned up |

## Fake Ticket Design

**Milestone:** `TEST` (no collision with production M1-M99)
**Location:** `tickets/_test/` (gitignored, created at test start, deleted at teardown)
**IDs:** TICKET-9901 through TICKET-9906

### Phase Alpha

| Ticket | Owner | depends_on | Purpose |
|--------|-------|------------|---------|
| TICKET-9901 | systems-programmer | none | Independent task A |
| TICKET-9902 | gameplay-programmer | none | Independent task B (fails once in mock mode) |
| TICKET-9903 | qa-engineer | 9901, 9902 | Fan-in — triggers phase gate when done |

### Phase Beta

| Ticket | Owner | depends_on | Purpose |
|--------|-------|------------|---------|
| TICKET-9904 | gameplay-programmer | 9903 | Post-gate task A |
| TICKET-9905 | systems-programmer | 9903 | Post-gate task B (parallel with 9904) |
| TICKET-9906 | qa-engineer | 9904, 9905 | Final fan-in — triggers milestone_complete |

## Architecture

### How mock mode works

A mock `run_claude` function replaces the real subprocess call:

- **Mock Producer** reads actual ticket frontmatter from `tickets/_test/`, computes which tickets are dispatchable (deps satisfied, correct phase), and returns `wave_plan.json`-compliant JSON.
- **Mock Worker** updates the ticket file status from OPEN to DONE and returns `worker_result.json`-compliant JSON.
- **Failure injection** is configurable: TICKET-9902 fails on its first attempt and succeeds on retry, exercising the conductor's retry queue.

### TestConductor subclass

`TestConductor` extends `Conductor` with minimal overrides:

- **Gate handling:** Auto-approves immediately (no file polling)
- **Event recording:** Tracks waves, gate events, and worker results for assertion checking
- **Evaluating:** Skips git merge/pull/UID steps (no real branches exist)
- **Signal handlers:** Disabled (not needed in tests)
- **Path redirection:** All state/log output goes to a temp directory

### Changes to production code

Only 3 files were touched (~10 lines total):

1. **conductor.py** — `REPO_ROOT`/`ORCH_DIR` overridable via `HFS_REPO_ROOT`/`HFS_ORCH_DIR` env vars; `Conductor.__init__` accepts optional `run_claude_fn` for mock injection
2. **tools/milestone_status.py** — Skips `_test` directory alongside `_archive`
3. **.gitignore** — Excludes `tickets/_test/`

## File Layout

```
orchestrator/
  test_harness.py              # Entry point, TestConductor, CLI, runner
  test_config.json             # Low-budget config (haiku, $0.50/worker, $5 ceiling)
  TEST_HARNESS.md              # This file
  test_fixtures/
    __init__.py
    ticket_templates.py        # 6 fake ticket markdown strings
    generate_tickets.py        # Write/clean tickets/_test/
    mock_agents.py             # Mock run_claude + failure injection
    assertions.py              # 14 validation functions
```

## Expected Output

```
============================================================
  Orchestrator Test Harness — Results
============================================================
  Mode:        mock
  Duration:    0.1s
  Waves:       7
  Cost:        $0.00

  [PASS] Terminal state: IDLE
  [PASS] Wave 1: parallel dispatch (TICKET-9901, TICKET-9902)
  [PASS] Wave 1: 9903 not dispatched (deps unmet)
  [PASS] Wave 3: 9903 dispatched
  [PASS] Phase gate: GATE_BLOCKED after Alpha
  [PASS] Gate auto-approved -> Beta
  [PASS] Wave 5: parallel dispatch (9904, 9905)
  [PASS] Wave 6: 9906 dispatched
  [PASS] Final wave: milestone_complete
  [PASS] Schema: producer outputs valid
  [PASS] Schema: worker results valid
  [PASS] Retry: TICKET-9902 failed then succeeded
  [PASS] Budget within ceiling ($0.00 <= $5.00)
  [PASS] Cleanup: no orphan files

  Result: 14/14 PASSED
============================================================
```
