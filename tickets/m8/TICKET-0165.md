---
id: TICKET-0165
title: "UI/UX — navigation console modal, biome map, fuel gauge HUD designs"
type: DESIGN
status: IN_PROGRESS
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

- [ ] **Navigation console modal wireframe:**
  - Full-screen modal (consistent with Fabricator/tech tree panel pattern)
  - Biome map — top-down abstract representation of available biomes with the current location highlighted
  - Each biome entry shows: name, distance, estimated fuel cost, available/locked state
  - Confirm travel button — disabled when fuel insufficient, shows reason
  - Cancel / close button
  - Follows existing UI style guide (color palette, typography, panel borders)
- [ ] **Fuel gauge HUD element:**
  - Persistent display showing current fuel level as a bar or numeric readout
  - Low-fuel warning state (visual change at ≤25% — consistent with battery amber warning pattern)
  - Empty state (distinct visual when fuel = 0)
  - Positioned consistently with existing HUD layout (does not overlap compass, battery, or other elements)
- [ ] Wireframes exported/saved to `docs/art/wireframes/m8/`
- [ ] UI style guide updated if any new patterns are introduced

## Implementation Notes

- The navigation console is a modal triggered by interacting with the cockpit console mesh (placed in M7)
- Fuel gauge should feel related to the battery bar — same visual language, different resource
- Biome map does not need to be geographically accurate — abstract node graph is sufficient for M8 greybox

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created — M8 Foundation phase
- 2026-02-27 [ui-ux-designer] Starting work — authoring navigation console modal wireframe and fuel gauge HUD wireframe
