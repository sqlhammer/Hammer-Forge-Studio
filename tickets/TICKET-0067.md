---
id: TICKET-0067
title: "Fabricator — 3D mesh and ship interior placement"
type: TASK
status: OPEN
priority: P1
owner: technical-artist
created_by: producer
created_at: 2026-02-24
updated_at: 2026-02-24
milestone: "M5"
milestone_gate: "M4"
phase: "Foundation"
depends_on: []
blocks: [TICKET-0069]
tags: [fabricator, 3d-asset, ship-interior, technical-art]
---

## Summary
Produce the Fabricator 3D mesh following the M2 pipeline SOP, import it into Godot, and place it in the greybox ship interior scene. The Fabricator is a crafting machine — visually distinct from the Recycler — that occupies a dedicated zone in the ship interior. The physical machine must be present in the scene before the interaction panel (TICKET-0069) can be implemented.

## Acceptance Criteria
- [ ] Fabricator mesh produced following `docs/engineering/3d-pipeline-sop.md` (M2 pipeline)
- [ ] Mesh is visually distinct from the Recycler — different silhouette and form factor appropriate to a fabrication/assembly machine
- [ ] Mesh imported into Godot and placed in the greybox ship interior scene (`game/scenes/gameplay/`)
- [ ] An `InteractionArea` (or equivalent collision/trigger node) attached to the Fabricator mesh — used by gameplay-programmer to wire the interaction in TICKET-0069
- [ ] Mesh poly count and texture budget within M2 pipeline art tech spec limits
- [ ] No Godot import errors or warnings
- [ ] Scene saved and committed

## Implementation Notes
- Reference `docs/engineering/3d-pipeline-sop.md` for the full production pipeline
- Reference existing M4 Recycler asset for scale, placement style, and interaction area convention
- The Fabricator should read as a "crafting bench / assembly station" in form factor — not industrial heavy machinery (that's the Recycler's territory)
- Placement zone in the ship interior: coordinate with greybox layout established in M4 (TICKET-0043)
- UI panel design (TICKET-0065) runs in parallel — if form factor guidance is needed before TICKET-0065 completes, use general design intent from GDD and the Recycler as a reference

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-24 [producer] Created ticket
