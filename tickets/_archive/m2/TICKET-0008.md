---
id: TICKET-0008
title: "Asset briefs + PoC evaluation criteria"
type: DESIGN
status: DONE
priority: P1
owner: game-designer
created_by: producer
created_at: 2026-02-22
updated_at: 2026-02-22
milestone: "M2"
depends_on: []
blocks: [TICKET-0009, TICKET-0010]
tags: [art-pipeline, poc, design]
---

## Summary
Define the four target assets for the 3D pipeline PoC and establish the evaluation criteria that will be used to compare the Blender Python approach against AI generation tools. Both PoC teams work from the same briefs — without this, the evaluation is apples-to-oranges.

## Acceptance Criteria
- [x] One asset brief written for each of the 4 target assets (see below)
- [x] Each brief defines: in-game function, approximate scale, visual context, and what "done" looks like for a PoC (not final production quality)
- [x] Evaluation criteria document written covering all dimensions used to compare the two approaches
- [x] Evaluation criteria weighted or ranked so TICKET-0011 can produce a clear recommendation to Studio Head
- [ ] Briefs and criteria reviewed and approved by technical-artist before PoC work begins

## Target Assets

| Asset | In-Game Role |
|-------|-------------|
| Hand drill | Player-held tool used for mining; visible in first-person view |
| Player character | Full-body player mesh; visible in third-person view |
| Ship exterior | Atmospheric ship hull; seen in third-person orbital view |
| Resource node | Scrap metal deposit marker; visible on alien surface |

## Evaluation Criteria Dimensions
At minimum, the criteria document should address:
- **Visual quality** — Does the output meet the game's stylized sci-fi aesthetic?
- **Iteration speed** — How long does one asset take from brief to importable GLB?
- **Consistency** — Can multiple assets from the same pipeline share a coherent visual language?
- **Maintainability** — Can another agent reproduce or modify an asset using the documented process?
- **AI-team suitability** — Does this pipeline work without manual modeling skills?
- **Godot compatibility** — Does output import cleanly with correct scale, UVs, and materials?

## Implementation Notes
- Asset briefs live at `docs/art/asset-briefs/` (create directory)
- Evaluation criteria doc lives at `docs/art/poc-evaluation-criteria.md`
- Do not over-specify briefs — PoC goal is to stress-test the pipeline, not to produce final assets
- Reference `docs/design/gdd.md` for visual tone: stylized sci-fi, reference Outer Wilds / Hades aesthetic
- Weighted scoring is preferred over pass/fail — enables a nuanced recommendation in TICKET-0011

## Activity Log
- 2026-02-22 [producer] Created ticket
- 2026-02-22 [game-designer] Completed all deliverables:
  - Asset briefs: `docs/art/asset-briefs/hand-drill.md`, `player-character.md`, `ship-exterior.md`, `resource-node.md`
  - Evaluation criteria: `docs/art/poc-evaluation-criteria.md` (weighted scoring, 6 dimensions, rubrics, scoring template)
  - All briefs reference GDD aesthetic targets (Outer Wilds / Hades stylized sci-fi)
  - Evaluation uses weighted scoring (Visual Quality 25%, Iteration Speed 20%, Consistency 20%, Godot Compat 15%, AI-Team 10%, Maintainability 10%)
  - Pending: technical-artist review before PoC work begins (AC-5)
- 2026-02-22 [producer] Archived
