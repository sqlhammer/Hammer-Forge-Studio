# Wireframe: M7 Ship Interior Layout

**Component:** Ship Interior — Cockpit, Machine Room, Corridor, Entry Vestibule
**Ticket:** TICKET-0123
**Blocks:** TICKET-0126 (Ship interior scene — 24m×12m build)
**Last Updated:** 2026-02-26

---

## Purpose

Spatial plan for the expanded M7 ship interior. Replaces the M4 greybox interior (12m × 8m single bay)
with a fully realized multi-room layout across a ~24m × 12m footprint. Four distinct areas:

1. **Entry Vestibule** — transition space from exterior to interior (south end)
2. **Machine Room** — primary module workspace with 4 placement zones
3. **Connecting Corridor** — hallway between machine room and cockpit
4. **Cockpit** — forward command area with navigation console, diegetic status displays, and exterior viewport

This is a greybox layout — no art direction. Functional spatial planning for M7.

---

## Coordinate System

| Axis | Range | Notes |
|------|-------|-------|
| **X** | −6 to +6 | West (−) to East (+) |
| **Y** | 0 to 3 | Floor (0) to ceiling (3m) |
| **Z** | −12 to +12 | North/cockpit (−12) to South/entry (+12) |

**Origin:** Center of total interior footprint. Y = 0 is floor. Z negative is north (toward cockpit).

---

## Room Summary

| Room | Width (X) | Depth (Z) | Z Range | Area |
|------|-----------|-----------|---------|------|
| **Cockpit** | 12m | 6m | −12 to −6 | 72 m² |
| **Connecting Corridor** | 4m | 2m | −6 to −4 | 8 m² |
| **Machine Room** | 12m | 12m | −4 to +8 | 144 m² |
| **Entry Vestibule** | 4m | 4m | +8 to +12 | 16 m² |
| **Total footprint** | 12m | 24m | −12 to +12 | 240 m² |

---

## Floor Plan (Top-Down View)

```
    North (cockpit / ship nose)
    ▲
    │
    ╔══════════════════════════════════════════════════════════════╗
    ║                         COCKPIT                             ║
    ║                        (12m × 6m)                           ║
    ║                                                             ║
    ║  [PWR]  [INT]   ╔══════════════════╗   [HET]  [OXY]        ║
    ║  West wall       ║    VIEWPORT       ║   East wall           ║
    ║  displays        ║    4m × 1.5m      ║   displays            ║
    ║                  ╚══════════════════╝                       ║
    ║              ┌───────────────────────┐                      ║
    ║              │  NAV CONSOLE (2m×0.8m)│                      ║
    ║              └───────────────────────┘                      ║
    ║                                                             ║
    ╠══════════╦══════════════════════════════╦═══════════════════╣
    ║          ║     CONNECTING CORRIDOR      ║                   ║
    ║  (wall)  ║          (4m × 2m)           ║     (wall)        ║
    ║          ╚══════════════════════════════╝                   ║
    ╠═════════════════════════════════════════════════════════════╣
    ║                       MACHINE ROOM                         ║
    ║                       (12m × 12m)                          ║
    ║                                                             ║
    ║   ┌ ─ ─ ─ ─ ─ ┐               ┌ ─ ─ ─ ─ ─ ┐              ║
    ║   │  ZONE C    │               │  ZONE D    │              ║
    ║   │ AutomHub   │               │   SPARE    │              ║
    ║   │  3m × 3m   │               │  3m × 3m   │              ║
    ║   └ ─ ─ ─ ─ ─ ┘               └ ─ ─ ─ ─ ─ ┘              ║
    ║         ○  ← interact                  ○  ← interact       ║
    ║                                                             ║
    ║   ┌ ─ ─ ─ ─ ─ ┐               ┌ ─ ─ ─ ─ ─ ┐              ║
    ║   │  ZONE A    │               │  ZONE B    │              ║
    ║   │  Recycler  │               │ Fabricator │              ║
    ║   │  3m × 3m   │               │  3m × 3m   │              ║
    ║   └ ─ ─ ─ ─ ─ ┘               └ ─ ─ ─ ─ ─ ┘              ║
    ║         ○  ← interact                  ○  ← interact       ║
    ║                                                             ║
    ║                   ╔════════════════╗                        ║
    ║                   ║   VESTIBULE    ║                        ║
    ║                   ║   4m × 4m      ║                        ║
    ║                   ║       ▼        ║                        ║
    ║                   ║  entry/exit    ║                        ║
    ║                   ╚════════════════╝                        ║
    ╚═════════════════════════════════════════════════════════════╝
    │
    ▼
    South (toward ship ramp / exterior)

    Legend:
    ╔═══╗  Solid walls / structural boundary
    ┌ ─ ┐  Module placement zone (floor marking, dashed boundary)
    ○      Interact point (player stands here to use the placed module)
    ▼      Entry/exit direction (ramp to exterior)
    [PWR]  Cockpit diegetic status display panel (wall-mounted)
```

