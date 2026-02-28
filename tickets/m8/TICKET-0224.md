---
id: TICKET-0224
title: "Bugfix — Mining interaction prompt shows 'E' but PC uses mouse button"
type: BUGFIX
status: IN_PROGRESS
priority: P2
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-28
updated_at: 2026-02-28
milestone: "M8"
phase: "QA"
depends_on: []
blocks: []
tags: [bugfix, interaction-prompt, mining, input, hud, m8-qa]
---

## Summary

When the player aims at an analyzed deposit, the interaction prompt HUD displays a static "E" key for the Mine action. On PC, mining is triggered by holding the mouse button (the `use_tool` action), not E. The prompt is showing the wrong key.

## Steps to Reproduce

1. Launch any biome and analyze a deposit with the scanner
2. Aim at the analyzed deposit
3. Observe: the interaction prompt shows `[E] Mine`
4. Attempt to press E — nothing happens; the player must hold the mouse button to mine

## Expected Behavior

The interaction prompt displays the actual key bound to the `use_tool` action for the active input device. On PC this is the mouse button, not E.

## Acceptance Criteria

- [ ] The Mine interaction prompt shows the key/button currently bound to `use_tool` via `InputManager`
- [ ] Prompt updates correctly if the player switches input device (keyboard/gamepad)
- [ ] Other interaction prompts are not affected
- [ ] Full test suite passes with no new failures

## Implementation Notes

- Root cause is in `deposit.gd` `get_interaction_prompt()` — line 141 returns a hardcoded `{"key": "E", "label": "Mine", "hold": false}` instead of querying the actual binding
- Fix: query `InputManager` for the display name of the `use_tool` action (e.g., `InputManager.get_action_display_name("use_tool")`) and use that as the `"key"` value; the existing interaction prompt rendering pipeline already handles variable key names for other actions
- Set `"hold": true` since mining requires holding the button, not tapping it — this also fixes the prompt implying a tap interaction

## Activity Log

- 2026-02-28 [producer] Created — Studio Head reported during M8 playtest (see screenshot)
- 2026-02-28 [gameplay-programmer] Starting work — fixing hardcoded key in deposit.gd get_interaction_prompt()
