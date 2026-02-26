---
id: TICKET-0123
title: "Ship interior wireframes — cockpit, machine room, corridors, entry vestibule, viewport spec"
type: DESIGN
status: DONE
priority: P1
owner: ui-ux-designer
created_by: producer
created_at: 2026-02-26
updated_at: 2026-02-26
milestone: "M7"
phase: "Foundation"
depends_on: []
blocks: [TICKET-0126]
tags: [design, wireframe, ship-interior, cockpit, machine-room]
---

## Summary

Design the full ship interior layout for the expanded ~24m × 12m footprint. The M4 greybox interior (12m × 8m single bay) is being replaced with a multi-room layout consisting of four distinct areas:

1. **Cockpit** — forward room with navigation console placeholder, diegetic ship status displays (Power, Integrity, Heat, O2), and an exterior viewport/window
2. **Machine Room** — primary module workspace with 4 placement zones (3 occupied: Recycler, Fabricator, Automation Hub; 1 spare for future modules)
3. **Connecting Corridor** — hallway between cockpit and machine room
4. **Entry Vestibule** — transition space from exterior to interior (replaces the M4 entry corridor)

This wireframe must define spatial dimensions, walking paths, module zone positions, cockpit furniture placement, viewport position/size, and all interact points.

## Design Constraints

- **Total footprint:** ~24m × 12m (Godot units)
- **Ceiling height:** 3m (same as M4)
- **Module zones:** 4 zones, each 3m × 3m (same zone size as M4)
- **Walking clearance:** Minimum 2m between any obstacles/walls
- **Art style:** Greybox — placeholder materials only (same as M4 wireframe spec)
- **Viewport:** The cockpit must include a window/viewport area showing the exterior world. Specify position, size, and whether it's a `SubViewport` or a transparent mesh opening.
- **Console:** A non-functional placeholder position for the navigation console (to be wired up in M8)
- **Status displays:** Wall-mounted panels showing ship globals (Power, Integrity, Heat, O2) — specify position, size, and arrangement

## Reference Documents

- M4 ship interior wireframe: `docs/design/wireframes/m4/ship-interior-layout.md`
- Mobile base design spec: `docs/design/systems/mobile-base.md`
- Ship globals HUD wireframe: `docs/design/wireframes/m4/ship-globals-hud.md`
- UI style guide: `docs/design/ui-style-guide.md`

## Acceptance Criteria

- [x] Wireframe document created at `docs/design/wireframes/m7/ship-interior-layout.md`
- [x] Top-down floor plan showing all four areas with dimensions
- [x] Module zone positions specified with coordinates relative to scene origin
- [x] Cockpit layout showing console position, status display positions, and viewport position/size
- [x] Entry/exit flow documented (vestibule trigger zones, spawn points)
- [x] Walking clearance verified — no path narrower than 2m
- [x] Implementation notes for scene structure (node types, hierarchy)
- [x] All design follows `docs/engineering/coding-standards.md`

## Implementation Notes

- Output location: `docs/design/wireframes/m7/ship-interior-layout.md`
- Reference the M4 wireframe for format and style conventions
- The viewport implementation approach (SubViewport vs transparent opening) should be specified clearly for the gameplay-programmer
- Consider future expansion: the machine room should be designed so additional module zones can be added in later milestones without restructuring

## Handoff Notes

Wireframe at `docs/design/wireframes/m7/ship-interior-layout.md`. Key decisions for TICKET-0126 (gameplay-programmer):
- **24m × 12m** total footprint. Coordinate origin at interior center; Y=0 floor, Z-negative is north/cockpit.
- **4 module zones** in a 2×2 grid in the machine room. All zone coordinates in the Zone Coordinates table.
- **Viewport:** transparent hull cutout (not SubViewport). Implement as a gap in the north cockpit wall geometry with a thin frame mesh border.
- **Status displays:** `SubViewport` textures on `MeshInstance3D` panels, reusing ship globals HUD bar nodes.
- **Scene root:** `Node3D` instanced scene at `res://game/scenes/gameplay/ship_interior.tscn`.
- Console and cockpit features are built in TICKET-0127 and TICKET-0128 — this wireframe defines their positions.

## Activity Log
- 2026-02-26 [producer] Created ticket — M7 ship interior wireframes
- 2026-02-26 [ui-ux-designer] Completed wireframe — all acceptance criteria met. Wireframe at docs/design/wireframes/m7/ship-interior-layout.md
