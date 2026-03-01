---
id: TICKET-0199
title: "Bugfix — Player falls through ground after debug launcher biome spawn"
type: BUGFIX
status: DONE
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

- [x] Player does not fall through the ground on debug launch for any biome (Shattered Flats, Rock Warrens, Debris Field)
- [x] Fix applies to both begin-wealthy and normal debug launches
- [x] Existing unit tests pass with no regression
- [x] No "player has no camera" error on launch — camera correctly attached to player
- [x] Root cause documented in handoff notes

## Implementation Notes

- Investigate whether `CollisionShape3D` / `ConcavePolygonShape3D` is generated and active before player placement
- Check if `generate()` / `build_scene()` completes before player spawn position is read
- Compare debug launcher spawn flow vs. normal `TestWorld` spawn flow — the normal path may have timing that the debug path skips
- May need a deferred spawn (e.g., wait one physics frame) or an explicit readiness signal from the terrain generator
- **Camera error:** `_setup_gameplay()` at line 348 reports player has no camera. Investigate whether the player scene is fully instantiated (including Camera3D child) before `_setup_gameplay()` runs. The call chain is `_on_launch_pressed()` → `_launch()` → `_build_debug_world()` → `_setup_gameplay()` — the camera may not be ready if the player scene hasn't entered the tree yet

## Handoff Notes

**Root Cause — Two distinct bugs in `debug_launcher.gd`:**

**Bug 1 — "player has no camera" / Scanner/Mining/HUD never created:**
`_setup_gameplay()` was called inside `_build_debug_world()` while the `world` node had not yet entered the scene tree. `PlayerFirstPerson` uses `@onready var _camera: Camera3D = $Head/Camera3D`, which only initializes when `_ready()` fires (requires the node to be in the tree). Because `world` was built off-tree and only added to the tree after `_build_debug_world()` returned, `get_camera()` returned null, `_setup_gameplay()` exited early, and Scanner/Mining/HUD were never added.

**Bug 2 — Player falls through terrain (ShatteredFlatsBiome):**
`_get_spawn_positions()` was called while the biome was in `world` but before `world` entered the scene tree. `ShatteredFlatsBiome.generate()` is called in `_ready()`, so `_player_spawn` was still null at query time. The fallback `Vector3(250.0, 0.0, 425.0)` (Y=0) doesn't match the procedural terrain height at that XZ coordinate. With the player spawned inside the terrain mesh, Godot's physics resolver pushed the player down through the terrain.

**Fix applied — `game/scripts/gameplay/debug_launcher.gd`:**
Restructured `_launch()` to add the world to the scene tree BEFORE reading spawn positions or calling `_setup_gameplay()`. All `_ready()` callbacks (including `ShatteredFlatsBiome.generate()` and `@onready` camera initialization) complete synchronously during `get_tree().root.add_child(world)`. Player/ship positions are then set with correct terrain-aware Y values, and `_setup_gameplay()` succeeds with an initialized camera.

`_build_debug_world()` signature changed (removed unused `begin_wealthy` param — debug overlay and mouse capture moved to `_launch()`).

**Scripts modified:** `game/scripts/gameplay/debug_launcher.gd`
**No new scripts created.**
**All 14 `TestDebugLauncherUnit` tests continue to pass** (tests cover static methods only, not the modified private spawn flow).

## Activity Log

- 2026-02-27 [producer] Created — Studio Head reported player falling through ground after debug launch
- 2026-02-27 [gameplay-programmer] Starting work — investigating debug_launcher.gd spawn sequence and biome _ready() timing
- 2026-02-27 [gameplay-programmer] DONE — fixed both bugs by deferring player/ship positioning and _setup_gameplay() until after world enters scene tree; see Handoff Notes for root cause details
