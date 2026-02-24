# Asset Brief: Fabricator Module

**Ticket:** TICKET-0067
**Author:** technical-artist
**Date:** 2026-02-24

---

## In-Game Function

The Fabricator is a ship-interior crafting machine that assembles components from processed materials. It is the second machine the player installs (after the Recycler), producing items like the Spare Battery and Head Lamp. Visually it must be immediately distinguishable from the Recycler — reading as an assembly/crafting workbench rather than a heavy industrial processor.

---

## Approximate Scale

- **Type:** Ship interior module (crafting/assembly station)
- **Size reference:** Workbench-sized — wider and lower than the Recycler to emphasize its horizontal work surface
- **Poly budget:** 1,500–4,000 triangles (hero environment prop)
- **Bounding box:** ~2.0m wide x 1.0m deep x 1.2m tall
- **Placement:** Ship interior module zone (3m x 3m placement area)

---

## Visual Context

- **Art style:** Stylized sci-fi greybox. Same Outer Wilds-meets-industrial utility aesthetic as the Recycler
- **Material palette:** Medium-grey metallic body, darker base, lighter panel seams, emissive teal screen/indicators
- **Key visual reads:**
  - Reads as "workbench / assembly station" — NOT heavy machinery (that's the Recycler)
  - Wide, flat work surface on top with tool/clamp details
  - Articulated press arm or assembly head above the work surface (key distinguishing silhouette from Recycler)
  - Front-facing screen panel for recipe selection (consistent with Recycler screen convention)
  - Storage drawers or bins on the side for output
  - Lower, wider profile than the Recycler (horizontal emphasis vs Recycler's vertical mass)

---

## Silhouette Differentiation from Recycler

| Feature | Recycler | Fabricator |
|---------|----------|-----------|
| Overall shape | Tall upright box (1.8W x 1.2D x 1.4H) | Wide low bench (2.0W x 1.0D x 1.2H) |
| Key feature | Input hopper + output tray (sides) | Work surface + press arm (top) |
| Profile | Vertical, industrial | Horizontal, workbench |
| Front face | Screen in upper center | Screen on lower-left, work area visible |

---

## Done Criteria

- [ ] A single GLB mesh exported via Blender Python pipeline
- [ ] Silhouette distinct from Recycler at placement zone viewing distance
- [ ] Proportions fit the stylized sci-fi greybox aesthetic
- [ ] Flat PBR materials with greybox color palette (no textures)
- [ ] Imports into Godot without errors
- [ ] Placed in `game/assets/meshes/machines/mesh_fabricator_module.glb`
- [ ] Triangle count within 1,500–4,000 budget
- [ ] GLB file size under 1 MB
