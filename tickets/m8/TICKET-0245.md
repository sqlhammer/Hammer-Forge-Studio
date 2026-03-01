---
id: TICKET-0245
title: "BUG — Navigation console interaction prompt appears before player can actually interact"
type: BUG
status: IN_PROGRESS
priority: P2
owner: gameplay-programmer
created_by: producer
created_at: 2026-03-01
updated_at: 2026-03-01
milestone: "M8"
phase: "Bug Fix"
depends_on: []
blocks: []
tags: [navigation-console, interaction-prompt, hud, bug]
---

## Summary

The interaction prompt ("E — Navigate") appears on the HUD while the player is still too far away to actually open the navigation console. The player sees the prompt, presses E, and nothing happens. They must walk closer before the interaction fires. The prompt and the actual interact gate are not in sync.

## Root Cause

Two separate systems define the trigger zone at different distances:

1. **HUD prompt (too wide):** `interaction_prompt_hud.gd` uses a raycast with `INTERACTION_RAY_LENGTH = 6.0` meters. It detects the `CockpitConsole` `StaticBody3D` (which is on `PhysicsLayers.INTERACTABLE`) from up to 6 meters away and shows the prompt.

2. **Actual interact gate (narrower):** `debug_ship_boarding_handler.gd` calls `ship_interior.is_player_near_cockpit_console()`, which returns true only when the player body overlaps `CockpitConsoleArea` — an `Area3D` with a `BoxShape3D` of size `Vector3(3.0, 2.0, 2.0)` (≈ 1 meter deep in Z). The actual interact fires only inside this smaller zone.

The player is inside the raycast range long before they are inside `CockpitConsoleArea`, producing a visible-but-non-functional prompt.

## Acceptance Criteria

- [ ] The interaction prompt only appears when the player is close enough that pressing E will actually open the navigation console.
- [ ] No dead zone exists where the prompt is visible but the interact action does nothing.
- [ ] The fix does not affect the raycast-based prompt for other interactables (deposits, etc.).
- [ ] Existing unit tests pass.

## Implementation Notes

**Files:**
- `game/scripts/gameplay/ship_interior.gd` — `_build_cockpit_console_area()`
- `game/scripts/objects/cockpit_console.gd`

### Option A — Preferred: Switch cockpit prompt to area-based detection

Remove the `CockpitConsole` from raycast detection and instead register `CockpitConsoleArea` as a prompt source. This keeps the prompt range strictly in sync with the interact gate.

Steps:
1. In `cockpit_console.gd`, remove or do not set `collision_layer = PhysicsLayers.INTERACTABLE` (or remove it from the `interactable` group so the HUD raycast ignores it).
2. In `ship_interior.gd`, add `CockpitConsoleArea` to the `interaction_prompt_source` group:
   ```gdscript
   _cockpit_console_area.add_to_group("interaction_prompt_source")
   ```
3. Add `get_interaction_prompt()` to the Area3D. Since Area3D cannot have GDScript methods injected dynamically, the cleanest approach is a small attached script or to give `CockpitConsoleArea` a child `Node` that acts as the prompt delegate. Alternatively, promote the CockpitConsole StaticBody3D to be inside `CockpitConsoleArea` (as a child) and keep the raycast detection on the StaticBody3D but cap its collision shape to match the Area3D.

### Option B — Simpler: Match collision shape to the Area3D

Keep the raycast path. Add a `CollisionShape3D` to `CockpitConsole` (in `cockpit_console.gd`) whose size matches `CockpitConsoleArea` (`Vector3(3.0, 2.0, 2.0)`). This ensures the raycast only hits the console when the player is already inside the interact zone.

Option B is simpler to implement but couples the two shapes — any future resize of the interact zone requires updating both.

## Activity Log

- 2026-03-01 [producer] Created ticket — player-reported: prompt shows too early, E press does nothing at distance
- 2026-03-01 [gameplay-programmer] Starting work — implementing Option A (area-based prompt detection)
