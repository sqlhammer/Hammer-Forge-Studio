---
id: TICKET-0355
title: "BUG — Tech tree panel inaccessible in gameplay: DebugShipBoardingHandler missing terminal interaction"
type: BUG
status: DONE
priority: P1
owner: gameplay-programmer
created_by: play-tester
created_at: 2026-03-07
updated_at: 2026-03-07
milestone: "M11"
phase: "QA"
depends_on: []
blocks: []
tags: [bug, tech-tree, boarding-handler, gameplay, interaction]
---

## Summary

The tech tree panel (`TechTreePanel`) cannot be opened through normal gameplay. The
`DebugShipBoardingHandler._process()` handles boarding, cockpit console, module placement
zones, and exit zone interactions — but does NOT check `is_player_near_terminal()` and never
calls `hud.get_tech_tree_panel().open()`. The tech tree terminal exists in the ship interior
scene but is completely non-interactive.

---

## Reproduction Steps

1. Launch `res://scenes/gameplay/game_world.tscn`
2. Walk to the ship and board it (press E at entrance)
3. Navigate inside to the tech tree terminal (north wall of machine room)
4. Press E (interact)
5. Observe: nothing happens — no tech tree panel opens, no interaction prompt shows

**Expected:** Tech tree panel opens, showing Fabricator and Automation Hub nodes with icons,
labels, and unlock costs.
**Actual:** No response to interact input near the terminal.

---

## Root Cause

`DebugShipBoardingHandler._process()` handles all interior interactions. It checks:
- `is_player_near_cockpit_console()` → opens navigation console
- `get_nearby_zone_index()` → opens module placement UI
- `is_player_in_exit_zone()` → exits ship

But it does NOT check `is_player_near_terminal()` (which exists in `ShipInterior`) and
does not wire any code to call `hud.get_tech_tree_panel().open()`.

`game_hud.gd` exposes `get_tech_tree_panel()` returning the `TechTreePanel` instance, but
this method is never called from any gameplay script.

---

## Expected Behavior

When the player is near the tech tree terminal in the ship interior and presses interact (E),
`TechTreePanel.open()` should be called, displaying the tech tree panel with:
- Fabricator node (Card0) with icon and "UNLOCKABLE" state
- Automation Hub node (Card1) with icon and "LOCKED" state (requires Fabricator)
- Detail panel showing selected node's name, description, unlock cost, and prerequisites
- Unlock button (enabled for Fabricator, disabled for Automation Hub)

---

## Actual Behavior

No interaction occurs at the terminal. The tech tree panel (`visible = false`) is never made
visible during gameplay. The `open()` method is only called from unit tests.

---

## Fix Recommendation

Add tech tree terminal interaction to `DebugShipBoardingHandler._process()`, analogous to
the existing cockpit console check:

```gdscript
# Tech tree terminal — open tech tree panel when near terminal
if _ship_interior.is_player_inside() and not (_hud.get_tech_tree_panel().is_open()):
    if _ship_interior.is_player_near_terminal():
        if InputManager.is_action_just_pressed("interact"):
            _hud.get_tech_tree_panel().open()
            return
```

---

## Evidence

Code audit during TICKET-0324 verification (2026-03-07):
- `debug_ship_boarding_handler.gd:_process()` — no `is_player_near_terminal()` check present
- `game_hud.gd:116` — `get_tech_tree_panel()` method defined but never called in any
  gameplay script (verified via full codebase grep)
- `ship_interior.gd:174` — `is_player_near_terminal()` method exists but never called
  from any script other than ship_interior.gd itself
- Tech tree panel starts with `visible = false` (tech_tree_panel.tscn line 7)
  and is only visible after `open()` is called — which never happens in gameplay

---

## Handoff Notes

(Leave blank until handoff occurs.)

---

## Activity Log

- 2026-03-07 [play-tester] Created during TICKET-0324 verification. Tech tree terminal
  interaction missing from DebugShipBoardingHandler — player cannot open the tech tree
  panel during gameplay. is_player_near_terminal() exists in ShipInterior and
  get_tech_tree_panel() exists in GameHUD but neither is wired in the boarding handler.
  Pre-existing gap not introduced by TICKET-0295 (scene-first refactor), but blocks
  visual verification of TICKET-0324 acceptance criteria.
- 2026-03-07 [gameplay-programmer] Starting work. Adding tech tree terminal interaction
  to DebugShipBoardingHandler._process().
- 2026-03-07 [gameplay-programmer] DONE. Added is_player_near_terminal() check in
  DebugShipBoardingHandler._process() to open TechTreePanel when player interacts near
  the tech tree terminal. Commit: 0b23470, PR: https://github.com/sqlhammer/Hammer-Forge-Studio/pull/385
