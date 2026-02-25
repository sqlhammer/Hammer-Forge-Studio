# Asset Brief: Automation Hub Module

**Ticket:** TICKET-0120
**Author:** technical-artist
**Date:** 2026-02-25

---

## In-Game Function

The Automation Hub is a ship-interior module that controls mining drones. It is the third machine the player installs (after Recycler and Fabricator), requiring the Fabricator to be unlocked first via the tech tree. Visually it must read as a "command console / control station" — distinct from both the Recycler (tall industrial processor) and Fabricator (wide workbench).

---

## Approximate Scale

- **Type:** Ship interior module (drone command/control station)
- **Size reference:** Compact console — medium height, moderate width
- **Poly budget:** 1,500–4,000 triangles (hero environment prop)
- **Bounding box:** ~2.2m wide x 1.2m deep x 1.4m tall (collision box from test_world.gd)
- **Placement:** Ship interior Zone C (rightmost zone, 3m x 3m placement area)

---

## Visual Context

- **Art style:** Stylized sci-fi greybox. Same Outer Wilds-meets-industrial utility aesthetic as Recycler and Fabricator
- **Material palette:** Medium-grey metallic body, darker base, lighter panel seams, emissive teal/amber screen and indicators
- **Key visual reads:**
  - Reads as "command console / drone controller" — NOT a workbench or processor
  - Angled main display screen on front face (larger than Recycler/Fabricator screens — this is the primary interface)
  - Antenna array on top (key distinguishing silhouette — signals "communication/control")
  - Side panel with drone status indicator lights (stacked LEDs showing drone fleet status)
  - Compact console desk form factor with recessed control panel below the screen
  - Ventilation grille on the back for heat dissipation

---

## Silhouette Differentiation

| Feature | Recycler | Fabricator | Automation Hub |
|---------|----------|-----------|----------------|
| Overall shape | Tall upright box (1.8W x 1.2D x 1.4H) | Wide low bench (2.0W x 1.0D x 1.2H) | Console desk (2.2W x 1.2D x 1.4H) |
| Key top feature | Exhaust vents | Work surface + press arm | Antenna array |
| Screen | Small upper-center | Small lower-left | Large angled main display |
| Side features | Hopper + tray | Bins + drawer | Drone status LED panel |
| Profile | Vertical, industrial | Horizontal, workbench | Angled, command station |

---

## Done Criteria

- [ ] A single GLB mesh exported via Blender Python pipeline
- [ ] Silhouette distinct from Recycler and Fabricator at placement zone viewing distance
- [ ] Proportions fit within `Vector3(2.2, 1.4, 1.2)` collision box
- [ ] Flat PBR materials with greybox color palette (no textures)
- [ ] Imports into Godot without errors
- [ ] Placed in `game/assets/meshes/machines/mesh_automation_hub_module.glb`
- [ ] Triangle count within 1,500–4,000 budget
- [ ] GLB file size under 1 MB
