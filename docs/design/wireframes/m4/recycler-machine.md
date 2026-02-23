# Wireframe: Recycler Machine — 3D Form Factor

**Component:** Recycler Module Physical Machine
**Ticket:** TICKET-0042
**Blocks:** TICKET-0043 (greybox ship interior), TICKET-0044 (module placement), TICKET-0045 (Recycler interaction)
**Last Updated:** 2026-02-23

---

## Purpose

The Recycler is the first module the player installs inside the ship. It is a physical machine that occupies a module placement zone. The player walks up to it, sees its current status at a glance, and interacts with a built-in screen to queue processing jobs. This wireframe defines the machine's 3D form factor, dimensions, key visual landmarks, and the relationship between the physical machine and its interaction UI.

---

## Design Intent

The Recycler should read as a chunky, utilitarian processing unit — something a researcher cobbled together from salvaged parts. It's functional, not elegant. The player should immediately understand: "raw material goes in one side, processed material comes out the other." The built-in screen is the primary interaction surface.

**Visual references:** Outer Wilds tool stations (handcrafted, purposeful instruments), industrial recycling compactors (boxy, heavy, visible mechanical function).

---

## Dimensions & Scale

| Property | Value | Notes |
|----------|-------|-------|
| **Width** | 1.8m | Faces the player (front) |
| **Depth** | 1.2m | Side-to-side from interact point |
| **Height** | 1.4m | Waist-to-chest height on a 1.8m player |
| **Placement zone** | 3m x 3m | Machine occupies center ~60% of the zone footprint |
| **Clearance** | 0.6m min on all sides | Player can walk around it within the zone |

**Scale rationale:** At 1.4m tall, the machine sits below eye level so the player naturally looks down at the screen. Large enough to feel like a serious piece of equipment, small enough that two fit comfortably in the 10m x 8m bay.

---

## Form Factor — Multi-View Diagram

### Front View (player faces this)

```
                    1.8m
    ◄──────────────────────────────►

    ┌──────────────────────────────┐  ─┬─
    │                              │   │
    │   ┌──────────────────────┐   │   │
    │   │                      │   │   │
    │   │    SCREEN PANEL      │   │   │
    │   │    (interaction UI)  │   │   │  1.4m
    │   │    40cm x 30cm       │   │   │
    │   │                      │   │   │
    │   └──────────────────────┘   │   │
    │                              │   │
    │   [STATUS LIGHT]   [POWER]   │   │
    │                              │   │
    ├──────────────────────────────┤  ─┴─
    │ ▓▓▓▓▓▓▓  BASE / FEET  ▓▓▓▓▓│
    └──────────────────────────────┘
                 FRONT
           (player stands here)
```

### Side View (left side — input side)

```
         1.2m
    ◄──────────────►

    ┌──────────────┐  ─┬─
    │              │   │
    │  ┌────────┐  │   │
    │  │ INPUT  │  │   │
    │  │ HOPPER │  │   │  1.4m
    │  │  ╲  ╱  │  │   │
    │  └────────┘  │   │
    │              │   │
    │   machine    │   │
    │   body       │   │
    ├──────────────┤  ─┴─
    │ ▓▓▓▓ BASE ▓▓▓│
    └──────────────┘
     LEFT SIDE (input)
```

### Side View (right side — output side)

```
         1.2m
    ◄──────────────►

    ┌──────────────┐  ─┬─
    │              │   │
    │              │   │
    │              │   │
    │              │   │  1.4m
    │  ┌────────┐  │   │
    │  │ OUTPUT │  │   │
    │  │ TRAY   │  │   │
    │  └────────┘  │   │
    │              │   │
    ├──────────────┤  ─┴─
    │ ▓▓▓▓ BASE ▓▓▓│
    └──────────────┘
     RIGHT SIDE (output)
```

### Top View

```
         1.2m
    ◄──────────────►

    ┌──────────────┐  ─┬─
    │  ┌────────┐  │   │
    │  │ INPUT  │  │   │
    │  │ HOPPER │  │   │
    │  │(open top│  │   │
    │  └────────┘  │   │  1.8m
    │              │   │
    │  ▒▒▒▒▒▒▒▒▒  │   │
    │  ▒ exhaust ▒ │   │
    │  ▒ vents   ▒ │   │
    │  ▒▒▒▒▒▒▒▒▒  │   │
    │              │   │
    └──────────────┘  ─┴─
     TOP (left=input, right=output)
     Front edge at bottom of diagram
```