---

## Entry Vestibule

- **Size:** 4m wide (X: −2 to +2) × 4m deep (Z: +8 to +12)
- **Position:** Centered on south wall of machine room; connects exterior ramp to main interior
- **Ceiling height:** 3m
- **Features:**
  - Exterior-facing door at Z = +12 (ship hull opening)
  - Interior door threshold at Z = +8 (open archway into machine room)
  - Interior spawn `Marker3D` at X = 0, Y = 0, Z = +10 — player faces north (−Z) on entry
  - Exit trigger `Area3D` at Z = +11.5 (midpoint) — detects player walking toward exterior, shows "Press [E] to exit ship"
  - Entry trigger is on the exterior side of the hull; ship entry interact prompt is placed there
  - HUD signal: crossing into vestibule from exterior fires `player_entered_ship`; crossing out fires `player_exited_ship`
- **Greybox:** Box geometry, same material as corridors — slightly lighter grey to distinguish from machine room

---

## Connecting Corridor

- **Size:** 4m wide (X: −2 to +2) × 2m deep (Z: −6 to −4)
- **Position:** Centered between machine room and cockpit
- **Ceiling height:** 3m
- **Features:**
  - Archway at Z = −4 (machine room to corridor entrance)
  - Archway at Z = −6 (corridor to cockpit entrance)
  - No interaction points — purely a spatial transition
  - Walking clearance: 4m wide throughout ✓
- **Greybox:** Box geometry, corridor material (lighter grey `#555555`)
- **Future:** This corridor is the natural location for a pressure door, airlock-style seal, or security checkpoint (post-M7)

---

## Machine Room

- **Size:** 12m wide (X: −6 to +6) × 12m deep (Z: −4 to +8)
- **Ceiling height:** 3m
- **Features:**
  - 4 module placement zones (see Module Zone Layout below)
  - Flat floor — no steps or elevation changes
  - Vestibule entrance archway at Z = +8, X: −2 to +2
  - Corridor entrance archway at Z = −4, X: −2 to +2
  - Ambient lighting from ceiling
- **Greybox:** Main bay material, medium grey `#4A4A4A` floor, dark grey walls/ceiling

---

## Cockpit

- **Size:** 12m wide (X: −6 to +6) × 6m deep (Z: −12 to −6)
- **Ceiling height:** 3m
- **Features:**
  - Navigation console placeholder (see Cockpit Console Spec below)
  - 4 diegetic status display panels (see Status Display Spec below)
  - Exterior viewport / window (see Viewport Spec below)
  - Corridor entrance archway at Z = −6, X: −2 to +2
  - Player walking clearance: 3m+ on each side of the console ✓
- **Greybox:** Dark grey walls and ceiling (`#2A2A2A`) — slightly darker than machine room to emphasize the cockpit as a distinct space

