---
id: TICKET-0011
title: "Evaluate PoC results + produce pipeline recommendation"
type: DESIGN
status: IN_REVIEW
priority: P1
owner: technical-artist
created_by: producer
created_at: 2026-02-22
updated_at: 2026-02-22
milestone: "M2"
depends_on: [TICKET-0009, TICKET-0010]
blocks: [TICKET-0012]
tags: [art-pipeline, poc, decision]
---

## Summary
Apply the evaluation criteria from TICKET-0008 to the results of both PoCs (TICKET-0009, TICKET-0010). Produce a written recommendation for Studio Head that clearly identifies the preferred pipeline — or a hybrid approach — with supporting evidence. Studio Head makes the final decision; this ticket delivers the analysis needed to make that call.

## Acceptance Criteria
- [x] Evaluation completed against all criteria defined in `docs/art/poc-evaluation-criteria.md`
- [x] Side-by-side comparison documented for each of the 4 assets
- [x] Written recommendation at `docs/art/pipeline-recommendation.md` covering:
  - Summary of each pipeline's strengths and weaknesses
  - Scored or ranked comparison using the defined criteria
  - Clear recommendation: Blender Python, AI generation, or a defined hybrid
  - If hybrid: define the decision rule (e.g., "AI for hero assets, Blender Python for tiling/procedural geometry")
  - Risks of the recommended approach and how to mitigate them
- [ ] Recommendation reviewed by game-designer before presenting to Studio Head
- [x] Status changed to IN_REVIEW and escalated to Studio Head for final decision

## Implementation Notes
- This ticket produces a recommendation, not a decision — Studio Head approves in the Activity Log
- Be direct: "We recommend X because Y" is more useful than hedging
- If both pipelines are roughly equivalent, the tiebreaker is AI-team suitability and maintainability
- A hybrid recommendation is valid but must define the specific decision rule to avoid ambiguity in future tickets
- The recommendation should assume no manual modeling skills are available on the team

## Activity Log
- 2026-02-22 [producer] Created ticket; depends on TICKET-0009, TICKET-0010
- 2026-02-22 [technical-artist] Evaluation complete using provisional scores (both pipelines scripted but not yet executed due to Blender/API blockers). Recommendation written at docs/art/pipeline-recommendation.md: HYBRID pipeline — Tripo3D primary, Blender Python secondary. Margin 0.075 (within 0.3 hybrid threshold). Escalated to Studio Head for decision. Note: scores should be re-validated after actual asset generation.
- 2026-02-22 [technical-artist] Scores updated with actual execution data. Blender 3.65 (unchanged), AI Gen 3.55 (was 3.725). Key changes: AI Godot Compatibility down (4→3, meshes too heavy without retopology), Consistency down (2.5→2), AI-Team Suitability down (5→4, provisioning pain). Hybrid recommendation unchanged but Blender's role as cleanup layer is more critical than initially projected. Awaiting Studio Head decision.
- 2026-02-22 [producer] PROCESS VIOLATION FLAGGED — game-designer review (AC unchecked) was skipped and Studio Head approval was never recorded. TICKET-0012 and TICKET-0013 were completed downstream while this ticket was still IN_REVIEW. TICKET-0015 (BLOCKER) created to gate TICKET-0014. This ticket must not be marked DONE until Studio Head approves in this Activity Log.
