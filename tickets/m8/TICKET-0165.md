---
id: TICKET-0165
title: "UI/UX — navigation console modal, biome map, fuel gauge HUD designs"
type: DESIGN
status: DONE
priority: P1
owner: ui-ux-designer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "M8"
phase: "Foundation"
depends_on: []
blocks: []
tags: [ui, ux, design, navigation, fuel, hud, m8-foundation]
---

## Summary

Design the modal navigation console screen, the biome map within it, and the persistent fuel gauge HUD element. These designs gate the navigation console UI implementation (TICKET-0167) and fuel HUD (TICKET-0169).

## Acceptance Criteria

- [x] **Navigation console modal wireframe:**
  - Full-screen modal (consistent with Fabricator/tech tree panel pattern)
  - Biome map — top-down abstract representation of available biomes with the current location highlighted
  - Each biome entry shows: name, distance, estimated fuel cost, available/locked state
  - Confirm travel button — disabled when fuel insufficient, shows reason
  - Cancel / close button
  - Follows existing UI style guide (color palette, typography, panel borders)
- [x] **Fuel gauge HUD element:**
  - Persistent display showing current fuel level as a bar or numeric readout
  - Low-fuel warning state (visual change at ≤25% — consistent with battery amber warning pattern)
  - Empty state (distinct visual when fuel = 0)
  - Positioned consistently with existing HUD layout (does not overlap compass, battery, or other elements)
- [x] Wireframes exported/saved to `docs/art/wireframes/m8/`
- [x] UI style guide updated if any new patterns are introduced

## Implementation Notes

- The navigation console is a modal triggered by interacting with the cockpit console mesh (placed in M7)
- Fuel gauge should feel related to the battery bar — same visual language, different resource
- Biome map does not need to be geographically accurate — abstract node graph is sufficient for M8 greybox

## Handoff Notes

### For TICKET-0167 (Gameplay Programmer — Navigation Console UI)

See `docs/art/wireframes/m8/navigation-console-modal.md` for full spec.

**Exported properties required:**
| Property / Signal | Type | Purpose |
|-------------------|------|---------|
| `@export var navigation_system: NavigationSystem` | Node ref | Biome registry, distances, travel state |
| `@export var fuel_system: FuelSystem` | Node ref | Current fuel level, cost calculations |
| `signal travel_confirmed(destination_biome_id: String)` | Signal | Emitted when player presses CONFIRM TRAVEL |
| `signal panel_closed()` | Signal | Emitted when dismissed without travel |
| `func open_panel()` | Method | Show panel, reset to no-selection state |
| `func close_panel()` | Method | Hide panel, restore input handling |

**Key implementation notes:**
- CanvasLayer layer 2; non-pause model (game time continues, InputManager suppresses gameplay inputs)
- Biome map uses manual node layout inside a `Control` container (not auto-layout)
- Reactive detail panel: map nodes emit `biome_selected(biome_id)`, detail panel updates on that signal
- CONFIRM TRAVEL disabled reason label ("Need X more Fuel Cell(s)") shown below button when insufficient

---

### For TICKET-0169 (Gameplay Programmer — Fuel Consumption HUD)

See `docs/art/wireframes/m8/fuel-gauge-hud.md` for full spec.

**Exported properties required:**
| Property / Signal | Type | Purpose |
|-------------------|------|---------|
| `@export var fuel_system: FuelSystem` | Node ref | Current fuel level and max capacity |
| `func set_fuel_level(current: float, maximum: float)` | Method | Called by fuel system to update display |

**Key implementation notes:**
- Anchored `bottom_center`, 32px from bottom edge
- Reuses battery bar `ProgressBar` theme; state colors via `theme_override_colors`
- States: Full (green) / Normal (teal) / Low ≤25% (amber, pulse) / Empty (coral, flash)
- Pulse + flash via `Tween` — create on state entry, kill on state exit

## Activity Log

- 2026-02-27 [producer] Created — M8 Foundation phase
- 2026-02-27 [ui-ux-designer] Starting work — authoring navigation console modal wireframe and fuel gauge HUD wireframe
- 2026-02-27 [ui-ux-designer] DONE — commit aa9dabf, PR #128 (https://github.com/sqlhammer/Hammer-Forge-Studio/pull/128) merged to main. Wireframes delivered: docs/art/wireframes/m8/navigation-console-modal.md and docs/art/wireframes/m8/fuel-gauge-hud.md. Style guide updated with Resource Gauge and Biome Node Map patterns.