---

## Key Visual Landmarks

These are the elements that give the machine visual identity and communicate its function at a glance. In M4 greybox, they are represented by simple geometry with distinct materials — no textures or fine detail.

### 1. Input Hopper (Left Side, Upper)

- **Shape:** Truncated pyramid / funnel opening on the left face, upper half
- **Size:** ~40cm x 40cm opening, narrowing to ~20cm
- **Visual read:** "Put stuff in here" — an obvious intake
- **Greybox:** Open-topped box geometry, darker interior
- **When processing:** Could have subtle particle emission or glow (deferred to polish pass)

### 2. Output Tray (Right Side, Lower)

- **Shape:** Shelf / tray protruding ~15cm from the right face, lower half
- **Size:** ~40cm wide x 25cm deep
- **Visual read:** "Finished product comes out here" — a collection shelf
- **Greybox:** Flat shelf with raised edges (simple box)
- **When output ready:** Teal emissive glow on the tray edge (`#00D4AA` at 40%)

### 3. Screen Panel (Front Face, Upper-Center)

- **Shape:** Recessed rectangular screen embedded in the front face
- **Size:** 40cm wide x 30cm tall
- **Position:** Upper-center of front face, angled ~15deg tilted toward the player (ergonomic viewing angle for a 1.8m player standing in front of a 1.4m machine)
- **Visual read:** "This is where I interact" — the primary interaction point
- **Greybox:** Flat emissive surface, distinct from the machine body color
- **Screen color (idle):** Dim teal glow (`#007A63` at 50%)
- **Screen color (active/interacting):** Bright teal (`#00D4AA`) — the Recycler UI panel renders here

### 4. Status Light (Front Face, Below Screen)

- **Shape:** Small circle or pill-shaped indicator, ~5cm diameter
- **Position:** Front face, below the screen, left side
- **Purpose:** At-a-glance job status without opening the panel
- **Colors:**
  - **Off (idle):** Neutral grey `#94A3B8` at 30%
  - **Processing:** Amber `#FFB830`, slow pulse (1.5s cycle)
  - **Complete:** Positive Green `#4ADE80`, solid
  - **Error/no power:** Coral `#FF6B5A`, fast blink (0.5s cycle)

### 5. Power Indicator (Front Face, Below Screen)

- **Shape:** Small circle, ~3cm diameter
- **Position:** Front face, below the screen, right side (next to status light)
- **Purpose:** Shows the machine is receiving ship power
- **Colors:**
  - **Powered:** Teal `#00D4AA`, solid
  - **Unpowered:** Off / dark

### 6. Machine Body

- **Shape:** Rounded-edge rectangular box — the main mass
- **Proportions:** Slightly wider than deep, industrial feel
- **Surface details (greybox):** Panel line seams (subtle edge geometry or color breaks dividing the body into 3-4 visual panels). No fine detail — just enough geometry to prevent it from reading as a plain cube.
- **Material zones:**
  - Main body: Medium-dark metal
  - Panel seams/edges: Slightly lighter accent
  - Base/feet: Darker, heavier

### 7. Base / Feet

- **Shape:** Slightly wider footprint than the body (~10cm overhang per side)
- **Purpose:** Grounds the machine visually, implies weight and stability
- **Greybox:** Simple box, darker material than body

---

## Placement Within Module Zone

```
    Module Zone A (3m x 3m, top-down view)
    ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
    │                                 │
    │       ┌──────────────┐          │
    │       │   RECYCLER   │          │
    │       │   1.8 x 1.2  │          │
    │       │              │          │
    │       │  [front/screen          │
    │       │   faces south]│          │
    │       └──────────────┘          │
    │              ○                  │
    │         interact point          │
    │        (0.8m from front)        │
    │                                 │
    └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘

    - Machine centered in zone
    - Front faces the interact point (toward entry corridor / south)
    - 0.6m clearance on all sides within zone
    - 0.8m from front face to interact point marker
```

