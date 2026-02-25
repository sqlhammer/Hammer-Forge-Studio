---
id: TICKET-0103
title: "Bugfix — Ship model was replaced; restore original model at scaled-up size"
type: BUGFIX
status: TODO
priority: P2
owner: technical-artist
created_by: producer
created_at: 2026-02-25
updated_at: 2026-02-25
milestone: "M5"
phase: "QA"
depends_on: []
blocks: []
tags: [bugfix, ship, assets, visual]
---

## Summary
During M5 the ship was intended to be scaled up. The scale was applied, but the ship mesh was also replaced with a different model. The original ship model must be restored; only the scale change should be kept.

## Reproduction
1. Launch the game and observe the ship in the game world
2. Compare against the ship model from before M5 (previous milestone build)
3. Observe that the mesh is different from the original

## Expected Behavior
The ship should use the same mesh that existed prior to M5 (the model produced in M2), scaled up to the size intended by the M5 scope.

## Fix
- Identify the correct pre-M5 ship mesh asset (from M2 production output in `game/assets/meshes/`)
- Restore that mesh on the ship scene node
- Preserve the scale increase that M5 intended
- Do not introduce any new mesh

## Acceptance Criteria
- [ ] Ship uses the original M2 model mesh, not any replacement mesh introduced in M5
- [ ] Ship is visibly larger than in M4 (scale-up intent is preserved)
- [ ] No visual regressions on ship interior or collision shape

## Activity Log
- 2026-02-25 [producer] Created from UAT feedback. Ship model was unintentionally replaced during M5 scale-up work.
