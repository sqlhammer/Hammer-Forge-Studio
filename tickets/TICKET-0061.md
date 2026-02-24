---
id: TICKET-0061
title: "Fabricator module — data layer and recipes"
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
depends_on: [TICKET-0060]
blocks: [TICKET-0064, TICKET-0069]
tags: [fabricator, module-system, data, crafting]
---

## Summary
Define the Fabricator as a ship module in the module system — a crafting machine that converts refined resources into equipment and components. Extends the existing module framework (M4) with a new module type. Registers the Fabricator's M5 recipes: Spare Battery and Head Lamp. The Fabricator is unlocked via the tech tree (TICKET-0060) before it can be installed.

## Acceptance Criteria
- [ ] `FabricatorModule` defined extending the existing module base class (M4 module system)
- [ ] Module properties: weight class Medium, power draw defined (placeholder: same draw as Recycler — confirm with Studio Head)
- [ ] Module is gated behind tech tree node `fabricator_module` — cannot be installed until that node is unlocked
- [ ] Recipe system defined: each recipe has `inputs` (item type + quantity), `output` (item type + quantity), `duration` (seconds)
- [ ] M5 recipes registered:
  - Spare Battery: 10 Metal → 1 Spare Battery (placeholder cost — confirm with Studio Head)
  - Head Lamp: 5 Metal → 1 Head Lamp (placeholder cost — confirm with Studio Head)
- [ ] `queue_job(recipe_id)` method: validates inputs available, deducts inputs, begins job, emits `job_started` signal
- [ ] `job_completed` signal emitted on finish; output placed into ship inventory
- [ ] All code follows `docs/engineering/coding-standards.md`

## Implementation Notes
- Reference M4 module system implementation for base class and registration pattern
- Reference `docs/design/systems/mobile-base.md` for module category: Fabricator is an Extraction Bay-class module (crafting/production)
- The interaction panel UI (TICKET-0069) and 3D mesh (TICKET-0067) are separate tickets
- Recipe costs are placeholders — balance pass during QA (TICKET-0075 / TICKET-0076)

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-24 [producer] Created ticket
- 2026-02-24 [systems-programmer] Started implementation
- 2026-02-24 [systems-programmer] Implemented FabricatorDefs (scripts/data/fabricator_defs.gd) with recipe catalog (spare_battery, head_lamp). Created Fabricator autoload (scripts/systems/fabricator.gd) with queue_job(), cancel_job(), progress tracking, and dual output modes (inventory/equip). Added Fabricator and AutomationHub modules to ModuleDefs with tech_tree_gate field. Added get_tech_tree_gate() helper. Added tech tree gate check to ModuleManager.install_module(). Registered Fabricator in project.godot.
