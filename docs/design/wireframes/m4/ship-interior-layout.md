# Wireframe: Greybox Ship Interior Layout

**Component:** Ship Interior Floor Plan
**Ticket:** TICKET-0042
**Blocks:** TICKET-0043 (Greybox ship interior scene)
**Last Updated:** 2026-02-23

---

## Purpose

Spatial plan for the greybox ship interior that the player can walk through in first-person. Defines the walkable area, module placement zone(s), entry/exit point, and approximate dimensions. This is a greybox layout — no art direction, just functional spatial planning for M4.

---

## Design Intent

The ship interior for M4 is deliberately minimal. The player needs:
1. A space to enter and exit
2. A place to install the Recycler module
3. Enough room to walk to the module and interact with it
4. A sense that this space can grow (module placement zones hint at future expansion)

This is NOT the final ship interior. M6 (Ship Interior) will define the full cockpit and machine room. M4 establishes the shell.

---

## Dimensions

| Property | Value | Notes |
|----------|-------|-------|
| **Total interior footprint** | 12m x 8m (Godot units) | Roughly the size of a small apartment |
| **Ceiling height** | 3m | Comfortable first-person scale |
| **Entry corridor** | 2m x 3m | Transition from exterior to interior |
| **Main bay** | 10m x 8m | Primary walkable and buildable space |
| **Module placement zone** | 3m x 3m (x2 zones) | Floor-marked areas for module installation |

---

## Floor Plan (Top-Down View)

```
    North (toward ship nose)
    ▲
    │
    ┌────────────────────────────────────────────────────┐
    │                                                     │
    │                    MAIN BAY                         │
    │               (10m x 8m walkable)                   │
    │                                                     │
    │   ┌ ─ ─ ─ ─ ─ ┐         ┌ ─ ─ ─ ─ ─ ┐            │
    │   │  MODULE    │         │  MODULE    │            │
    │   │  ZONE A    │         │  ZONE B    │            │
    │   │  3m x 3m   │         │  3m x 3m   │            │
    │   │             │         │             │            │
    │   └ ─ ─ ─ ─ ─ ┘         └ ─ ─ ─ ─ ─ ┘            │
    │                                                     │
    │        ○ Interact point        ○ Interact point     │
    │        (front of zone)         (front of zone)      │
    │                                                     │
    │                                                     │
    │                    ┌─────────┐                      │
    │                    │  ENTRY  │                      │
    │                    │ CORRIDOR│                      │
    │                    │ 2m x 3m │                      │
    │                    │         │                      │
    │                    │    ▼    │                      │
    │                    │  EXIT   │                      │
    │                    └─────────┘                      │
    │                                                     │
    └────────────────────────────────────────────────────┘
    South (toward ship ramp / exterior)

    Legend:
    ┌───┐  Solid walls
    ┌ ─ ┐  Module placement zone (floor marking, dashed boundary)
    ○      Interact point (player stands here to interact with placed module)
    ▼      Entry/exit direction (ramp to exterior)
```

---

## Zone Details

### Entry Corridor

- **Size:** 2m wide x 3m deep
- **Purpose:** Transition space between exterior and interior
- **Features:**
  - Ramp or doorway connecting to exterior ship mesh
  - Collision boundary that triggers `player_entered_ship` / `player_exited_ship` signals
  - Trigger zone at the midpoint: crossing inward activates in-ship HUD, crossing outward deactivates it
- **Greybox:** Simple box geometry, slightly narrower than the main bay to create a sense of entering

### Main Bay

- **Size:** 10m wide x 8m deep
- **Purpose:** Primary walkable and buildable space
- **Features:**
  - Flat floor, box walls, flat ceiling — pure greybox
  - Ambient lighting (uniform, no dramatic shadows — functional)
  - Two module placement zones on the floor
  - Clear walking paths between zones and to the entry corridor
- **Walking clearance:** Minimum 2m between any two obstacles or walls for comfortable first-person navigation

### Module Placement Zones

- **Size:** 3m x 3m each
- **Count:** 2 zones in M4 (expandable in future milestones)
- **Position:** Left and right sides of the main bay, set back from the entry corridor
- **Visual marking:** Dashed line rectangle on the floor (emissive teal `#00D4AA` at 30% opacity)
- **Interact point:** Centered on the front edge (south side) of each zone, 0.5m out from the zone boundary
- **State when empty:** Floor marking visible, interact prompt shows "Press [E] to install module" when player is within 2m of the interact point
- **State when occupied:** Placed module mesh sits within the zone boundaries. Floor marking dims to 15% opacity. Interact prompt shows "Press [E] to use [Module Name]"

