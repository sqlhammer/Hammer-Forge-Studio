---
id: TICKET-0263
title: "BUG: Gamepad cannot open inventory — no input action mapped to inventory toggle"
type: BUG
status: DONE
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-03-02
updated_at: 2026-03-02
milestone: "M9"
phase: "Root Game"
depends_on: []
blocks: []
tags: [bug, gamepad, inventory, input, uat-rejection]
---

## Summary

There is no gamepad button mapped to open the inventory screen. Keyboard players can press **I** to open inventory, but gamepad players have no equivalent input — the inventory is completely inaccessible when using a controller.

Discovered during Studio Head UAT of TICKET-0218 (Drop Items from Inventory). The drop-items feature requires inventory access, making TICKET-0218 untestable on gamepad until this is resolved.

## Reproduction Steps

1. Launch the game with a gamepad connected.
2. Enter gameplay (load into a biome).
3. Press every face button, shoulder button, and D-pad direction on the gamepad.
4. Observe: no button opens the inventory screen.

## Expected Behavior

A gamepad button (e.g., **Select / Back / View** or a face button chord) opens and closes the inventory screen, matching the keyboard **I** toggle.

## Actual Behavior

No gamepad input opens inventory. The inventory screen is unreachable on gamepad.

## Fix Recommendation

- Add an `open_inventory` input action in `project.godot` with an appropriate gamepad button binding.
- Wire `InventoryScreen` (or `game_hud.gd`) to respond to `open_inventory` in addition to any existing keyboard check.
- Ensure the action also appears in any on-screen control hint UI if applicable.

## Activity Log

- 2026-03-02 [producer] Filed — UAT rejection on TICKET-0218. Studio Head reported no gamepad button opens inventory during drop-items playtest.
- 2026-03-02 [gameplay-programmer] Starting work — adding JOY_BUTTON_BACK gamepad binding to inventory_toggle action.
- 2026-03-02 [gameplay-programmer] DONE — commit e9079fe, PR https://github.com/sqlhammer/Hammer-Forge-Studio/pull/289 merged. Added JOY_BUTTON_BACK to inventory_toggle action and updated hint text.
