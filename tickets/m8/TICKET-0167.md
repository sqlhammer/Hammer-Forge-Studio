---
id: TICKET-0167
title: "Navigation console UI — modal screen, biome selection, fuel cost display, confirm travel"
type: FEATURE
status: PENDING
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

- [ ] Modal opens when player interacts with cockpit console (interaction prompt: "[E] Navigate")
- [ ] Modal displays all biomes from BiomeRegistry with: name, distance, fuel cost, current biome highlighted
- [ ] Current fuel level displayed — updates live if fuel changes while modal is open
- [ ] Confirm travel button: enabled when destination selected and fuel sufficient; disabled with explanation when fuel insufficient
- [ ] Cancel closes modal without travel
- [ ] Mouse click selects destinations (TICKET-0153 covers general mouse interaction; this ticket wires it for the nav modal specifically)
- [ ] Keyboard/controller navigation also works (up/down to select, confirm key to travel)
- [ ] Modal pauses player input (movement, scanning) while open — consistent with other modal panels
- [ ] Calls `NavigationSystem.initiate_travel()` on confirm
- [ ] Unit tests cover: modal opens/closes, destination selection, confirm disabled when fuel empty, travel initiated on confirm
- [ ] Full test suite passes

## Implementation Notes

- Follow existing modal panel pattern (Fabricator panel, tech tree) for open/close and input blocking
- Fuel cost display must call `NavigationSystem.get_travel_cost()` — do not duplicate the formula here
- The modal is a Control scene instanced into the HUD layer

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created — M8 Gameplay phase