### Placement Zone Positioning

```
    ┌──────────────────────────────────────────────┐
    │                                               │
    │  2m     ┌ ─ ─ ─ ┐  2m gap  ┌ ─ ─ ─ ┐  2m   │
    │  wall   │ ZONE A │ ◄─────► │ ZONE B │  wall  │
    │  gap    │ 3x3    │         │ 3x3    │  gap   │
    │         └ ─ ─ ─ ┘         └ ─ ─ ─ ┘         │
    │                                               │
    │         Zone A center: (-2.5, 0, -1)          │
    │         Zone B center: ( 2.5, 0, -1)          │
    │                                               │
    │  (coordinates relative to bay center,         │
    │   Y=0 is floor, Z negative is north)          │
    └──────────────────────────────────────────────┘
```

- **Gap between zones:** 2m — enough for comfortable walking
- **Gap from walls:** 2m on each side — prevents claustrophobic feel
- **Gap from entry corridor:** ~3m — player has space to orient after entering

---

## Entry/Exit Flow

### Entering the Ship

1. Player approaches ship exterior (existing ship mesh from M3 greybox world)
2. Interact prompt appears near the ship ramp/door: "Press [E] to enter ship"
3. Player presses interact
4. Transition: Brief fade-to-black (300ms) then fade-in (300ms) — player spawns at the entry corridor interior, facing north into the main bay
5. Ship globals HUD activates (see `ship-globals-hud.md`)
6. Battery bar and compass remain visible

### Exiting the Ship

1. Player walks back to the entry corridor
2. At the exit trigger zone, interact prompt appears: "Press [E] to exit ship"
3. Player presses interact
4. Transition: Fade-to-black (300ms) then fade-in (300ms) — player spawns outside the ship at the ramp location, facing away from the ship
5. Ship globals HUD deactivates

**Alternative:** The exit could be automatic (walk through the trigger) instead of requiring an interact press. Recommend interact-to-exit for consistency and to prevent accidental exits.

---

## Greybox Material Spec

All surfaces use placeholder materials — no textures, no UV work:

| Surface | Color | Material |
|---------|-------|----------|
| **Floor** | Medium grey `#4A4A4A` | `StandardMaterial3D`, roughness 0.8 |
| **Walls** | Dark grey `#333333` | `StandardMaterial3D`, roughness 0.9 |
| **Ceiling** | Dark grey `#2A2A2A` | `StandardMaterial3D`, roughness 0.9 |
| **Module zone floor marking** | Teal `#00D4AA` at 30% | Emissive outline on floor (shader or overlay mesh) |
| **Entry corridor** | Slightly lighter grey `#555555` | Distinguishes corridor from main bay |

### Lighting

- **Type:** Single `OmniLight3D` or `DirectionalLight3D` — uniform, shadowless
- **Color:** Neutral white `#E0E0E0`
- **Purpose:** Functional visibility only — no mood lighting in greybox phase

---

## Collision & Navigation

- All walls, floor, and ceiling have `StaticBody3D` colliders
- Floor is flat — no steps, no ramps inside (ramp is only at entry/exit)
- Player uses existing first-person controller from M1/M3
- No special movement modifications inside the ship (same speed, same controls)

---

## Future Expansion Notes

- M6 (Ship Interior) will split the main bay into a cockpit area and a machine room
- Module zone count will increase as hull tier upgrades are implemented (OQ-008)
- The entry corridor will eventually lead to a proper airlock or ramp with animation
- Diegetic HUD elements (screens, readouts on walls) are deferred to M6+
- These wireframes are for spatial planning ONLY — art direction comes in M8

---

## Implementation Notes

- Scene root: `Node3D` (ship interior scene, instanced when player enters)
- Walls/floor/ceiling: `CSGBox3D` nodes for rapid greybox construction (or `MeshInstance3D` with box meshes)
- Module zones: `Area3D` nodes with `CollisionShape3D` (box shape, 3x0.1x3) as trigger volumes
- Entry/exit trigger: `Area3D` at corridor midpoint, connected to scene transition logic
- Interact points: Reuse existing interact system from M3 (scanner/mining interact pattern)
- Player spawn points: `Marker3D` nodes at entry (interior) and exit (exterior) positions
- Ship globals HUD show/hide: Triggered by the entry/exit `Area3D` body_entered/body_exited signals
