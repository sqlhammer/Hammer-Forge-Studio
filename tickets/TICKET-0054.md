---
id: TICKET-0054
title: "3D asset — Recycler machine mesh"
type: TASK
status: DONE
priority: P1
owner: technical-artist
created_by: producer
created_at: 2026-02-23
updated_at: 2026-02-23
milestone: "M4"
milestone_gate: "M3"
depends_on: [TICKET-0042]
blocks: [TICKET-0044]
tags: [art, asset, recycler, ship, machines]
---

## Summary
Produce the Recycler machine 3D mesh per the form factor wireframe delivered in TICKET-0042. The Recycler is a placeable ship module — a physical machine the player installs in the ship interior and interacts with to process resources. The panel UI is mounted to the front of this machine (built-in screen).

## Acceptance Criteria
- [x] Mesh produced using the hybrid pipeline (Blender Python) per the M2 pipeline SOP at `docs/art/3d-pipeline-sop.md`
- [x] Delivered at `game/assets/meshes/machines/mesh_recycler_module.glb`
- [x] Dimensions: approximately 1.8m (W) × 1.2m (D) × 1.4m (H) — match wireframe spec
- [x] Triangle budget: 1500–4000 tris (greybox quality; no fine surface detail required)
- [x] Input hopper visible on left side, output tray on right side, front-facing screen/panel area
- [x] Status light and power indicator present (greybox placeholder, no texture detail required)
- [x] Flat/greybox materials only — no texture maps required in M4
- [x] Imports cleanly into Godot with no editor errors or warnings
- [x] Consistent scale with existing M2 assets (hand drill, player character, ship exterior)

## Implementation Notes
- Reference wireframe: `docs/design/wireframes/m4/recycler-machine.md`
- The panel UI (TICKET-0045) overlays the machine's front screen — the screen face should be a recognizable flat surface with forward-facing normal
- Greybox quality is intentional for M4; a polished art pass is deferred to M8 (Visual Asset Refinement)
- Follow art tech specs at `docs/art/tech-specs.md`

## Handoff Notes

### Asset Deliverable
- **File:** `game/assets/meshes/machines/mesh_recycler_module.glb`
- **Build script:** `blender_experiments/build_recycler_module.py`
- **Pipeline:** Blender Python (exact dimensional control required for boxy geometry)
- **Triangle count:** 1,590 tris (budget: 1,500–4,000)
- **File size:** 100 KB (budget: ≤1 MB)
- **Materials (7):** Recycler_Body, Recycler_Seam, Recycler_Base, Recycler_Screen, Recycler_StatusLight, Recycler_PowerLight, Recycler_Hopper
- **AABB envelope:** W=2.10m × D=1.40m × H=1.37m (body 1.8×1.2×1.4, base/hopper extend envelope)

### Key Landmarks Present
- Input hopper (left side, upper) — truncated cone funnel with lip ring and guide rails
- Output tray (right side, lower) — shelf with raised edges
- Screen panel (front face, upper-center) — emissive flat surface with bezel frame
- Status light (front, below screen, left) — 5cm emissive sphere
- Power indicator (front, below screen, right) — 3cm emissive sphere
- Exhaust vents (top surface, toward back) — housing with slit grilles
- Corner reinforcements and bolts on front face
- Internal processing pipe with collar on back face

### For Gameplay Programmer (TICKET-0044)
- Screen surface is a separate MeshInstance3D (`Screen_Surface`) for independent material swapping (idle/active states)
- Status light and power indicator are separate MeshInstance3D nodes for runtime emission control
- Machine origin is at floor level (Z=0), front face at -Y — snap to module zone center
- Output tray edge materials can be toggled for emissive glow when job completes

## Activity Log
- 2026-02-23 [producer] Created ticket. Spawned from gap identified during M4 implementation review — TICKET-0042 wireframe specifies a 3D machine form factor with no corresponding asset production ticket.
- 2026-02-23 [technical-artist] Status → IN_PROGRESS. Dependency check passed (TICKET-0042 DONE). Pipeline decision: Blender Python (boxy geometry, exact dimensional control). Writing build script.
- 2026-02-23 [technical-artist] Mesh built and validated. 1,590 tris, 100 KB, 7 materials, imports cleanly into Godot. All acceptance criteria met. Status → DONE.