---

## Module Zone Layout

Four 3m × 3m zones arranged in a 2 × 2 grid within the machine room.

### Clearance Verification

| Clearance | Measurement | Requirement |
|-----------|-------------|-------------|
| West wall → Zone A/C | 2m | ≥ 2m ✓ |
| Zone A/C → Zone B/D (center aisle) | 2m | ≥ 2m ✓ |
| Zone B/D → East wall | 2m | ≥ 2m ✓ |
| South wall (Z=+8) → Zone A/B front edge | 2m | ≥ 2m ✓ |
| Zone A/B back edge → Zone C/D front edge | 2m | ≥ 2m ✓ |
| Zone C/D back edge → North wall (Z=−4) | 2m | ≥ 2m ✓ |

All paths exceed the 2m minimum clearance. ✓

### Zone Coordinates

All coordinates relative to scene origin. Zone occupies the full 3m × 3m floor area at Y = 0.

```
                          ← 12m →
      X=-6  X=-4   X=-1   X=0   X=+1   X=+4  X=+6
        │    │       │      │      │      │     │
  Z=-4 ─┤    │   ZONE C    │      │   ZONE D   │    ├─ Z=-4  (machine room N wall)
        │    │   X:[-4,-1] │      │  X:[+1,+4] │
  Z=-2 ─┤    └ ─ ─ ─ ─ ─ ─┘      └─ ─ ─ ─ ─ ─┘    ├─ Z=-2
        │           ○                    ○
  Z=+1 ─┤    ┌ ─ ─ ─ ─ ─ ─┐      ┌─ ─ ─ ─ ─ ─┐    ├─ Z=+1
        │    │   ZONE A    │      │   ZONE B   │
  Z=+3 ─┤    │   X:[-4,-1] │      │  X:[+1,+4] │    ├─ Z=+3
        │    └ ─ ─ ─ ─ ─ ─┘      └─ ─ ─ ─ ─ ─┘
  Z=+6 ─┤           ○                    ○           ├─ Z=+6
        │
  Z=+8 ─┤ (machine room S wall / vestibule threshold)
```

| Zone | Module | X Center | Z Center | X Range | Z Range | Interact Point |
|------|--------|----------|----------|---------|---------|----------------|
| **A** | Recycler | −2.5 | +4.5 | −4 to −1 | +3 to +6 | X=−2.5, Z=+6.5, Y=0 |
| **B** | Fabricator | +2.5 | +4.5 | +1 to +4 | +3 to +6 | X=+2.5, Z=+6.5, Y=0 |
| **C** | Automation Hub | −2.5 | −0.5 | −4 to −1 | −2 to +1 | X=−2.5, Z=+1.5, Y=0 |
| **D** | (Spare) | +2.5 | −0.5 | +1 to +4 | −2 to +1 | X=+2.5, Z=+1.5, Y=0 |

**Interact point convention:** Centered on the south (front-facing) edge of each zone, offset 0.5m south. Player faces north (toward module) when interacting.

### Future Expansion

Zones C and D back row have 2m of clear floor north of them (Z: −4 to −2) before the machine room north wall. A fifth zone could be added at the north wall (Z: −4 to −1) without restructuring — the center aisle extends naturally. When the machine room depth is extended, additional rows slot in without changing existing zone coordinates.

### Zone Visual Marking

Identical to M4 specification:
- **Empty:** Dashed rectangle on floor, emissive teal `#00D4AA` at 30% opacity. Interact prompt: "Press [E] to install module"
- **Occupied:** Module mesh sits in zone. Floor marking dims to 15% opacity. Interact prompt: "Press [E] to use [Module Name]"
- Zone `Area3D` trigger: 3m × 0.1m × 3m box at Y = 0.05 — detects player proximity for interact prompt

---

## Cockpit Console Specification

The navigation console is a non-functional placeholder. No interaction is attached until M8.

