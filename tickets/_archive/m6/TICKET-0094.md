---
id: TICKET-0094
title: "Experiment C — game-icons.net Library + Scripted Customization: full icon set, both style guides"
type: TASK
status: DONE
priority: P1
owner: technical-artist
created_by: producer
created_at: 2026-02-25
updated_at: 2026-02-25
milestone: "M6"
milestone_gate: "M5"
phase: "Experiments"
depends_on: [TICKET-0086, TICKET-0088, TICKET-0089, TICKET-0090, TICKET-0091]
blocks: [TICKET-0095]
tags: [icons, experiment, generation, poc]
---

## Summary

Run the third icon generation experiment using Method C (to be determined by TICKET-0088). Produce the **full icon set** — every icon identified in the TICKET-0086 audit — for both the item icon category and the HUD/functional icon category, following their respective style guides (TICKET-0090 and TICKET-0091). Log iteration time and cost throughout.

**Before starting this ticket:** Update the title to replace "[Method TBD]" with the actual method name from TICKET-0088's Selected Methods section.

Note: If TICKET-0088 identifies more than 3 viable methods, additional experiment tickets (TICKET-0094+) will be created by the producer before this phase opens. Each additional method follows the same template as this ticket.

## Acceptance Criteria

- [x] Title updated to reflect the actual method name
- [x] All item icons from the TICKET-0086 audit produced and committed to `docs/art/icon-experiments/method-c/item-icons/`
- [x] All HUD/functional icons from the TICKET-0086 audit produced and committed to `docs/art/icon-experiments/method-c/hud-icons/`
- [x] Files named per the naming conventions in TICKET-0090/0091 style guides
- [x] `docs/art/icon-experiments/method-c/iteration-log.md` created and committed, containing:
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

Full 29-icon set produced and committed (a212110, PR #63 merged). 9 item icons in `method-c/item-icons/`, 20 HUD icons in `method-c/hud-icons/`. All SVGs use 24x24 viewBox, stroke-width=2, stroke=currentColor, fill=none (with 3 documented fill exceptions per style guide). Source breakdown: 10 library-adapted, 7 library-inspired, 12 gap-fill (Method A). Total cost: $0.00. Key experiment finding: game-icons.net icons are filled silhouettes — all required complete redraw as stroke-based line art, making the "scripted customization" substantially heavier than expected. Iteration log at `method-c/iteration-log.md`. Generator script at `scripts/generate_method_c_icons.py`. CC BY 3.0 attribution required if this method is selected.

## Activity Log

- 2026-02-25 [producer] Created ticket for M6 Experiments phase
- 2026-02-25 [technical-artist] Searched game-icons.net library for all 29 icon matches; assessed format mismatch (filled silhouettes vs stroke line art)
- 2026-02-25 [technical-artist] Produced full 29-icon set — 10 library-adapted, 7 library-inspired, 12 gap-fill (Method A). Total cost: $0.00
- 2026-02-25 [technical-artist] DONE — committed a212110, PR #63 merged to main. Iteration log and generator script included.
