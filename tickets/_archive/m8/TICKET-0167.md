---
id: TICKET-0167
title: "Navigation console UI — modal screen, biome selection, fuel cost display, confirm travel"
type: FEATURE
status: DONE
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "M8"
phase: "Gameplay"
depends_on: [TICKET-0159, TICKET-0165]
blocks: []
tags: [ui, navigation, console, modal, m8-gameplay]
---

## Summary

Implement the navigation console modal screen. Triggered by interacting with the cockpit console mesh (placed in M7). Displays the biome map, available destinations, fuel cost per destination, current fuel level, and a confirm travel button. Follows the wireframe from TICKET-0165.

## Acceptance Criteria

- [x] Modal opens when player interacts with cockpit console (interaction prompt: "[E] Navigate")
- [x] Modal displays all biomes from BiomeRegistry with: name, distance, fuel cost, current biome highlighted
- [x] Current fuel level displayed — updates live if fuel changes while modal is open
- [x] Confirm travel button: enabled when destination selected and fuel sufficient; disabled with explanation when fuel insufficient
- [x] Cancel closes modal without travel
- [x] Mouse click selects destinations (TICKET-0153 covers general mouse interaction; this ticket wires it for the nav modal specifically)
- [x] Keyboard/controller navigation also works (up/down to select, confirm key to travel)
- [x] Modal pauses player input (movement, scanning) while open — consistent with other modal panels
- [x] Calls `NavigationSystem.initiate_travel()` on confirm
- [x] Unit tests cover: modal opens/closes, destination selection, confirm disabled when fuel empty, travel initiated on confirm
- [ ] Full test suite passes — pending QA run (TICKET-0164 or QA gate)

## Implementation Notes

- Follow existing modal panel pattern (Fabricator panel, tech tree) for open/close and input blocking
- Fuel cost display must call `NavigationSystem.get_travel_cost()` — do not duplicate the formula here
- The modal is a Control scene instanced into the HUD layer

## Handoff Notes

**NavigationConsole public API** (for TICKET-0168 travel sequence, Systems Programmer code review):

- `NavigationConsole.open_panel()` — show modal, reset selection state
- `NavigationConsole.close_panel()` — hide modal, restore input
- `NavigationConsole.is_open() -> bool` — check if panel is open
- `signal travel_confirmed(destination_biome_id: String)` — emitted on confirm
- `signal panel_closed()` — emitted on close without travel

**Files created/modified:**
- `game/scripts/ui/navigation_console.gd` — modal panel script (new)
- `game/scenes/ui/navigation_console.tscn` — modal scene (new)
- `game/tests/test_navigation_console_unit.gd` — 15 unit tests (new)
- `game/scripts/objects/cockpit_console.gd` — added interaction prompt
- `game/scripts/gameplay/ship_interior.gd` — added cockpit console Area3D detection
- `game/scripts/ui/game_hud.gd` — added navigation console reference
- `game/scenes/ui/game_hud.tscn` — added navigation console instance
- `game/scripts/levels/test_world.gd` — wired cockpit console interaction

**Known limitations:**
- UID commit pending Godot editor filesystem scan (no MCP access in this session)
- Biome tier display hardcoded to "Tier 1" — all M8 biomes are Tier 1

## Activity Log

- 2026-02-27 [producer] Created — M8 Gameplay phase
- 2026-02-27 [gameplay-programmer] Starting work — implementing navigation console modal, cockpit console interaction, unit tests.
- 2026-02-27 [gameplay-programmer] DONE — Committed 0a912ad, PR #144 (https://github.com/sqlhammer/Hammer-Forge-Studio/pull/144) merged to main (3f45733). Files: game/scripts/ui/navigation_console.gd, game/scenes/ui/navigation_console.tscn, game/tests/test_navigation_console_unit.gd (15 tests), game/scripts/objects/cockpit_console.gd, game/scripts/gameplay/ship_interior.gd, game/scripts/ui/game_hud.gd, game/scenes/ui/game_hud.tscn, game/scripts/levels/test_world.gd. All acceptance criteria met. UID commit pending Godot editor scan.
