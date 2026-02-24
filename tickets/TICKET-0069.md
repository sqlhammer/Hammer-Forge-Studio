---
id: TICKET-0069
title: "Fabricator interaction panel UI"
type: FEATURE
status: OPEN
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-24
updated_at: 2026-02-24
milestone: "M5"
milestone_gate: "M4"
phase: "Gameplay"
depends_on: [TICKET-0061, TICKET-0065, TICKET-0067, TICKET-0078, TICKET-0083]
blocks: [TICKET-0075]
tags: [fabricator, ui, gameplay, interaction-panel]
---

## Summary
Implement the Fabricator interaction panel — the in-world UI the player opens by interacting with the physical Fabricator machine in the ship interior. Follows the same interaction pattern as the Recycler panel (M4). Allows the player to select recipes, queue jobs, monitor progress, and collect finished output. Requires the Fabricator mesh (TICKET-0067) to be placed in scene before the interaction trigger can be wired.

## Acceptance Criteria
- [ ] Player can interact with the Fabricator mesh in the ship interior to open the panel
- [ ] Panel displays available recipes: Spare Battery, Head Lamp
- [ ] Each recipe shows: name, input requirements (item + quantity), output, duration
- [ ] Recipes with insufficient input materials are shown as unavailable (dimmed)
- [ ] Player can queue a job for an available recipe; inputs are deducted on queue
- [ ] Active job shows progress bar and time remaining
- [ ] On completion: output item delivered to ship inventory; notification displayed
- [ ] Player can close the panel at any time (job continues running while panel is closed)
- [ ] Fully navigable with gamepad; mouse/keyboard also supported
- [ ] Panel is consistent in layout and interaction model with the Recycler panel (M4)
- [ ] References `FabricatorModule` from TICKET-0061 for all state and job calls
- [ ] All code follows `docs/engineering/coding-standards.md`

## Implementation Notes
- Reference wireframes from TICKET-0065
- Reference M4 Recycler panel implementation for consistency — reuse patterns, not necessarily code
- The Fabricator must have an `InteractionArea` node in scene (placed by technical-artist in TICKET-0067) to wire the open/close trigger
- The panel does not need to be open for jobs to run — fire-and-forget model consistent with Recycler

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-24 [producer] Created ticket
- 2026-02-24 [producer] Added TICKET-0078 to depends_on — wireframes must be updated for non-pause model (DEC-0001) before implementation begins
