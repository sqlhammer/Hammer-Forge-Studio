---
id: TICKET-0014
title: "QA — import validation + pipeline reproducibility"
type: QA
status: OPEN
priority: P1
owner: qa-engineer
created_by: producer
created_at: 2026-02-22
updated_at: 2026-02-22
milestone: "M2"
depends_on: [TICKET-0012, TICKET-0016]
blocks: []
tags: [qa, art-pipeline, validation]
---

## Summary
Validate that all 4 game assets import cleanly into Godot, meet the art tech specs, and that the pipeline SOP is reproducible by an agent who did not write it. This is the M2 milestone gate — QA sign-off closes the milestone.

## Acceptance Criteria

### Asset Validation
- [ ] All 4 assets load in Godot without errors or warnings
- [ ] Polygon counts verified against budgets in `docs/art/tech-specs.md`
- [ ] Texture resolutions verified against budgets in `docs/art/tech-specs.md`
- [ ] All assets display correctly in the M3 test scene (`game/scenes/test/test_m2_assets.tscn`)
- [ ] No z-fighting, missing materials, or broken UVs visible in-engine
- [ ] Asset file names match naming convention in `docs/art/tech-specs.md`

### Pipeline Reproducibility
- [ ] QA engineer follows `docs/art/3d-pipeline-sop.md` from scratch to produce one new test asset
- [ ] New test asset imports successfully into Godot without outside help
- [ ] Any gaps, ambiguities, or failures in the SOP documented and reported to technical-artist

### Documentation Check
- [ ] `docs/art/3d-pipeline-sop.md` exists and covers all required sections
- [ ] `docs/art/tech-specs.md` has no remaining `[TBD]` fields in required sections
- [ ] `docs/art/pipeline-recommendation.md` documents the pipeline decision with Studio Head approval recorded

### Sign-off
- [ ] QA test results documented at `docs/qa/test-results-M2.md`
- [ ] All blockers resolved before sign-off
- [ ] M2 milestone approved

## Activity Log
- 2026-02-22 [producer] Created ticket; depends on TICKET-0012, TICKET-0013
- 2026-02-22 [producer] GATED — added dependency on TICKET-0015. TICKET-0011 pipeline decision was never approved by Studio Head before TICKET-0012 and TICKET-0013 were marked DONE. QA must not begin until TICKET-0015 is resolved.
- 2026-02-22 [producer] Updated depends_on to [TICKET-0012, TICKET-0016]. TICKET-0011 approved (DONE). TICKET-0013 output rejected by Studio Head; TICKET-0016 created for hybrid rework. TICKET-0015 closed. QA gated on TICKET-0016.
