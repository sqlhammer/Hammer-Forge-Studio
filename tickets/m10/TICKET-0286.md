---
id: TICKET-0286
title: "M10 Resources — In-biome timed resource node respawn (D-007)"
type: TASK
status: IN_PROGRESS
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-03-03
updated_at: 2026-03-03
milestone: "M10"
phase: "Implementation"
depends_on: []
blocks: [TICKET-0285]
tags: [resources, respawn, deposits, config]
---

## Summary

Resource nodes that are fully mined should respawn after a configurable per-resource-type
delay. Depleted nodes must become invisible and non-interactable — but NOT freed from the
scene tree — so each node can track its own respawn timer internally. When the timer
expires the node becomes visible and mineable again.

Deep resource nodes (infinite yield) are **unaffected** — they never deplete and do not
need respawn logic.

---

## Acceptance Criteria

### Config file — `game/config/resource_respawn_config.gd` (or equivalent)
- [ ] A config resource (GDScript `Resource` subclass or `ConfigFile`) holds a
      `respawn_times: Dictionary` mapping resource type name → respawn delay in seconds
- [ ] Default values: `5 * 60` (300 s) for every resource type currently in the game
      (Scrap Metal, Cryonite, and any others present at time of implementation)
- [ ] The config file — not any hardcoded constant — is the single source of truth for
      respawn delays; no magic numbers in deposit logic
- [ ] Adding a new resource type later requires only a new entry in this config

### Deposit logic — `deposit.gd` (or equivalent)
- [ ] When a deposit is **fully depleted** (yield reaches 0):
  - [ ] The mesh and any interaction prompt become **invisible** (`visible = false`)
  - [ ] The collision shape is **disabled** so the player cannot interact with it
  - [ ] A local `Timer` node (or `_respawn_timer: float` countdown in `_process`) starts
        counting down for the duration specified in the config for this resource type
  - [ ] The node is **NOT freed** from the scene tree
- [ ] When the timer expires:
  - [ ] Deposit yield is restored to its full initial value
  - [ ] Mesh and interaction prompt become **visible** again (`visible = true`)
  - [ ] Collision shape is **re-enabled**
  - [ ] The deposit is fully mineable again

### Deep resource nodes
- [ ] `DeepResourceNode` (or any deposit with `infinite = true`) is **completely unaffected**
      by this system — do not start a respawn timer when `infinite` is `true`

### No Regressions
- [ ] Existing mine loop (hold tool, reduce yield, mine complete) still works unchanged
- [ ] Compass ping markers for depleted (invisible) deposits are **not shown** — pinged
      deposits that are currently respawning should be excluded from ping results
- [ ] Drone mining is unaffected for deep nodes
- [ ] Scene save/reload does not corrupt node state — respawn timers restart cleanly
      on scene load (acceptable: in-progress timers reset to full on reload)

---

## Implementation Notes

**Timer approach:** Prefer a `Timer` child node (`autostart = false`, `one_shot = true`)
over a `_process` float countdown — `Timer` is idiomatic Godot, easier to pause/resume,
and avoids manual delta accumulation.

**Config approach:** A lightweight `ResourceRespawnConfig` GDScript resource class
(extending `Resource`) with `@export var respawn_times: Dictionary = {}` is the
recommended pattern. Load it once at startup or as an autoload. Alternatively, a simple
GDScript `const` dictionary in a dedicated config file is acceptable if the team prefers
to avoid custom resource types.

**Respawn timer source of truth:** `deposit.gd` should read the respawn time from the
config at the moment of depletion (not at scene load) — this allows config hot-reloading
without scene restarts during development.

**Ping exclusion:** The scanner ping system reads deposits from `DepositRegistry` (or
equivalent). When filtering results, exclude deposits where `visible == false` (or add a
`is_depleted() -> bool` method to `Deposit` and filter on that).

---

## Handoff Notes

(Leave blank until handoff occurs.)

---

## Activity Log

- 2026-03-03 [producer] Created ticket — M10 resources: in-biome timed respawn (D-007)
  Studio Head decisions:
  - Respawn is per-node (each node tracks its own timer from depletion moment)
  - Config is per-resource-type; all types default to 300 s (5 min) for playtesting
  - Deep resource nodes (infinite) are excluded
  - No resource scarcity pressure goal at this phase
- 2026-03-03 [gameplay-programmer] Starting work — implementing resource respawn config and deposit timer logic
