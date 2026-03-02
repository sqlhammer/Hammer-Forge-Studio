# Orchestrator Config Reference

**File:** `orchestrator/config.json`
**Override File:** `orchestrator/config.local.json` (gitignored — machine-local overrides)
**Last Updated:** 2026-03-02

The conductor merges `config.json` and `config.local.json` at startup, with `config.local.json` taking precedence on a per-key basis. Use `config.local.json` for machine-specific settings (e.g., higher parallelism on a fast workstation) without modifying the committed defaults.

---

## Top-Level Sections

| Section | Description |
|---------|-------------|
| `models` | Model assignments per agent and global default |
| `budgets` | Per-invocation and session spending limits |
| `timeouts` | Worker timeout limits (minutes) |
| `concurrency` | Parallel worker limits |
| `retries` | Retry count limits |
| `limit_wait` | Usage-limit cooldown behavior |
| `tool_tiers` | Agent tool tier assignments |
| `plan_limits` | Subscription plan capacity labels (informational) |

---

## `models`

Controls which Claude model is used for each agent.

| Field | Type | Description |
|-------|------|-------------|
| `producer` | string | Model for Producer planning invocations. One of `"opus"`, `"sonnet"`, `"haiku"`. |
| `default_worker` | string | Default model for all worker agents not listed in `overrides`. |
| `overrides` | object | Per-agent model overrides. Keys are agent slugs; values are model names. |

**Example:**
```json
"models": {
  "producer": "sonnet",
  "default_worker": "sonnet",
  "overrides": {
    "gameplay-programmer": "opus",
    "systems-programmer": "opus",
    "qa-engineer": "sonnet"
  }
}
```

---

## `budgets`

Controls per-invocation and session spending limits. Workers are launched with `--max-budget-usd` set to their effective budget.

| Field | Type | Description |
|-------|------|-------------|
| `producer_usd` | number | Max spend per Producer planning invocation (USD). |
| `default_worker_usd` | number | Default per-invocation budget for workers not in `overrides`. |
| `overrides` | object | Per-agent budget overrides. Keys are agent slugs; values are USD amounts. |
| `session_ceiling_usd` | number | Cumulative spend limit for the entire conductor session. Conductor halts with `BUDGET_WARNING` if this is exceeded. |

**Example:**
```json
"budgets": {
  "producer_usd": 1.00,
  "default_worker_usd": 3.00,
  "overrides": {
    "gameplay-programmer": 5.00,
    "systems-programmer": 5.00,
    "qa-engineer": 5.00
  },
  "session_ceiling_usd": 100.00
}
```

---

## `timeouts`

Controls how long the conductor waits for a worker before killing it and treating the invocation as a failure.

| Field | Type | Description |
|-------|------|-------------|
| `default_minutes` | integer | Default worker timeout in minutes for agents not in `overrides`. |
| `overrides` | object | Per-agent timeout overrides. Keys are agent slugs; values are minutes. |

**Example:**
```json
"timeouts": {
  "default_minutes": 30,
  "overrides": {
    "gameplay-programmer": 45,
    "qa-engineer": 45
  }
}
```

---

## `concurrency`

Controls how many workers run in parallel per wave.

| Field | Type | Description |
|-------|------|-------------|
| `max_parallel_workers` | integer | Maximum number of worker processes running simultaneously in one wave. |
| `godot_mcp_exclusive` | boolean | When `true`, at most 1 worker with `needs_godot_mcp: true` may run per wave. Default: `true`. |
| `max_tickets_per_agent_per_wave` | integer \| null | Maximum tickets assigned to a single agent per wave. `null` means unlimited. |

**Example:**
```json
"concurrency": {
  "max_parallel_workers": 8,
  "godot_mcp_exclusive": true,
  "max_tickets_per_agent_per_wave": null
}
```

**Tip:** Increase `max_parallel_workers` in `config.local.json` for workstations with more capacity. The default committed value is conservative.

---

## `retries`

Controls how many times a ticket can be retried after failure.

| Field | Type | Description |
|-------|------|-------------|
| `max_per_ticket` | integer | Maximum retry attempts per ticket before the conductor gives up and halts. Usage-limit failures do **not** count against this limit — they use `limit_wait` cooldown cycles instead. |

**Example:**
```json
"retries": {
  "max_per_ticket": 3
}
```

---

## `limit_wait`

Controls the conductor's behavior when it detects that agents have hit the Claude subscription usage limit. Added in M9 Orchestrator Resilience phase (TICKET-0184).

| Field | Type | Description |
|-------|------|-------------|
| `cooldown_minutes` | integer | How many minutes to sleep before retrying after a usage-limit detection. Default: `15`. |
| `mass_threshold_pct` | integer | Percentage of workers in a wave that must fail with a suspected usage limit to trigger wave-level `LIMIT_WAIT` (instead of per-ticket retries). Default: `50` (50%). |
| `max_cooldown_cycles` | integer | Maximum number of consecutive `LIMIT_WAIT` cycles before giving up and entering `HALTED`. Default: `3`. |

**Example:**
```json
"limit_wait": {
  "cooldown_minutes": 15,
  "mass_threshold_pct": 50,
  "max_cooldown_cycles": 3
}
```

**How it interacts with `retries.max_per_ticket`:** Usage-limit failures are tracked separately from implementation failures. A ticket retried 3 times due to usage limits has not consumed any of its `max_per_ticket` implementation retries.

**How to override at runtime:** If the usage limit has cleared and you do not want to wait for the cooldown, stop the conductor, edit `orchestrator/state.json` to set `status` to `PLANNING` and remove `_cooldown_cycle_count`, then re-run with `--resume`.

---

## `tool_tiers`

Maps agent slugs to their Godot MCP tool tier. The conductor uses this to build the `--disallowed-tools` argument when spawning workers.

| Field | Type | Description |
|-------|------|-------------|
| `"0"` | array of strings | Tier 0 agents — no Godot MCP access (e.g., `producer`). |
| `"1"` | array of strings | Tier 1 agents — read-only Godot MCP (scene tree, screenshots, file search). |
| `"2"` | array of strings | Tier 2 agents — scene construction (add/modify nodes, play scenes). |
| `"3"` | array of strings | Tier 3 agents — full engine access (create scripts, execute editor scripts). |

See `docs/engineering/orchestration-architecture.md` section 1.7 for the full list of tools per tier.

**Example:**
```json
"tool_tiers": {
  "0": ["producer"],
  "1": ["game-designer", "narrative-designer", "technical-writer"],
  "2": ["environment-artist", "character-animator", "ui-ux-designer", "audio-engineer", "vfx-artist", "qa-engineer"],
  "3": ["systems-programmer", "gameplay-programmer", "tools-devox-engineer", "technical-artist"]
}
```

---

## `plan_limits`

Informational labels about the Claude subscription plan. Used for capacity planning and logging. Not enforced by the conductor — these are reference values only.

| Field | Type | Description |
|-------|------|-------------|
| `plan_tier` | string | Human-readable plan name (e.g., `"Max 20"`). |
| `five_hour_output_token_limit` | integer | Observed output token limit per 5-hour rolling window. |
| `weekly_output_token_limit` | integer | Observed output token limit per week. |

---

## `config.local.json`

Create this file (gitignored) to override any values from `config.json` for your local machine. The conductor deep-merges `config.local.json` on top of `config.json`.

**Common local overrides:**

```json
{
  "concurrency": {
    "max_parallel_workers": 12
  }
}
```

This is the recommended way to tune parallelism without affecting the committed defaults shared by all contributors.
