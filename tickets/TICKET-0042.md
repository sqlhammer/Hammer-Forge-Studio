---
id: TICKET-0042
title: "UI/UX — ship globals HUD, ship stats sidebar, Recycler panel, interior wireframes"
type: DESIGN
status: DONE
priority: P1
owner: ui-ux-designer
created_by: producer
created_at: 2026-02-23
updated_at: 2026-02-23
milestone: "M4"
milestone_gate: "M3"
depends_on: []
blocks: [TICKET-0045, TICKET-0046, TICKET-0047]
tags: [ui, ux, design, wireframes]
---

## Summary
Produce wireframes for all new M4 UI surfaces: ship global variable indicators (inside-ship HUD), ship stats sidebar on the inventory screen, Recycler interaction panel, and the minimal greybox ship interior layout. Gameplay programmers block on these wireframes before implementing UI tickets.

## Acceptance Criteria
- [x] Ship globals HUD display — Power, Integrity, Heat, Oxygen indicators shown when player is inside the ship; layout does not conflict with existing battery bar and compass
- [x] Ship stats sidebar — compact view of all four global variables appended to the existing inventory screen; visible when player is outside the ship
- [x] Recycler panel — input slot (resource to process), output slot (processed resource), single active job display with progress indicator, collect button
- [x] Greybox ship interior layout — floor plan showing walkable area, module placement zone(s), entry/exit point, and approximate dimensions
- [x] All wireframes consistent with the M3 UI style guide (`docs/design/ui-style-guide.md`)
- [x] Wireframes delivered and reviewed before Gameplay phase tickets begin

## Implementation Notes
- Reference M3 HUD layout to avoid element conflicts — battery bar is top-left, compass is top-center
- The inventory screen already exists (TICKET-0028) — the ship stats sidebar is an additive change, not a redesign
- Recycler panel interaction model: player opens panel via interact input, navigates with standard UI controls, closes with cancel input
- Interior layout is greybox only — no art direction needed in M4, just spatial planning for placement zones

## Handoff Notes

### Wireframe Deliverables

All wireframes at `docs/design/wireframes/m4/`:

| Wireframe | File | Blocks |
|-----------|------|--------|
| Ship Globals HUD | `ship-globals-hud.md` | TICKET-0046 |
| Ship Stats Sidebar | `ship-stats-sidebar.md` | TICKET-0047 |
| Recycler Panel | `recycler-panel.md` | TICKET-0045 |
| Ship Interior Layout | `ship-interior-layout.md` | TICKET-0043 |

### Key Design Decisions

1. **Ship globals HUD position:** Bottom-right (opposite battery bar at bottom-left). Avoids all conflict with existing M3 HUD elements.
2. **Ship stats sidebar:** Attached flush to the right side of the inventory panel. Combined width 760px (580 inventory + 180 sidebar), centered as one unit. Includes an ALERTS summary section.
3. **Recycler panel:** Full-screen overlay (same pattern as inventory). Mini-picker for input selection filters to valid recipes only. Ghost icon shows expected output during processing.
4. **Ship interior:** 12m x 8m main bay with 2m x 3m entry corridor. Two 3m x 3m module placement zones. Interact-to-enter and interact-to-exit (no auto-transition). Fade-to-black scene transition.
5. **Heat bar:** Dual-range indicator — both 0% (freezing) and 100% (overheating) are dangerous. Tick marks at 25%/75% show safe zone.

### For Gameplay Programmer

- All wireframes reference signals from `ShipState` autoload and `Recycler` module
- Ship globals HUD and sidebar use identical icon set and color thresholds — shared constants recommended
- Recycler panel reuses the inventory slot pattern from M3 where possible
- Entry/exit uses `Area3D` trigger zones — same interact pattern as M3 scanner/mining

## Activity Log
- 2026-02-23 [producer] Created ticket
- 2026-02-23 [ui-ux-designer] Status → IN_PROGRESS. Prerequisite check passed: M3 complete, no depends_on. Beginning wireframe design.
- 2026-02-23 [ui-ux-designer] All 4 wireframes complete. Ship globals HUD (bottom-right), ship stats sidebar (inventory addon), Recycler panel (full overlay), ship interior layout (12x8m bay, 2 module zones). Status → DONE.
