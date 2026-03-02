---
id: TICKET-0184
title: "Usage-limit detection and LIMIT_WAIT cooldown state"
type: FEATURE
status: IN_PROGRESS
priority: P1
owner: tools-devops-engineer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "M9"
phase: "Orchestrator Resilience"
depends_on: [TICKET-0235]
blocks: []
tags: [orchestrator, conductor, resilience, usage-limit, cooldown, state-machine]
---

## Summary

The conductor currently treats all worker/Producer failures identically — retry up to 3 times, then HALT. When failures are caused by Claude Max usage limits (account-wide rate caps), retrying immediately is futile and wastes budget. This ticket adds a usage-limit detection heuristic and a new `LIMIT_WAIT` conductor state that implements a cooldown period before retrying.

See `docs/engineering/orchestrator-resilience-plan.md` Risks R4 and R6.

## Acceptance Criteria

### Usage-Limit Detection
- [ ] New function `_detect_usage_limit(exit_code, stdout, stderr) -> bool` that returns `True` if the failure appears to be a usage limit.
- [ ] Detection heuristic: scan stderr and stdout (case-insensitive) for keywords: "rate limit", "rate_limit", "usage limit", "usage_limit", "capacity", "exceeded", "too many requests", "429", "quota".
- [ ] Also trigger on: exit code 0 with completely empty stdout (common Claude Max behavior — session starts, immediately ends).

### Retry Reason Tracking
- [ ] Add `retry_reason` field to retry tracking in `state["retries"]`. Each ticket's retry entry becomes `{"count": N, "reasons": ["usage_limit", "implementation_failure", ...]}`.
- [ ] Usage-limit retries do NOT increment the retry counter used for HALT decisions. Only `implementation_failure` retries count toward the `max_per_ticket` limit.
- [ ] `_queue_retry` accepts a `reason` parameter: `"usage_limit"` or `"implementation_failure"` (default).

### LIMIT_WAIT State
- [ ] New conductor state `LIMIT_WAIT` added to the state machine, between `WORKING` and `PLANNING`.
- [ ] `LIMIT_WAIT` entered when: (a) Producer planning fails with detected usage limit, OR (b) >= `limit_mass_threshold_pct`% of workers in a wave fail with detected usage limit.
- [ ] While in `LIMIT_WAIT`: conductor sleeps in `limit_wait_minutes`-minute intervals, logging `[LIMIT_WAIT] Cooling down — {N}m remaining` every 5 minutes.
- [ ] After cooldown expires: transition to `PLANNING`, log `[LIMIT_WAIT] Cooldown expired — resuming`.
- [ ] If 3 consecutive cooldown cycles all result in immediate usage-limit failure on the very first dispatch, transition to `HALTED` with log `[BUDGET ] Persistent usage limit after 3 cooldowns — halting`.

### Configuration
- [ ] Add to `config.json`: `"limit_wait": {"cooldown_minutes": 15, "mass_threshold_pct": 50, "max_cooldown_cycles": 3}`.
- [ ] Values are configurable but have sensible defaults as shown.

### Testing
- [ ] All existing conductor tests pass.
- [ ] Add test case: mock worker stderr contains "rate limit" → `_detect_usage_limit` returns `True`.
- [ ] Add test case: 5 of 8 workers fail with usage limit → conductor enters `LIMIT_WAIT` instead of queuing individual retries.

## Implementation Notes

- The state machine currently has 6 states: `PLANNING`, `DISPATCHING`, `WORKING`, `EVALUATING`, `GATE_BLOCKED`, `HALTED`, `IDLE`. Add `LIMIT_WAIT` as the 7th.
- The cooldown sleep should respect `shutdown_requested` (check between sleep intervals, not after full cooldown).
- Mass threshold detection happens in `_do_working` after all results are processed — count usage-limit failures vs. total workers.

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created ticket — usage-limit detection and cooldown state
- 2026-03-01 [tools-devops-engineer] Starting work — implementing _detect_usage_limit, LIMIT_WAIT state, retry_reason tracking, and configuration
