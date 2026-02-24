---
id: TICKET-0060
title: "Tech tree — data layer"
type: FEATURE
status: DONE
priority: P1
owner: systems-programmer
created_by: producer
created_at: 2026-02-24
updated_at: 2026-02-24
milestone: "M5"
milestone_gate: "M4"
phase: "Foundation"
depends_on: []
blocks: [TICKET-0061, TICKET-0064, TICKET-0068]
tags: [tech-tree, data, architecture]
---

## Summary
Define the data layer for the M5 tech tree — the system through which players spend processed resources to unlock new ship modules and capabilities. M5 requires a minimum of two nodes: the Fabricator unlock (costs 100 Metal) and the Automation Hub unlock (cost TBD, requires Fabricator unlocked). The system must be extensible so future milestones can add nodes without rework.

## Acceptance Criteria
- [ ] `TechTree` autoload (or equivalent) defined with a node graph structure
- [ ] Each node has: `id`, `display_name`, `unlock_cost` (resource type + quantity), `prerequisites` (list of node IDs), `unlocked` (bool)
- [ ] M5 nodes defined: `fabricator_module` (100 Metal, no prereqs), `automation_hub` (cost TBD, requires `fabricator_module`)
- [ ] `unlock_node(node_id)` method: validates prerequisites met, validates player has sufficient resources, deducts resources, marks node unlocked, emits `node_unlocked(node_id)` signal
- [ ] `is_unlocked(node_id)` and `can_unlock(node_id)` query methods available
- [ ] Tech tree state persists across sessions
- [ ] New nodes can be registered at startup from external resource definitions — no hardcoding in core class
- [ ] All code follows `docs/engineering/coding-standards.md`

## Implementation Notes
- Reference `docs/design/gdd.md` for tech tree design intent (broad early-game, converges late-game)
- Resources are deducted from the ship's cargo/inventory — coordinate with `Inventory` system (see M3 implementation)
- Pattern should be consistent with existing autoloads: `InputManager`, `Global`, `ShipState`
- `automation_hub` unlock cost is a placeholder — Studio Head to confirm value before TICKET-0064 implementation

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-24 [producer] Created ticket
- 2026-02-24 [systems-programmer] Started implementation
- 2026-02-24 [systems-programmer] Implemented TechTreeDefs (scripts/data/tech_tree_defs.gd) and TechTree autoload (autoloads/tech_tree.gd). Fabricator and Automation Hub nodes defined. Registered TechTree in project.godot. All scripts load clean.
