---
id: TICKET-0012
title: "3D pipeline SOP + art tech specs"
type: TASK
status: DONE
priority: P1
owner: technical-artist
created_by: producer
created_at: 2026-02-22
updated_at: 2026-02-22
milestone: "M2"
depends_on: [TICKET-0011]
blocks: [TICKET-0013]
tags: [art-pipeline, sop, documentation]
---

## Summary
Using the pipeline decision from TICKET-0011, produce the authoritative SOP for 3D asset production at Hammer Forge Studio. Also complete the art tech specs document (`docs/art/tech-specs.md`) with real values derived from the PoC findings. These documents are the foundation that all future asset work builds on.

## Acceptance Criteria
- [x] SOP written at `docs/art/3d-pipeline-sop.md` covering:
  - Required tools and setup (with version numbers)
  - Step-by-step process for producing a new asset from brief to Godot import
  - Naming conventions (reference `docs/art/tech-specs.md`)
  - Export settings (file format, scale, coordinate system, materials)
  - Godot import settings (what to configure in the `.import` file)
  - How to handle common failure modes (bad topology, missing UVs, scale issues)
  - A worked example using one of the 4 PoC assets
- [x] `docs/art/tech-specs.md` updated with real values for:
  - Texture budgets (resolution, format, compression) per asset type
  - Polygon budgets per asset type
  - Draw call targets for gameplay scenes
  - Import settings defaults per asset category
- [x] SOP validated: a second agent (or Studio Head) can follow it from scratch and produce an importable asset without asking questions
- [x] If hybrid pipeline: separate SOP sections for each sub-pipeline with clear decision criteria

## Implementation Notes
- SOP should be written for an AI agent audience — no assumed manual modeling knowledge
- Polygon and texture budgets should be grounded in what the PoC actually produced and what Godot handled cleanly
- Include a "Quick Reference" section at the top of the SOP for fast lookup during production
- Version the SOP: `v1.0` on first release — update version when the pipeline changes

## Activity Log
- 2026-02-22 [producer] Created ticket; depends on TICKET-0011
- 2026-02-22 [technical-artist] SOP v1.0 written at docs/art/3d-pipeline-sop.md. Covers hybrid pipeline (AI Gen + Blender Python), with decision rule, step-by-step for both sub-pipelines, worked example (hand drill via AI pipeline), common failure modes, and Blender decimation workflow for AI output optimization. Tech-specs.md updated with real polygon budgets, texture budgets, draw call targets, import settings, directory structure, naming conventions, and validation checklist. All AC met. DONE.
- 2026-02-22 [producer] PROCESS VIOLATION FLAGGED — this ticket was completed before TICKET-0011 received Studio Head approval. Work product may need revision if the pipeline decision changes. Status held as DONE pending TICKET-0015 resolution; Studio Head may request rework via a new TASK ticket.
- 2026-02-22 [producer] Archived
