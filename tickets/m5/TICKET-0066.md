---
id: TICKET-0066
title: "Ship machine process flow — SOP"
type: TASK
status: DONE
priority: P2
owner: producer
created_by: producer
created_at: 2026-02-24
updated_at: 2026-02-24
milestone: "M5"
milestone_gate: "M4"
phase: "Foundation"
depends_on: []
blocks: []
tags: [process, sop, documentation, ship-machine]
---

## Summary
Document a reusable standard operating procedure (SOP) for introducing any new ship machine to the game. M5 is the first milestone to add a second machine (the Fabricator) alongside the Recycler. Capturing the process now creates a repeatable template that prevents ad-hoc decisions in M6+ and ensures all agents know their responsibilities at each step.

## Acceptance Criteria
- [ ] SOP document created at `docs/studio/sop-ship-machine.md`
- [ ] Document covers all required steps in order:
  - [ ] Physical machine design brief (form factor, size, visual identity, placement zone in ship interior)
  - [ ] 3D mesh production (technical-artist ticket scope, M2 pipeline reference, import and placement checklist)
  - [ ] Interaction panel UI design (ui-ux-designer ticket scope, consistency requirements with existing panels)
  - [ ] Tech tree node definition (id, display name, unlock cost, prerequisites)
  - [ ] Build cost specification (module power draw, weight class, material install cost if any)
  - [ ] Data layer implementation (systems-programmer ticket scope, module base class extension, recipe registration)
  - [ ] Interaction panel implementation (gameplay-programmer ticket scope, signal wiring, job queue behavior)
  - [ ] QA checklist (end-to-end loop test: unlock → install → operate → collect output)
- [ ] Each step identifies the responsible agent and any cross-agent handoff points
- [ ] M5 Fabricator is used as the reference example throughout the document
- [ ] Document reviewed for completeness against M4 Recycler implementation (retro-fit any gaps)

## Implementation Notes
- Use M4 (Recycler) and M5 (Fabricator) as dual reference cases — note where their processes diverged and why
- This SOP does not need Studio Head approval to publish, but should be shared with the team at the start of any milestone adding a new machine
- File path: `docs/studio/sop-ship-machine.md`

## Handoff Notes
(Leave blank until handoff occurs.)

## Handoff Notes
SOP created at `docs/studio/sop-ship-machine.md`. Covers all 8 steps with Fabricator (M5) as primary reference and Recycler (M4) as comparison case. Known gaps from M4 retrofitted in the final section.

## Activity Log
- 2026-02-24 [producer] Created ticket
- 2026-02-24 [producer] Implemented SOP at docs/studio/sop-ship-machine.md. Reviewed M4 Recycler and M5 Fabricator implementations. 8-step process documented with agent matrix, handoff points, file naming conventions, and M4 gap analysis. Status → DONE.
