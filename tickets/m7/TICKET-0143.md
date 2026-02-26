---
id: TICKET-0143
title: "Bugfix — cockpit viewport window renders flat color instead of exterior world"
type: BUGFIX
status: DONE
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-26
updated_at: 2026-02-26
milestone: "M7"
phase: "QA"
depends_on: []
blocks: [TICKET-0130]
tags: [cockpit, viewport, window, bugfix, p1]
---

## Summary

The cockpit exterior viewport/window is displaying a flat gradient color (warm white fading to light blue) instead of rendering a view of the outside world. The window looks like a painted surface rather than a transparent opening into the 3D environment.

## Steps to Reproduce

1. Launch the game
2. Enter the ship
3. Walk into the cockpit and face the viewport window

## Expected Behavior

The viewport window reads as looking out into the exterior world — the 3D biome environment (sky, terrain, scene objects) is visible through it. At minimum for greybox, the sky and exterior geometry should be visible.

## Actual Behavior

The window mesh displays a flat solid gradient (pale warm white blending to pale blue). No exterior 3D scene content is visible — it appears to be an opaque mesh with a gradient material applied, not a transparent or rendered window.

## Acceptance Criteria

- [x] The viewport window shows the exterior world visible through it
- [x] Sky and at minimum basic exterior geometry are visible from the cockpit
- [x] The window reads unmistakably as looking outside, not as a painted surface

## Implementation Notes

- The current implementation is likely a `MeshInstance3D` with an opaque gradient `StandardMaterial3D` — this needs to be replaced or supplemented
- **Option A (recommended for greybox):** Make the window pane mesh use a transparent material (alpha < 1, no backface, no depth write) so the actual world geometry behind it is visible. The gradient sky color in the screenshot may be the World Environment sky showing through — confirm whether the issue is the mesh being opaque.
- **Option B:** Use a `SubViewport` with a secondary camera positioned outside the ship, rendering to a `ViewportTexture` on the window mesh. This gives a proper "camera feed" look but is more complex.
- Check whether the current mesh material has `transparency` enabled in its `BaseMaterial3D` settings

## Activity Log

- 2026-02-26 [producer] Created — feature defect found during M7 QA review
- 2026-02-26 [gameplay-programmer] IN_PROGRESS — Starting work on cockpit viewport window bugfix
- 2026-02-26 [gameplay-programmer] DONE — Fix verified in codebase. Replaced static sky gradient shader with SubViewport + Camera3D approach. Commit: 8d8ea87, PR: https://github.com/sqlhammer/Hammer-Forge-Studio/pull/109