| Property | Value |
|----------|-------|
| **Position** | X = 0, Y = 0, Z = −11.5 (0.5m from north wall) |
| **Size** | 2m wide × 0.8m tall × 0.6m deep |
| **Mesh type** | `MeshInstance3D` with `BoxMesh` |
| **Material** | Dark grey `#333333`, roughness 0.8 |
| **Interaction** | None — no `Area3D`, no interact prompt. A `Label3D` node above: "Navigation Console (M8)" at Y = 1.0m, scale 0.1 |
| **Walking clearance** | 5m on each side (west and east) ✓ |

The console is centered, leaving 5m walkable space on each side (X: −6 to −1 on west, +1 to +6 on east). Player can walk behind the console along the north wall if needed (0.5m gap between console and wall — tight but passable; designer may widen to 0.8m if needed).

---

## Cockpit Exterior Viewport Specification

The cockpit viewport shows the exterior world. For greybox, this is a **transparent mesh opening** in the north hull wall — a gap in the geometry with an invisible or wire-frame boundary. No `SubViewport` required; exterior world geometry renders naturally through the opening.

| Property | Value |
|----------|-------|
| **Position** | Centered on north wall, X: −2 to +2 (4m wide), Z = −12 |
| **Size** | 4m wide × 1.5m tall |
| **Bottom edge** | Y = 1.5m (above console, at eye level when standing) |
| **Top edge** | Y = 3.0m (flush with ceiling) |
| **Implementation** | Hull geometry has a rectangular cutout; no mesh covers the opening. A thin `MeshInstance3D` frame (0.1m border, dark grey) outlines the opening for definition |
| **Material** | Opening is empty — no glass mesh in greybox. Glass mesh added in M9 art pass |
| **Visibility** | Exterior world geometry (terrain, sky) renders through the opening automatically |

**Alternative approach (not recommended for greybox):** `SubViewport` with a camera mounted outside the ship looking forward. Higher cost, required if the opening causes rendering issues with scene instancing. Evaluate only if the opening produces z-fighting or incorrect depth sorting.

**For M9:** Replace the open gap with a glass-material mesh (`StandardMaterial3D`, transparency enabled, roughness 0.1, metallic 0.5, albedo `#C8D8FF` at 20% alpha).

---

## Cockpit Status Display Specification

Four wall-mounted diegetic panels showing ship global variables. These are physical 3D objects in the world — not screen HUD elements. They supplement the bottom-right ship globals HUD panel (from M4) and provide environmental storytelling in the cockpit.

### Panel Geometry

| Property | Value |
|----------|-------|
| **Mesh type** | `MeshInstance3D` with `BoxMesh` |
| **Size** | 0.6m wide × 0.4m tall × 0.05m thick |
| **Mount height** | Y = 1.5m (center of panel — eye level) |
| **Material (frame)** | Dark grey `#1A2736`, roughness 0.8 |
| **Material (face)** | Emissive, variable by ship state (see color table) |
| **Interaction** | None — display only |

### Panel Positions

| Variable | Wall | X | Y Center | Z | Facing Direction |
|----------|------|---|----------|---|-----------------|
| **Power** | West | −5.95 | 1.5 | −8.0 | +X (east) |
| **Integrity** | West | −5.95 | 1.5 | −9.5 | +X (east) |
| **Heat** | East | +5.95 | 1.5 | −8.0 | −X (west) |
| **Oxygen** | East | +5.95 | 1.5 | −9.5 | −X (west) |

West wall panels face east (player sees them when looking left from the console).
East wall panels face west (player sees them when looking right from the console).

### Display Content per Panel

Each panel shows a simplified version of the ship globals HUD bar:
- Icon (20px equivalent in world space, ~0.06m)
- Bar fill (width = 0 to 0.48m proportional to current value)
- Percentage label