**Orientation:** The machine always faces the interact point of the zone (south / toward the entry corridor), so the screen is visible as the player approaches.

---

## Interaction Flow with Machine

1. **Approach:** Player walks toward the Recycler. At 3m, the status light and screen glow are visible.
2. **Interact range (2m):** Prompt appears: "Press [E] to use Recycler"
3. **Interact:** Player presses interact.
   - Camera does NOT lock or reposition (stays in first-person, player retains control)
   - The Recycler panel UI opens as a screen-space overlay (see `recycler-panel.md`)
   - The physical screen on the machine brightens to full teal
4. **While panel is open:** Player is stationary (game paused), interacting with the 2D panel overlay
5. **Close panel:** Screen dims back to idle glow, player regains movement

**Why overlay instead of in-world screen:** At 40cm x 30cm, a physical in-world screen is too small for the UI detail needed (slots, progress bar, buttons) at comfortable viewing distance. The overlay panel *represents* what's on the machine screen — the physical screen provides the narrative anchor ("I'm reading the machine's display") while the overlay provides the usability.

---

## Greybox Material Spec

| Surface | Color | Material Type |
|---------|-------|---------------|
| **Main body** | Medium grey `#5A5A5A` | `StandardMaterial3D`, roughness 0.7, metallic 0.4 |
| **Panel seams / edges** | Lighter grey `#7A7A7A` | `StandardMaterial3D`, roughness 0.8, metallic 0.3 |
| **Base / feet** | Dark grey `#3A3A3A` | `StandardMaterial3D`, roughness 0.9, metallic 0.2 |
| **Input hopper interior** | Dark `#2A2A2A` | `StandardMaterial3D`, roughness 0.9 |
| **Output tray** | Medium grey `#5A5A5A` | Same as body; teal emissive edge when output ready |
| **Screen (idle)** | Teal `#007A63` | `StandardMaterial3D`, emission enabled, emission_energy 0.3 |
| **Screen (active)** | Teal `#00D4AA` | `StandardMaterial3D`, emission enabled, emission_energy 0.8 |
| **Status light** | State-dependent | `StandardMaterial3D`, emission enabled, small sphere/cylinder |
| **Power indicator** | State-dependent | `StandardMaterial3D`, emission enabled, small sphere |

---

## Asset Technical Spec

| Property | Value |
|----------|-------|
| **Asset type** | Environment prop (hero) |
| **Triangle budget** | 1,500–4,000 (max 4,000) |
| **Texture resolution** | 1024x1024 (if textured; greybox uses flat materials) |
| **File format** | GLB |
| **Max file size** | 1 MB |
| **Asset name** | `mesh_recycler_module.glb` |
| **Directory** | `game/assets/meshes/machines/` |
| **Material zones** | 4 minimum (body, seams, base, screen) |

---

## Greybox vs Final Art

This wireframe describes the **greybox M4 version**. The greybox needs:
- Correct dimensions and proportions
- Clearly readable landmarks (hopper, tray, screen, lights)
- Distinct material zones (even as flat colors)
- Correct placement and orientation in module zone

It does NOT need:
- Detailed surface modeling (rivets, bolts, wear marks)
- Texture maps (flat materials are fine)
- Particle effects (processing VFX deferred)
- Sound design (audio deferred)
- LOD variants (single mesh for M4)

The final art pass happens in M8 (Visual Asset Refinement).

---

## Implementation Notes

- The machine mesh is a static `MeshInstance3D` placed as a child of the module zone `Node3D` when the player installs the Recycler
- The screen is a separate `MeshInstance3D` child (flat quad) so its material can be swapped independently for idle/active states
- Status light and power indicator: Small `MeshInstance3D` spheres with emissive materials, colors driven by the `Recycler` autoload state
- The interact point is an `Area3D` with `CollisionShape3D` positioned 0.8m in front of the machine
- When building the greybox mesh: Use CSGBox3D composition in Godot for rapid iteration, or a simple Blender box-model export. The key is getting the proportions and landmarks right — topology quality doesn't matter at greybox stage
- Output tray glow: Toggle emission_energy on the tray edge material when `Recycler.job_completed` fires
