---
id: TICKET-0065
title: "UI/UX — tech tree, Fabricator panel, minigame overlay, drone programming UI, third-person HUD"
type: DESIGN
status: IN_REVIEW
priority: P1
owner: ui-ux-designer
created_by: producer
created_at: 2026-02-24
updated_at: 2026-02-24T09:00:00
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
- [x] **Tech tree UI:** Node graph layout, unlock flow (resource cost display, confirm unlock action, locked/unlocked visual states), gamepad-navigable
- [x] **Fabricator interaction panel:** Job queue, recipe selection, input/output display, job progress bar, collect output — consistent with Recycler panel design (M4)
- [x] **Mining minigame overlay:** Line tracing display on deposit geometry, success/fail state, bonus yield notification — must be legible in first-person HUD
- [x] **Drone programming UI:** Program configuration screen (deposit type filter, purity filter, tool tier, extraction radius, priority order), drone status display, active drone count
- [x] **Third-person scan/mine HUD:** Scanner and mining action prompts and feedback adapted for third-person camera perspective
- [x] All designs follow M3 style guide (`docs/design/systems/` UI references)
- [x] All designs specify gamepad input as first-class (legible at TV viewing distance, navigable with analog stick)
- [x] Wireframes delivered as design assets or annotated docs in `docs/design/wireframes/m5/`

## Implementation Notes
- Reference M4 Recycler panel design as the baseline for the Fabricator panel (consistency over novelty)
- Reference `docs/design/systems/meaningful-mining.md` for mining minigame and scanner UX spec
- The tech tree node graph should communicate node state clearly: locked (dimmed), unlockable (highlighted), unlocked (filled)
- Drone programming UI must surface enough information for the player to make strategic decisions without overwhelming them
- Third-person HUD adapts existing scanner/mining prompts — do not redesign the underlying systems, only the camera-perspective-specific presentation

## Handoff Notes

**Wireframes submitted for game-designer review:** `docs/design/wireframes/m5/`

| Deliverable | File | Blocks |
|-------------|------|--------|
| Tech Tree UI | `tech-tree.md` | TICKET-0068 |
| Fabricator Panel | `fabricator-panel.md` | TICKET-0069 |
| Mining Minigame Overlay | `minigame-overlay.md` | TICKET-0070 |
| Third-Person HUD | `third-person-hud.md` | TICKET-0071 |
| Drone Programming UI | `drone-programming.md` | TICKET-0072 |

**Design decisions:**
- Fabricator panel reuses Recycler slot scene from M4 (consistency; documented in wireframe)
- Tech tree nodes are focusable even when locked so players can read locked node descriptions
- Third-person HUD repositions scanner readout to bottom-center only (no redesign of panel contents)
- Minigame overlay is HUD-only; world-space line rendering delegated to gameplay-programmer
- Drone programming screen uses left/right arrow selectors consistently (same pattern as Fabricator recipe selector) for gamepad navigability

**For gameplay-programmer:** Each wireframe includes an "Exported Properties" table specifying signals and `@export` vars required for logic wiring.

## Activity Log
- 2026-02-24 [producer] Created ticket
- 2026-02-24 [ui-ux-designer] Status → IN_PROGRESS. Beginning wireframe production for all 5 M5 UI deliverables.
- 2026-02-24 [ui-ux-designer] All 5 wireframes complete. Status → IN_REVIEW. Submitted to game-designer for approval. Files: docs/design/wireframes/m5/
