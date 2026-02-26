---
id: TICKET-0093
title: "Experiment B — Recraft.ai API (AI Vector Generation): full icon set, both style guides"
type: TASK
status: DONE
priority: P1
owner: technical-artist
created_by: producer
created_at: 2026-02-25
updated_at: 2026-02-26
milestone: "M6"
milestone_gate: "M5"
phase: "Experiments"
depends_on: [TICKET-0086, TICKET-0088, TICKET-0089, TICKET-0090, TICKET-0091]
blocks: [TICKET-0095]
tags: [icons, experiment, generation, poc]
---

## Summary

Run the second icon generation experiment using Method B (to be determined by TICKET-0088). Produce the **full icon set** — every icon identified in the TICKET-0086 audit — for both the item icon category and the HUD/functional icon category, following their respective style guides (TICKET-0090 and TICKET-0091). Log iteration time and cost throughout.

**Before starting this ticket:** Update the title to replace "[Method TBD]" with the actual method name from TICKET-0088's Selected Methods section.

## Acceptance Criteria

- [x] Title updated to reflect the actual method name
- [x] All item icons from the TICKET-0086 audit produced and committed to `docs/art/icon-experiments/method-b/item-icons/`
- [x] All HUD/functional icons from the TICKET-0086 audit produced and committed to `docs/art/icon-experiments/method-b/hud-icons/`
- [x] Files named per the naming conventions in TICKET-0090/0091 style guides
- [x] `docs/art/icon-experiments/method-b/iteration-log.md` created and committed, containing:
  - For each icon: start time, end time, wall-clock duration, any tool cost incurred, and 1-sentence note on any difficulties
  - Total wall-clock time for the full set
  - Total financial cost for the full set
  - Summary of any deviations from the style guide (icons that could not meet the brief and why)
- [x] Every icon produced at its required output size(s) per the style guide format spec
- [x] No icons skipped — if a specific icon genuinely cannot be produced by this method, document it in the iteration log as a gap rather than leaving it out silently

## Implementation Notes

- Follow the style guides strictly — the purpose of this experiment is to evaluate how well the method achieves the defined brief
- If the method produces multiple output variants for any icon, commit the best one and note alternatives in the iteration log
- Record start and end times before each icon is produced — accurate iteration time data is essential for TICKET-0095 scoring
- Track any financial cost in real time
- Do not evaluate or score your own output — that happens in TICKET-0095

## Handoff Notes

All 29 icons generated via Recraft.ai API v3 (`recraftv3` model, `vector_illustration/line_art` style) and committed (d09c704, PR #64). Post-processed to normalize viewBox to 24x24, convert all fills to `currentColor`, and remove backgrounds. Iteration log documents per-icon timing (avg 8.2s/icon, 268.4s total), cost ($2.32 successful / $5.52 total incl. failed runs), and 5 style guide deviations (filled-path rendering, high path complexity, coordinate scaling, no perspective control, no accent fills). No icons skipped. Generation scripts committed for reproducibility.

## Activity Log

- 2026-02-25 [producer] Created ticket for M6 Experiments phase
- 2026-02-26 [technical-artist] Generated all 29 icons via Recraft API; post-processed SVGs; iteration log written; committed and merged (d09c704, PR #64). DONE.
