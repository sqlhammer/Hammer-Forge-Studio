---
id: TICKET-0042
title: "UI/UX — ship globals HUD, ship stats sidebar, Recycler panel, interior wireframes"
type: DESIGN
status: OPEN
priority: P1
owner: ui-ux-designer
created_by: producer
created_at: 2026-02-23
updated_at: 2026-02-23
milestone: "M4"
milestone_gate: "M3"
depends_on: []
blocks: [TICKET-0045, TICKET-0046, TICKET-0047]
tags: [ui, ux, design, wireframes]
---

## Summary
Produce wireframes for all new M4 UI surfaces: ship global variable indicators (inside-ship HUD), ship stats sidebar on the inventory screen, Recycler interaction panel, and the minimal greybox ship interior layout. Gameplay programmers block on these wireframes before implementing UI tickets.

## Acceptance Criteria
- [ ] Ship globals HUD display — Power, Integrity, Heat, Oxygen indicators shown when player is inside the ship; layout does not conflict with existing battery bar and compass
- [ ] Ship stats sidebar — compact view of all four global variables appended to the existing inventory screen; visible when player is outside the ship
- [ ] Recycler panel — input slot (resource to process), output slot (processed resource), single active job display with progress indicator, collect button
- [ ] Greybox ship interior layout — floor plan showing walkable area, module placement zone(s), entry/exit point, and approximate dimensions
- [ ] All wireframes consistent with the M3 UI style guide (`docs/design/ui/m3-style-guide.md`)
- [ ] Wireframes delivered and reviewed before Gameplay phase tickets begin

## Implementation Notes
- Reference M3 HUD layout to avoid element conflicts — battery bar is top-left, compass is top-center
- The inventory screen already exists (TICKET-0028) — the ship stats sidebar is an additive change, not a redesign
- Recycler panel interaction model: player opens panel via interact input, navigates with standard UI controls, closes with cancel input
- Interior layout is greybox only — no art direction needed in M4, just spatial planning for placement zones

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-23 [producer] Created ticket
