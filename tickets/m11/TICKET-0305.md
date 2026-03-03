---
id: TICKET-0305
title: "BUG — Ship boarding ContextualPrompt shows when player is not aiming at the hull"
type: BUG
status: DONE
priority: P2
owner: gameplay-programmer
created_by: producer
created_at: 2026-03-03
updated_at: 2026-03-03
milestone: "M11"
phase: "Remediation"
depends_on: []
blocks: []
tags: [interaction, ui, prompt, ship, raycast, bug]
---

## Summary

TICKET-0280 added a camera-forward raycast to `DebugShipBoardingHandler` that gates the
ship boarding action on the player pointing at the hull. However, the "Enter Ship"
`ContextualPrompt` in `InteractionPromptHUD` is still driven entirely by proximity
(`ShipEnterZone` area overlap), with no awareness of the aim check. The result: the prompt
shows whenever the player is within the enter zone, even when pressing E would do nothing
because the raycast fails.

**Player experience:** "Enter Ship" prompt appears → player presses E → nothing happens.
This is confusing and incorrect feedback.

---

## Root Cause

`ShipEnterZone.get_interaction_prompt()` returns the prompt when `_prompt_enabled` is true.
`_prompt_enabled` is only toggled off when the player is **inside** the ship
(`_on_player_entered_ship` / `_on_player_exited_ship`). It is never gated on the aim check.

`InteractionPromptHUD._get_area_prompt()` queries all `interaction_prompt_source` nodes and
shows a prompt if the player body overlaps their area — proximity only.

`DebugShipBoardingHandler._process()` calls `_is_aiming_at_ship()` only at the moment
`interact` is pressed, and silently does nothing when the check fails. There is no feedback
path from the aim check back to the prompt display layer.

**Files involved:**
- `game/scripts/gameplay/ship_enter_zone.gd` — prompt gating logic
- `game/scripts/gameplay/debug_ship_boarding_handler.gd` — raycast aim check

---

## Acceptance Criteria

- [x] The "Enter Ship" contextual prompt is only shown when the player is **both** within the
      ship enter zone **and** aiming at the ship hull (i.e., the same condition that allows the
      boarding action to fire)
- [x] When the player is in the zone but aims away from the ship, the prompt hides
- [x] When the player turns back toward the hull, the prompt reappears promptly (next frame)
- [x] The fix applies in both `GameWorld` and `DebugWorld` sessions (both use
      `DebugShipBoardingHandler`)
- [x] No regression: prompt still hides correctly when the player enters the ship
- [x] No regression: all other interaction prompts (deposits, machine slots, cockpit console,
      exit zone) are unaffected

---

## Suggested Fix

Add a per-frame aim-validity sync from `DebugShipBoardingHandler` to `ShipEnterZone`.

**Step 1 — Add `set_aim_valid()` to `ShipEnterZone`:**

```gdscript
var _aim_valid: bool = false

func set_aim_valid(valid: bool) -> void:
    _aim_valid = valid

func get_interaction_prompt() -> Dictionary:
    if not _prompt_enabled or not _aim_valid:
        return {}
    return {
        "key": "E",
        "action": "interact",
        "label": "Enter Ship",
        "hold": false,
    }
```

**Step 2 — Update aim validity each frame in `DebugShipBoardingHandler._process()`:**

```gdscript
# Inside the existing proximity block, replace the current interact check:
if _player_near_ship_entrance and not _ship_interior.is_player_inside():
    var aiming: bool = _is_aiming_at_ship()
    _ship_enter_zone.set_aim_valid(aiming)
    if aiming and InputManager.is_action_just_pressed("interact"):
        _begin_enter_ship()
    return

# At the top of _process(), ensure aim_valid is cleared when not in proximity:
# (reset to false when player leaves zone — handle in _on_ship_enter_zone_exited)
```

**Step 3 — Reset aim_valid on zone exit:**

In `_on_ship_enter_zone_exited`, add:
```gdscript
_ship_enter_zone.set_aim_valid(false)
```

This keeps the fix entirely within the two scripts already modified by TICKET-0280. No
changes are needed to `InteractionPromptHUD` or `GameWorld`.

---

## Implementation Notes

- The `_is_aiming_at_ship()` call in `_process()` runs every frame while the player is near
  the entrance — this is acceptable; it is the same raycast already used on interact press
- Graceful-degradation path (`_camera == null`) returns `true` from `_is_aiming_at_ship()`;
  `set_aim_valid` should behave consistently (prompt shows when camera is null, same as before)
- Ensure `_aim_valid` is reset to `false` on `_on_ship_enter_zone_exited` so the zone is
  clean when the player is not nearby

Refer to:
- `game/scripts/gameplay/debug_ship_boarding_handler.gd`
- `game/scripts/gameplay/ship_enter_zone.gd`
- TICKET-0280 handoff notes for full context on the raycast implementation

---

## Handoff Notes

Added `_aim_valid` state to `ShipEnterZone` with `set_aim_valid()` setter. `DebugShipBoardingHandler._process()` now calls `_is_aiming_at_ship()` every frame while the player is in the enter zone and syncs the result to the zone via `set_aim_valid()`. The aim validity resets to `false` on zone exit. No changes to `InteractionPromptHUD` or `GameWorld` were needed — both use `DebugShipBoardingHandler` which now drives the aim sync.

---

## Activity Log

- 2026-03-03 [producer] Created — TICKET-0280 left "Enter Ship" ContextualPrompt showing
  even when aim check would block boarding; prompt and action are no longer in sync
- 2026-03-03 [gameplay-programmer] IN_PROGRESS — Starting work
- 2026-03-03 [gameplay-programmer] DONE — Commit af7c2c4, PR https://github.com/sqlhammer/Hammer-Forge-Studio/pull/323
