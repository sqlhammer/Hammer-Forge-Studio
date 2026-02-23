---
id: TICKET-0041
title: "Recycler module — data layer and logic"
type: FEATURE
status: DONE
priority: P1
owner: systems-programmer
created_by: producer
created_at: 2026-02-23
updated_at: 2026-02-23
milestone: "M4"
milestone_gate: "M3"
depends_on: [TICKET-0040]
blocks: [TICKET-0045]
tags: [ship, modules, recycler, crafting]
---

## Summary
Implement the Recycler as the first working ship module. Converts Scrap Metal into Metal. Power draw is low enough to run on the ship's baseline power without overloading the grid. Introduces Metal as a new resource type.

## Acceptance Criteria
- [ ] Recycler defined in the module catalog (install cost: Scrap Metal, power draw: within baseline capacity)
- [ ] Metal defined as a new resource type in the resource registry (tier, stack size, display name)
- [ ] Recipe defined: Scrap Metal → Metal (quantities at designer's discretion — document the choice)
- [ ] Recipe queue API: add job, cancel job, process job over time
- [ ] Processing time defined as a configurable constant (not hardcoded)
- [ ] Signal emitted on job completion (`recycler_job_completed`)
- [ ] Output resource (Metal) added to player inventory on collection — not auto-deposited
- [ ] Recycler power draw validated against baseline in TICKET-0039 — must not exceed it
- [ ] All code follows `docs/engineering/coding-standards.md`

## Implementation Notes
- Reference `docs/design/systems/mobile-base.md` for the Extraction Bay module context
- Metal is the first processed resource — it will be used in future milestones for crafting and upgrades
- The recipe queue should support at minimum one active job in M4 — multi-job queuing can be deferred
- Processing time should feel meaningful but not punishing — a few seconds in greybox, tunable for feel

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-23 [producer] Created ticket
- 2026-02-23 [systems-programmer] Implemented: Recycler autoload with recipe (3 Scrap Metal → 1 Metal, 5s processing), job start/cancel/collect API, progress signal, any-purity input consumption. Added METAL resource type to ResourceDefs (stack_size=50, processed_material category). Output collected manually (not auto-deposited). Recycler power draw=10.0, within BASELINE_POWER=30.0
