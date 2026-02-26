---
id: TICKET-0092
title: "Experiment A — Programmatic SVG (Python svgwrite): full icon set, both style guides"
type: TASK
status: DONE
priority: P1
owner: technical-artist
created_by: producer
created_at: 2026-02-25
updated_at: 2026-02-25 (DONE)
milestone: "M6"
milestone_gate: "M5"
phase: "Experiments"
depends_on: [TICKET-0086, TICKET-0088, TICKET-0089, TICKET-0090, TICKET-0091]
blocks: [TICKET-0095]
tags: [icons, experiment, generation, poc]
---

## Summary

Run the first icon generation experiment using Method A (to be determined by TICKET-0088). Produce the **full icon set** — every icon identified in the TICKET-0086 audit — for both the item icon category and the HUD/functional icon category, following their respective style guides (TICKET-0090 and TICKET-0091). Log iteration time and cost throughout.

**Before starting this ticket:** Update the title to replace "[Method TBD]" with the actual method name from TICKET-0088's Selected Methods section.

## Acceptance Criteria

- [ ] Title updated to reflect the actual method name
- [ ] All item icons from the TICKET-0086 audit produced and committed to `docs/art/icon-experiments/method-a/item-icons/`
- [ ] All HUD/functional icons from the TICKET-0086 audit produced and committed to `docs/art/icon-experiments/method-a/hud-icons/`
- [ ] Files named per the naming conventions in TICKET-0090/0091 style guides (e.g., `icon_item_scrap_metal.svg`, `icon_hud_battery.svg`)
- [ ] `docs/art/icon-experiments/method-a/iteration-log.md` created and committed, containing:
  - For each icon: start time, end time, wall-clock duration, any tool cost incurred, and 1-sentence note on any difficulties
  - Total wall-clock time for the full set
  - Total financial cost for the full set
  - Summary of any deviations from the style guide (icons that could not meet the brief and why)
- [ ] Every icon produced at its required output size(s) per the style guide format spec
- [ ] No icons skipped — if a specific icon genuinely cannot be produced by this method, document it in the iteration log as a gap rather than leaving it out silently

## Implementation Notes

- Follow the style guides strictly — the purpose of this experiment is to evaluate how well the method achieves the defined brief, not to create a new aesthetic
- If the method produces multiple output variants for any icon, commit the best one and note alternatives in the iteration log
- Record start and end times before each icon is produced — accurate iteration time data is essential for TICKET-0095 scoring
- Track any financial cost (API calls, subscription usage, etc.) in real time — reconstruct from memory is not sufficient
- Do not evaluate or score your own output — that happens in TICKET-0095

## Handoff Notes

All 29 icons generated via Python script (`scripts/generate_method_a_icons.py`) using direct SVG XML construction. Zero cost, zero human effort, fully deterministic. 9 item icons in `docs/art/icon-experiments/method-a/item-icons/`, 20 HUD icons in `docs/art/icon-experiments/method-a/hud-icons/`. Iteration log at `docs/art/icon-experiments/method-a/iteration-log.md`. 3 minor style guide deviations documented (reduced stroke-width on module detail elements and drone rotors; fill on thermometer bulb per icon list recommendation). No icons skipped. Ready for TICKET-0095 evaluation.

## Activity Log

- 2026-02-25 [producer] Created ticket for M6 Experiments phase
- 2026-02-25 [technical-artist] DONE — 29 SVG icons generated and committed (PR #62, merge commit 29e352a). Iteration log created. All acceptance criteria met.