Implement as a `SubViewport` texture rendered onto the panel face — reuse the HUD bar nodes from the existing ship globals panel (`ShipStatusPanel`). The subviewport renders at 128×64px resolution (sufficient for close-up legibility without performance cost).

**Color states:** Identical to `docs/design/wireframes/m4/ship-globals-hud.md` — teal healthy, amber low/warning, coral critical. Panel face emissive brightness: 0.4 at healthy state, 0.8 at critical state (pulse 1.5s — same as HUD).

---

## Entry/Exit Flow

### Entering the Ship

1. Player approaches ship exterior near the vestibule entry door (south hull face)
2. Interact prompt appears: "Press [E] to enter ship"
3. Player presses interact
4. Fade-to-black (300ms) → fade-in (300ms)
5. Player spawns at `Marker3D` inside vestibule: X=0, Y=0, Z=+10, facing north (−Z)
6. Ship globals HUD activates (`player_entered_ship` signal)
7. Player walks north through vestibule into machine room, then corridor, into cockpit

### Exiting the Ship

1. Player walks south through machine room to vestibule (Z > +8)
2. At Z = +11.5, exit trigger `Area3D` fires; interact prompt appears: "Press [E] to exit ship"
3. Player presses interact
4. Fade-to-black (300ms) → fade-in (300ms)
5. Player spawns at exterior spawn `Marker3D` outside the ship (position set by gameplay-programmer relative to ship mesh)
6. Ship globals HUD deactivates (`player_exited_ship` signal)

### Internal Room Transitions

Room transitions within the ship (vestibule → machine room → corridor → cockpit) are seamless — no fade, no loading. The player simply walks through archways. No trigger logic required for internal transitions in M7 greybox.

**Future (M8+):** Pressure door or airlock mechanic in the corridor may add an interaction to pass through.

---

## Greybox Material Spec

| Surface | Color | Material |
|---------|-------|----------|
| **Floor (all rooms)** | Medium grey `#4A4A4A` | `StandardMaterial3D`, roughness 0.8 |
| **Walls (machine room)** | Dark grey `#333333` | `StandardMaterial3D`, roughness 0.9 |
| **Walls (cockpit)** | Darker grey `#2A2A2A` | `StandardMaterial3D`, roughness 0.9 — emphasizes cockpit distinction |
| **Ceiling** | Dark grey `#2A2A2A` | `StandardMaterial3D`, roughness 0.9 |
| **Vestibule / Corridor** | Lighter grey `#555555` | Distinguishes transition spaces from main areas |
| **Module zone floor marking** | Teal `#00D4AA` at 30% | Emissive overlay mesh on floor |
| **Console mesh** | Dark grey `#333333` | `StandardMaterial3D`, roughness 0.8 |
| **Status display frame** | Dark slate `#1A2736` | `StandardMaterial3D`, metallic 0.3 |
| **Viewport frame border** | Dark grey `#333333` | `StandardMaterial3D`, roughness 0.9 |

### Lighting

- **Type:** Two `OmniLight3D` nodes (one in machine room, one in cockpit) — uniform, no dramatic shadows
- **Color:** Neutral white `#E0E0E0`
- **Purpose:** Functional visibility only — greybox phase only
- **Cockpit accent:** Optional second `OmniLight3D` slightly warmer (`#F0EAD6`) in cockpit only, to suggest instrument panel glow without committing to mood lighting

---

## Collision & Navigation

- All walls, floor, and ceiling have `StaticBody3D` + `CollisionShape3D`
- Floor is flat throughout — no steps or ramps inside
- Archways between rooms have no collision — open pass-through geometry
- Player uses existing first-person controller (unchanged from M1/M3)
- No special movement modifications inside the ship

---

## Scene Structure — Implementation Notes

