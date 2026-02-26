---
id: TICKET-0144
title: "Centralize physics layer constants into PhysicsLayers core class"
type: TASK
status: OPEN
priority: P3
owner: systems-programmer
created_by: systems-programmer
created_at: 2026-02-26
updated_at: 2026-02-26
milestone: "M7"
phase: "QA"
depends_on: []
blocks: []
tags: [physics-layers, architecture, core, coding-standards]
---

## Summary

Multiple M7 scripts define their own local copies of physics layer bit-mask constants (`LAYER_PLAYER`, `LAYER_ENVIRONMENT`, `LAYER_INTERACTABLE`). This duplication creates a maintenance risk and is inconsistent with the intent of `docs/engineering/physics-layers.md`, which notes these should be "replaced with named constants once defined in a core constants resource."

Create a central `PhysicsLayers` class in `game/scripts/core/physics_layers.gd` and update all scripts referencing local layer constants to use it.

## Identified Duplication Sites

| File | Local Constants Defined |
|------|------------------------|
| `game/scripts/gameplay/ship_interior.gd` | `LAYER_PLAYER`, `LAYER_ENVIRONMENT`, `LAYER_INTERACTABLE` |
| `game/scripts/ui/interaction_prompt_hud.gd` | `LAYER_INTERACTABLE` |

Other scripts may define their own local layer constants — do a full codebase search before implementing.

## Acceptance Criteria

- [ ] `game/scripts/core/physics_layers.gd` created with `class_name PhysicsLayers` and all named layer constants matching `docs/engineering/physics-layers.md`
- [ ] All scripts with local layer constant definitions updated to reference `PhysicsLayers` instead
- [ ] `docs/engineering/physics-layers.md` updated to reference the new class and mark Status as Active
- [ ] `docs/engineering/architecture.md` updated to document PhysicsLayers as a core utility
- [ ] No new Godot editor errors

## Implementation Notes

- `PhysicsLayers` does not need to extend any Godot class — a plain `class_name` script with constants is sufficient
- Layer bit-masks: `PLAYER = 1 << 0`, `ENEMY = 1 << 1`, `ENVIRONMENT = 1 << 2`, `INTERACTABLE = 1 << 3`, `PROJECTILE = 1 << 4` (per docs)
- Do NOT change any existing layer values — only centralize the definitions

## Activity Log
- 2026-02-26 [systems-programmer] Created from TICKET-0129 FINDING-01 — physics layer constants duplicated across M7 scripts
