---
id: TICKET-0175
title: "Headlamp — surface toggle action in interaction prompt HUD controls panel"
type: FEATURE
status: DONE
priority: P2
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "M8"
phase: "Gameplay"
depends_on: []
blocks: []
tags: [headlamp, hud, controls-panel, input, m8-gameplay]
---

## Summary

Surface the headlamp toggle action in the interaction prompt HUD's persistent controls panel (implemented in M7 as part of D-016). When the player has a Head Lamp equipped, the controls panel displays the bound key and "Headlamp" label. The toggle mechanic itself was implemented in M5 (TICKET-0074) — this ticket ensures it is discoverable via the HUD.

## Acceptance Criteria

- [x] When Head Lamp is equipped: controls panel shows "[F] Headlamp" (or currently mapped key)
- [x] When Head Lamp is not equipped: headlamp entry is absent from the controls panel
- [x] Key label resolves dynamically via InputMap (updates if player remaps the action)
- [x] Toggling headlamp via the key continues to work as before (no regression to M5 implementation)
- [x] Unit tests cover: controls panel entry present when equipped, absent when not equipped, key label reflects current mapping
- [x] Full test suite passes

## Implementation Notes

- The controls panel was implemented in TICKET-0120 (M7) — follow the same pattern used for existing controls entries (Q: Ping, I: Inventory)
- Headlamp input action should already exist from M5 — verify it is registered in InputMap before adding the HUD entry
- If the action is not registered, register it as part of this ticket

## Handoff Notes

- **Modified:** `game/scripts/ui/interaction_prompt_hud.gd` — added headlamp control row logic (dynamic creation, InputMap key resolution, per-frame refresh)
- **Created:** `game/tests/test_interaction_prompt_hud_unit.gd` — 7 unit tests covering presence/absence, key label, remap, edge cases
- **No scene changes** — HeadLampRow is created programmatically matching PingRow/InventoryRow style
- **No regression** to M5 headlamp toggle (`toggle_head_lamp` action and `HeadLamp` autoload untouched)
- **Known limitation:** UID sidecar file for new test script pending Godot filesystem scan

## Activity Log

- 2026-02-27 [producer] Created — M8 Gameplay phase
- 2026-02-27 [gameplay-programmer] Starting work — IN_PROGRESS
- 2026-02-27 [gameplay-programmer] DONE — merge commit dfaf6b6, PR https://github.com/sqlhammer/Hammer-Forge-Studio/pull/142
