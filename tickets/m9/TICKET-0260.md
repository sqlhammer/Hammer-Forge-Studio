---
id: TICKET-0260
title: "Code Quality: Move PlayerFirstPerson move_and_slide() from _process() to _physics_process()"
type: TASK
status: OPEN
priority: P3
owner: gameplay-programmer
created_by: producer
created_at: 2026-03-01
updated_at: 2026-03-01
milestone: "M9"
phase: "Code Quality"
depends_on: [TICKET-0235]
blocks: []
tags: [code-quality, m8-cleanup, player, physics, movement, godot-best-practices]
---

## Summary

`PlayerFirstPerson` currently calls `move_and_slide()` from `_process()`. While this works in Godot 4, `move_and_slide()` is a physics-engine call and belongs in `_physics_process()` per CharacterBody3D best practices. Running it from `_process()` means movement updates are tied to render frame rate rather than the physics tick, which can produce inconsistent collision behavior at non-standard frame rates.

## Acceptance Criteria

- [ ] All `move_and_slide()` calls in `player_first_person.gd` are moved from `_process()` to `_physics_process()`
- [ ] Physics-related state (velocity, collision detection) lives in `_physics_process()`; input reading and camera rotation may remain in `_process()` if input polling is frame-rate-sensitive
- [ ] Player movement feels identical at 60 fps — no regressions in speed, collision, or responsiveness
- [ ] Full test suite passes with no new failures

## Implementation Notes

- The split pattern is: `_process()` reads input and updates camera/look direction; `_physics_process()` applies velocity and calls `move_and_slide()`
- `delta` values differ between the two callbacks — ensure any `delta`-scaled calculations use the correct delta for their callback
- The debug 3× speed multiplier (TICKET-0220) should also live in `_physics_process()` if implemented in the same ticket pass
- No gameplay behavior changes are intended — this is a standards alignment only

## Activity Log

- 2026-03-01 [producer] Created — deferred item D-028 from M8 code review (TICKET-0177); scheduled for M9 Code Quality phase
