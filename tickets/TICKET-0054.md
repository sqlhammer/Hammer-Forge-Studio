---
id: TICKET-0054
title: "3D asset — Recycler machine mesh"
type: TASK
status: OPEN
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
- [ ] Mesh produced using the hybrid pipeline (Tripo3D primary, Blender decimation secondary) per the M2 pipeline SOP at `docs/art/3d-pipeline-sop.md`
- [ ] Delivered at `game/assets/meshes/machines/mesh_recycler_module.glb`
- [ ] Dimensions: approximately 1.8m (W) × 1.2m (D) × 1.4m (H) — match wireframe spec
- [ ] Triangle budget: 1500–4000 tris (greybox quality; no fine surface detail required)
- [ ] Input hopper visible on left side, output tray on right side, front-facing screen/panel area
- [ ] Status light and power indicator present (greybox placeholder, no texture detail required)
- [ ] Flat/greybox materials only — no texture maps required in M4
- [ ] Imports cleanly into Godot with no editor errors or warnings
- [ ] Consistent scale with existing M2 assets (hand drill, player character, ship exterior)

## Implementation Notes
- Reference wireframe: `docs/design/wireframes/m4/recycler-machine.md`
- The panel UI (TICKET-0045) overlays the machine's front screen — the screen face should be a recognizable flat surface with forward-facing normal
- Greybox quality is intentional for M4; a polished art pass is deferred to M8 (Visual Asset Refinement)
- Follow art tech specs at `docs/art/tech-specs.md`

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-23 [producer] Created ticket. Spawned from gap identified during M4 implementation review — TICKET-0042 wireframe specifies a 3D machine form factor with no corresponding asset production ticket.
