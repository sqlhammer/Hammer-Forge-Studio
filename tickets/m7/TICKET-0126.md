---
id: TICKET-0126
title: "Ship interior scene — 24m×12m layout with cockpit, machine room, corridors, vestibule, 4 module zones"
type: FEATURE
status: TODO
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-26
updated_at: 2026-02-26
milestone: "M7"
phase: "Build & Features"
depends_on: [TICKET-0123, TICKET-0113, TICKET-0124]
blocks: [TICKET-0127, TICKET-0128]
tags: [ship-interior, cockpit, machine-room, scene-build, gameplay]
---

## Summary

Rebuild the ship interior from the M4 greybox single-bay layout (12m × 8m) into the full multi-room layout (~24m × 12m) as defined in the M7 wireframes (TICKET-0123). The new interior has four distinct areas:

1. **Cockpit** — forward room containing the navigation console placeholder (TICKET-0124), with space for diegetic status displays and a viewport/window
2. **Machine Room** — primary module workspace with 4 placement zones (3m × 3m each). Three zones are pre-occupied by the refactored Recycler, Fabricator, and Automation Hub scenes (from TICKET-0113). One zone is empty/spare.
3. **Connecting Corridor** — hallway linking cockpit to machine room
4. **Entry Vestibule** — transition space from exterior to interior, replacing the M4 entry corridor

## Key Requirements

- **Total footprint:** ~24m × 12m (exact dimensions per TICKET-0123 wireframe)
- **Ceiling height:** 3m
- **Module zones:** 4 zones, each 3m × 3m with `Area3D` trigger volumes and interact points
- **Walking clearance:** Minimum 2m between any obstacles/walls throughout the layout
- **Art style:** Greybox — CSGBox3D or MeshInstance3D with placeholder materials (same palette as M4)
- **Entry/exit:** Fade-to-black transition (300ms each way), spawn points via `Marker3D` nodes
- **Cockpit console:** Instance `cockpit_console.tscn` (from TICKET-0124) in the cockpit room
- **Machine instances:** Instance the refactored standalone machine scenes (from TICKET-0113) in their respective module zones

## Scene Structure

```
ship_interior.tscn (Node3D root)
├── Geometry/
│   ├── CockpitWalls (CSGBox3D nodes)
│   ├── CorridorWalls (CSGBox3D nodes)
│   ├── MachineRoomWalls (CSGBox3D nodes)
│   ├── VestibuleWalls (CSGBox3D nodes)
│   ├── Floor (CSGBox3D)
│   └── Ceiling (CSGBox3D)
├── Cockpit/
│   ├── CockpitConsole (instanced cockpit_console.tscn)
│   ├── ViewportArea (Marker3D — position for TICKET-0128)
│   └── StatusDisplayArea (Marker3D — position for TICKET-0127)
├── MachineRoom/
│   ├── ModuleZoneA (Area3D — occupied by Recycler)
│   ├── ModuleZoneB (Area3D — occupied by Fabricator)
│   ├── ModuleZoneC (Area3D — occupied by Automation Hub)
│   └── ModuleZoneD (Area3D — empty/spare)
├── EntryVestibule/
│   ├── EntryTrigger (Area3D)
│   ├── InteriorSpawn (Marker3D)
│   └── ExteriorSpawn (Marker3D)
└── Lighting/
    └── (Uniform greybox lighting — OmniLight3D or DirectionalLight3D)
```

## Entry/Exit Flow

Reuse the M4 entry/exit system with updated spawn positions:
1. Player approaches ship exterior → interact prompt → fade-to-black → spawn at InteriorSpawn (vestibule), facing into the ship
2. Player walks to vestibule exit trigger → interact prompt → fade-to-black → spawn at ExteriorSpawn (outside ship)
3. Ship globals HUD activates on entry, deactivates on exit (same as M4)

## Acceptance Criteria

- [ ] `game/scenes/gameplay/ship_interior.tscn` rebuilt with ~24m × 12m layout
- [ ] Cockpit room exists with instanced console and marker positions for status displays/viewport
- [ ] Machine room has 4 module placement zones as `Area3D` nodes
- [ ] Three zones occupied by instanced Recycler, Fabricator, and Automation Hub scenes
- [ ] One zone empty with floor marking (emissive teal, 30% opacity)
- [ ] Connecting corridor links cockpit to machine room with minimum 2m clearance
- [ ] Entry vestibule with functional enter/exit transitions
- [ ] Greybox materials throughout (M4 palette)
- [ ] Uniform lighting — functional visibility, no mood lighting
- [ ] Player can walk through all areas without collision issues
- [ ] Ship globals HUD activates/deactivates correctly on entry/exit
- [ ] Module interact points work for all three placed machines
- [ ] Scene runs without errors in the editor
- [ ] All code follows `docs/engineering/coding-standards.md`

## Implementation Notes

- Replace the existing `ship_interior.tscn` — do not create a parallel scene
- The machine scenes from TICKET-0113 should be instanced (not duplicated) into the module zones
- Keep the module placement system from M4 functional — the catalog/install mechanic should still work for the spare zone
- The cockpit is a room shell only in this ticket — functional elements (status displays, viewport) are separate tickets (TICKET-0127, TICKET-0128)

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-26 [producer] Created ticket — ship interior scene rebuild
