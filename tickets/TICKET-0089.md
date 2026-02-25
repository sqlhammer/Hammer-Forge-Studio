---
id: TICKET-0089
title: "Icon evaluation criteria — adapt M2 POC framework for 2D icons"
type: TASK
status: OPEN
priority: P1
owner: producer
created_by: producer
created_at: 2026-02-25
updated_at: 2026-02-25
milestone: "M6"
milestone_gate: "M5"
phase: "Foundation"
depends_on: [TICKET-0086]
blocks: [TICKET-0092, TICKET-0093, TICKET-0094, TICKET-0095]
tags: [icons, evaluation, criteria, foundation, producer]
---

## Summary

This ticket produces the scoring framework used to compare the icon generation experiments (TICKET-0092–0094). It adapts the M2 3D asset PoC evaluation model (`docs/art/poc-evaluation-criteria.md`) for the specific requirements of 2D icon generation, incorporating the Studio Head's three primary goals: **minimize human effort**, **minimize financial cost**, and **maximize quality**.

The output document (`docs/art/icon-evaluation-criteria.md`) is used by TICKET-0095 (technical-artist evaluation) to score every experiment.

## Acceptance Criteria

- [ ] `docs/art/icon-evaluation-criteria.md` created and committed
- [ ] The document defines the same structural elements as the M2 criteria doc: scoring scale (1–5), dimension table with weights, per-dimension rubric with explicit score anchors, scoring template, and additional evaluation notes
- [ ] The following 7 dimensions are included with the specified weights (must sum to 100%):

| # | Dimension | Weight |
|---|-----------|--------|
| 1 | Visual Quality | 25% |
| 2 | Human Effort | 20% |
| 3 | Financial Cost | 20% |
| 4 | Consistency | 15% |
| 5 | Scalability | 10% |
| 6 | Godot Compatibility | 5% |
| 7 | Maintainability | 5% |

- [ ] **Per-dimension rubrics** are defined with score anchors (1–5) appropriate for 2D icons. Key rubric notes:
  - **Visual Quality:** evaluated against the relevant style guide (item guide for item icons, HUD guide for HUD icons). Score reflects match to stylized sci-fi aesthetic defined in the style guide.
  - **Human Effort:** score 5 = fully automated (agent prompt in, icon file out, no human steps); score 1 = requires a human artist for every icon.
  - **Financial Cost:** define score anchors in dollar terms based on a full set (~20 icons). Score 5 = free or negligible cost; score 1 = unacceptably expensive.
  - **Consistency:** evaluated across the full ~20-icon set — do all icons look like they belong to the same visual language?
  - **Scalability:** icons must be legible at 16px (smallest HUD use) through 48px (inventory slot). Score 5 = crisp at all sizes with no rework; score 1 = only usable at one size.
  - **Godot Compatibility:** clean import as SVG or PNG with correct transparency, scale, and no import warnings.
  - **Maintainability:** can another agent produce additional icons (beyond the experiment set) by following the documented SOP? Score 5 = reproducible with SOP alone; score 1 = only the original operator can replicate the results.
- [ ] Scoring template table included (one column per experiment method, populated by TICKET-0095)
- [ ] Recommendation threshold rule included: if top two methods score within 0.3 weighted points, recommend a hybrid approach; if one leads by > 0.3, recommend it as primary
- [ ] Document notes that **each icon is scored individually**, then averaged to the method-level dimension score (same methodology as M2)

## Implementation Notes

- Read `docs/art/poc-evaluation-criteria.md` in full before writing — the M6 criteria doc should mirror its structure so evaluation is familiar to the technical-artist
- The icon needs audit (TICKET-0086) must be complete so you can reference the correct icon count (used in Financial Cost rubric anchors)
- The rubric anchors for Financial Cost should be calibrated to the full icon set size from the audit, not to a per-icon estimate alone

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-25 [producer] Created ticket for M6 Foundation phase
