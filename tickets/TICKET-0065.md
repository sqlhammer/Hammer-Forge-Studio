---
id: TICKET-0065
title: "UI/UX — tech tree, Fabricator panel, minigame overlay, drone programming UI, third-person HUD"
type: DESIGN
status: OPEN
priority: P1
owner: ui-ux-designer
created_by: producer
created_at: 2026-02-24
updated_at: 2026-02-24
milestone: "M5"
milestone_gate: "M4"
phase: "Foundation"
depends_on: []
blocks: [TICKET-0068, TICKET-0069, TICKET-0070, TICKET-0071, TICKET-0072]
tags: [ui, ux, design, wireframes, tech-tree, fabricator, drones, minigame]
---

## Summary
Produce all UI/UX wireframes and style-compliant designs for M5's new screens and overlays. This is the design gate for the entire Gameplay phase — no implementation ticket may begin until the relevant design is approved. Five distinct design deliverables are required.

## Acceptance Criteria
- [ ] **Tech tree UI:** Node graph layout, unlock flow (resource cost display, confirm unlock action, locked/unlocked visual states), gamepad-navigable
- [ ] **Fabricator interaction panel:** Job queue, recipe selection, input/output display, job progress bar, collect output — consistent with Recycler panel design (M4)
- [ ] **Mining minigame overlay:** Line tracing display on deposit geometry, success/fail state, bonus yield notification — must be legible in first-person HUD
- [ ] **Drone programming UI:** Program configuration screen (deposit type filter, purity filter, tool tier, extraction radius, priority order), drone status display, active drone count
- [ ] **Third-person scan/mine HUD:** Scanner and mining action prompts and feedback adapted for third-person camera perspective
- [ ] All designs follow M3 style guide (`docs/design/systems/` UI references)
- [ ] All designs specify gamepad input as first-class (legible at TV viewing distance, navigable with analog stick)
- [ ] Wireframes delivered as design assets or annotated docs in `docs/design/wireframes/m5/`

## Implementation Notes
- Reference M4 Recycler panel design as the baseline for the Fabricator panel (consistency over novelty)
- Reference `docs/design/systems/meaningful-mining.md` for mining minigame and scanner UX spec
- The tech tree node graph should communicate node state clearly: locked (dimmed), unlockable (highlighted), unlocked (filled)
- Drone programming UI must surface enough information for the player to make strategic decisions without overwhelming them
- Third-person HUD adapts existing scanner/mining prompts — do not redesign the underlying systems, only the camera-perspective-specific presentation

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-24 [producer] Created ticket
