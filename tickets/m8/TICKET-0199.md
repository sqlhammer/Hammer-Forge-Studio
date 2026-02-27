---
id: TICKET-0199
title: "Bugfix — Player falls through ground after debug launcher biome spawn"
type: BUGFIX
status: OPEN
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "M8"
phase: "QA"
depends_on: []
blocks: []
tags: [bugfix, debug, terrain, collision, player, spawn]
---

## Summary

After launching into a world via the debug scene (`res://game/scenes/debug/debug_launcher.tscn`), the player falls through the terrain. Likely cause: terrain collision shapes are not ready at the time the player is spawned, or the player is spawned before the biome's procedural generation completes.

## Steps to Reproduce

1. Open `res://game/scenes/debug/debug_launcher.tscn` in the Godot editor
2. Select any biome from the biome selector
3. Click Launch
4. Observe: player falls through the ground
5. Console error on launch:

```
E 0:00:08:275   debug_launcher.gd:348 @ _setup_gameplay(): DebugLauncher: player has no camera
  <C++ Source>  core/variant/variant_utility.cpp:1024 @ push_error()
  <Stack Trace> debug_launcher.gd:348 @ _setup_gameplay()
                debug_launcher.gd:259 @ _build_debug_world()
                debug_launcher.gd:198 @ _launch()
                debug_launcher.gd:178 @ _on_launch_pressed()
```

## Expected Behavior

Player spawns on top of solid terrain with camera attached and remains standing.

## Acceptance Criteria

- [ ] Player does not fall through the ground on debug launch for any biome (Shattered Flats, Rock Warrens, Debris Field)
- [ ] Fix applies to both begin-wealthy and normal debug launches
- [ ] Existing unit tests pass with no regression
- [ ] No "player has no camera" error on launch — camera correctly attached to player
- [ ] Root cause documented in handoff notes

## Implementation Notes

- Investigate whether `CollisionShape3D` / `ConcavePolygonShape3D` is generated and active before player placement
- Check if `generate()` / `build_scene()` completes before player spawn position is read
- Compare debug launcher spawn flow vs. normal `TestWorld` spawn flow — the normal path may have timing that the debug path skips
- May need a deferred spawn (e.g., wait one physics frame) or an explicit readiness signal from the terrain generator
- **Camera error:** `_setup_gameplay()` at line 348 reports player has no camera. Investigate whether the player scene is fully instantiated (including Camera3D child) before `_setup_gameplay()` runs. The call chain is `_on_launch_pressed()` → `_launch()` → `_build_debug_world()` → `_setup_gameplay()` — the camera may not be ready if the player scene hasn't entered the tree yet

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created — Studio Head reported player falling through ground after debug launch
