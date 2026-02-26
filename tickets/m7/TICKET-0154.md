---
id: TICKET-0154
title: "Bugfix — ship exterior collision shapes regressed from polygon to box primitives"
type: BUGFIX
status: IN_PROGRESS
priority: P1
owner: gameplay-programmer
created_by: studio-head
created_at: 2026-02-26
updated_at: 2026-02-26
milestone: "M7"
phase: "QA"
depends_on: []
blocks: []
tags: [collision, physics, ship, regression, polygon, bugfix, p1]
---

## Summary

The ship exterior collision shapes have regressed from hand-authored polygon/trimesh colliders to basic box primitives. This produces incorrect collision geometry — the player and objects clip through the ship hull or are blocked by invisible walls that don't match the visual mesh.

The correct method is polygon-based collision (either `ConcavePolygonShape3D` for static trimesh or `ConvexPolygonShape3D` per-hull, authored against the ship mesh). This regression must be fixed and validated against the collision test harness before M7 can close.

## Steps to Reproduce

1. Load the ship exterior scene in the editor
2. Inspect the `StaticBody3D` or `CollisionShape3D` node(s) on the ship mesh
3. Observe that collision shapes are `BoxShape3D` instead of polygon/trimesh shapes
4. In-game: walk around the ship exterior and notice collision does not conform to the hull geometry

## Expected Behavior

Ship exterior `CollisionShape3D` nodes use polygon-based collision (trimesh or convex hull) that closely follows the visual mesh. Player movement around the ship feels correct — no phantom walls, no clip-through.

## Actual Behavior

`CollisionShape3D` nodes use `BoxShape3D` primitives. Collision boundary is a rough bounding box around the ship rather than the actual hull shape.

## Acceptance Criteria

- [ ] Ship exterior `CollisionShape3D` nodes replaced with polygon-based shapes — `ConcavePolygonShape3D` (trimesh) or `ConvexPolygonShape3D` (convex hull decomposition), matching the original pre-regression method
- [ ] Collision shapes visually conform to the ship hull mesh when inspected in the editor (use Godot's collision shape debug overlay to verify)
- [ ] Collision test harness passes — all ship exterior collision test cases green
- [ ] Player cannot clip through the ship hull at any point when walking the full perimeter
- [ ] No phantom collision walls extend beyond the visual mesh boundary
- [ ] Full test suite passes after fix

## Implementation Notes

- Check git history on the ship scene file to identify which M7 commit introduced the regression (likely the scene architecture refactor — TICKET-0122 or TICKET-0127)
- The original polygon collision was likely authored via "Create Trimesh Static Body" in the Godot editor on the ship mesh, or via a manually placed `ConcavePolygonShape3D` with mesh data baked in
- Do not use "Create Convex Static Body (Simplified)" — it produces a single convex hull which will not correctly represent a concave ship silhouette; use trimesh or multi-convex decomposition
- The collision test harness lives in `game/tests/` — identify the relevant test file and confirm all cases run after the fix

## Activity Log

- 2026-02-26 [studio-head] Created — regression observed during post-M7 playtesting before QA sign-off
- 2026-02-26 [gameplay-programmer] Starting work — regression traced to commit 27cd24d (TICKET-0111 scene refactor replaced VHACD convex decomposition with BoxShape3D)
