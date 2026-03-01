---
id: TICKET-0238
title: "Bugfix — Player cannot access navigation console in debug-launched sessions"
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
tags: [bugfix, navigation-console, debug-launcher, ship-interior, m8-qa]
---

## Summary

In debug-launched biome sessions, the player can board the ship but cannot open the navigation console from the cockpit. Pressing `E` near the console does nothing — the `NavigationConsole` modal never opens.

## Reproduction Steps

1. Launch any biome via the debug launcher
2. Walk to the ship and board it (Enter Ship works correctly)
3. Walk to the cockpit console
4. Press `E` (interact)

**Expected:** Navigation console modal opens
**Actual:** Nothing happens — no modal, no log output

## Root Cause

`DebugShipBoardingHandler` (`game/scripts/gameplay/debug_ship_boarding_handler.gd`, created in TICKET-0208) mirrors the ship enter/exit logic from `TestWorld._update_ship_interact()`, but it only handles two interactions:

- Entering the ship from the exterior enter zone
- Exiting the ship from the interior exit zone

The third branch in `TestWorld._update_ship_interact()` — the cockpit console check — was never ported:

```gdscript
# test_world.gd:381-384
if InputManager.is_action_just_pressed("interact"):
    if _ship_interior.is_player_near_cockpit_console():
        if _navigation_console:
            _navigation_console.open_panel()
```

`DebugShipBoardingHandler` has no reference to `NavigationConsole` and no call to `is_player_near_cockpit_console()`, so the cockpit interact branch is silently skipped every frame.

## Fix

Add cockpit console interaction to `DebugShipBoardingHandler._process()`, mirroring the logic in `TestWorld._update_ship_interact()`.

**Required changes:**

1. `debug_ship_boarding_handler.gd` — add a `_navigation_console: NavigationConsole` field; add the cockpit console check inside `_process()` (guarded by `_ship_interior.is_player_inside()` and `not _navigation_console.is_open()`); extend `setup()` to accept and wire the `NavigationConsole` reference.

2. `debug_launcher.gd` — pass the navigation console to `handler.setup()`:
   ```gdscript
   handler.setup(ship_interior, first_person, enter_zone, hud, hud.get_navigation_console())
   ```

The interaction priority in `_process()` should match `TestWorld`: cockpit console check before exit zone check (both only fire when `is_player_inside()` is true, so order only matters if the player is somehow in both areas simultaneously, but consistency with `TestWorld` is the goal).

**Do not** modify `test_world.gd` or `navigation_console.gd` — the fix is entirely in `DebugShipBoardingHandler` and `DebugLauncher`.

## Acceptance Criteria

- [x] Pressing `E` near the cockpit console while inside the ship (debug session) opens the navigation console modal
- [x] The navigation console closes on `E` / `Esc` as designed
- [x] Enter/exit ship interactions are unaffected
- [x] The fix works in `test_world.gd` sessions without change (no regression)
- [x] Full test suite passes with no new failures

## Activity Log

- 2026-03-01 [producer] Created — Studio Head reported navigation console unreachable in debug session (screenshot: cockpit visible, interact prompt absent for console, modal never opens)
- 2026-03-01 [gameplay-programmer] Starting work — implementing cockpit console interaction in DebugShipBoardingHandler
- 2026-03-01 [gameplay-programmer] DONE — commit b6eda81, PR https://github.com/sqlhammer/Hammer-Forge-Studio/pull/200 (merged 3a9384d)