```
ShipInterior (Node3D — root, instanced scene: res://game/scenes/gameplay/ship_interior.tscn)
├── Geometry (Node3D)
│   ├── Hull (StaticBody3D) — outer walls, floor, ceiling — single merged mesh or CSGCombiner3D
│   ├── Vestibule (Node3D) — vestibule geometry child nodes
│   ├── MachineRoom (Node3D) — machine room geometry
│   ├── Corridor (Node3D) — corridor geometry
│   └── Cockpit (Node3D) — cockpit geometry, console, displays, viewport frame
├── ModuleZones (Node3D)
│   ├── ZoneA (Area3D + CollisionShape3D + Marker3D[interact_point])
│   ├── ZoneB (Area3D + CollisionShape3D + Marker3D[interact_point])
│   ├── ZoneC (Area3D + CollisionShape3D + Marker3D[interact_point])
│   └── ZoneD (Area3D + CollisionShape3D + Marker3D[interact_point])
├── Triggers (Node3D)
│   ├── EntryTrigger (Area3D) — exterior entry interact point
│   └── ExitTrigger (Area3D) — vestibule exit interact point (Z ≈ +11.5)
├── SpawnPoints (Node3D)
│   ├── InteriorSpawn (Marker3D) — X=0, Y=0, Z=+10, facing north
│   └── ExteriorSpawn (Marker3D) — set by gameplay-programmer relative to ship mesh
├── CockpitFeatures (Node3D) — instanced separately in TICKET-0127 and TICKET-0128
│   ├── ConsoleProto (MeshInstance3D + Label3D)
│   ├── StatusDisplays (Node3D)
│   │   ├── PowerDisplay (MeshInstance3D + SubViewport)
│   │   ├── IntegrityDisplay (MeshInstance3D + SubViewport)
│   │   ├── HeatDisplay (MeshInstance3D + SubViewport)
│   │   └── OxygenDisplay (MeshInstance3D + SubViewport)
│   └── ViewportWindow (MeshInstance3D — frame only, opening is hull cutout)
└── Lighting (Node3D)
    ├── MachineRoomLight (OmniLight3D) — positioned at X=0, Y=2.8, Z=+2
    └── CockpitLight (OmniLight3D) — positioned at X=0, Y=2.8, Z=−9
```

- Use `CSGBox3D` nodes for rapid greybox construction, or `MeshInstance3D` with `BoxMesh` resources
- Module zones: `Area3D` with `CollisionShape3D` (box shape 3m × 0.1m × 3m at Y = 0.05) for proximity detection
- The cockpit console, status displays, and viewport frame are implemented via TICKET-0127 and TICKET-0128 — this wireframe defines their positions; those tickets build them
- Scene is instanced into the main game world scene when the player enters

---

## Walkable Path Verification

All paths through the interior verified at ≥ 2m clearance:

| Path | Width | Clear? |
|------|-------|--------|
| Vestibule (entry to machine room) | 4m | ✓ |
| Connecting corridor (machine room to cockpit) | 4m | ✓ |
| Center aisle in machine room (between zone columns) | 2m | ✓ |
| West aisle in machine room (between wall and zones) | 2m | ✓ |
| East aisle in machine room (between zones and wall) | 2m | ✓ |
| Between zone front row and south machine room wall | 2m | ✓ |
| Between zone back row and north machine room wall | 2m | ✓ |
| Between zone front row and back row | 2m | ✓ |
| Cockpit west of console | 5m | ✓ |
| Cockpit east of console | 5m | ✓ |

---

## Future Expansion Notes

- Machine room designed with room for a 5th module zone north of Zone C/D (Z: −4 to −1) without restructuring
- The console placeholder at Z = −11.5 is positioned to receive interaction wiring in M8 (navigation system)
- The viewport opening receives a glass material in M9 visual art pass
- Status display panels could be upgraded to animated holographic projections in M9+
- The connecting corridor is sized for a future pressure door / airlock installation
- Cockpit lighting (OmniLight3D) can be replaced with point lights tied to console power state once M8 ship systems are wired up

---

## Handoff Notes

(Leave blank until handoff occurs.)
