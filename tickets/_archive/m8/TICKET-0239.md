---
id: TICKET-0239
title: "Bugfix — Navigation console missing interaction prompt: wrong collision layer"
type: BUGFIX
status: DONE
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-03-01
updated_at: 2026-03-01
milestone: "M8"
phase: "QA"
depends_on: []
blocks: []
tags: [bugfix, navigation-console, interaction-prompt, physics-layers, m8-qa]
---

## Summary

Targeting the navigation console never shows the contextual interaction prompt ("E — Navigate"). The prompt HUD's raycast cannot hit the console because the console's `StaticBody3D` is on the wrong physics layer.

## Reproduction Steps

1. Launch any biome via the debug launcher and board the ship
2. Walk to the cockpit and aim the crosshair at the console mesh
3. Observe the interaction prompt HUD (center-bottom of screen)

**Expected:** "E — Navigate" prompt appears when crosshair is on the console
**Actual:** No prompt — the HUD shows nothing

## Root Cause

`InteractionPromptHUD._get_raycast_prompt()` (`game/scripts/ui/interaction_prompt_hud.gd:117`) sets:

```gdscript
query.collision_mask = PhysicsLayers.INTERACTABLE  # = 1 << 3 = 8
```

`cockpit_console.tscn` sets:

```
collision_layer = 4   # decimal 4 = bit 2 = PhysicsLayers.ENVIRONMENT (layer 3)
```

`PhysicsLayers.INTERACTABLE` is `1 << 3 = 8` (layer 4). The console is on layer 3 (`ENVIRONMENT`, value 4), so the raycast mask of 8 never intersects it. The prompt therefore never fires.

`CockpitConsole._ready()` adds the node to the `"interactable"` group but does not set `collision_layer`, so the scene-file value of `4` is used at runtime.

The area-based fallback path (`_get_area_prompt()`) also does not apply — `CockpitConsole` is a `StaticBody3D`, not an `Area3D`, and is not in the `"interaction_prompt_source"` group.

## Fix

Set the console's collision layer to `PhysicsLayers.INTERACTABLE` in `CockpitConsole._ready()`:

```gdscript
func _ready() -> void:
    collision_layer = PhysicsLayers.INTERACTABLE
    collision_mask = 0
    add_to_group("interactable")
    Global.log("CockpitConsole: ready")
```

Setting it in `_ready()` (rather than patching the `.tscn`) keeps the layer assignment co-located with the group membership and ensures all future instances are correct by default. The `.tscn` value of `4` will be overridden at runtime.

Alternatively, the `.tscn` value can be corrected directly (`collision_layer = 8`) — either approach is acceptable, but the code-driven approach is preferred to keep physics layer assignments readable and centralized via `PhysicsLayers`.

**Do not** modify `interaction_prompt_hud.gd` — the raycast is correct.

## Acceptance Criteria

- [x] Aiming at the cockpit console displays the "E — Navigate" prompt in the interaction prompt HUD
- [x] Pressing E while the prompt is visible opens the navigation console modal (TICKET-0238 fix)
- [x] No other interaction prompts are affected (deposits, ship enter zone, etc.)
- [x] Full test suite passes with no new failures

## Activity Log

- 2026-03-01 [producer] Created — Studio Head reported console targeting produces no prompt; root cause traced to collision_layer = 4 (ENVIRONMENT) instead of 8 (INTERACTABLE) in cockpit_console.tscn
- 2026-03-01 [gameplay-programmer] Starting work — no dependencies, applying collision_layer fix in CockpitConsole._ready()
- 2026-03-01 [gameplay-programmer] DONE — commit a73085e, PR https://github.com/sqlhammer/Hammer-Forge-Studio/pull/202 (merged). Set collision_layer = PhysicsLayers.INTERACTABLE and collision_mask = 0 in CockpitConsole._ready().
