---
id: TICKET-0019
title: "UI style guide and M3 wireframes"
type: DESIGN
status: DONE
priority: P1
owner: ui-ux-designer
created_by: producer
created_at: 2026-02-22
updated_at: 2026-02-23
milestone: "M3"
depends_on: []
blocks: [TICKET-0024, TICKET-0025, TICKET-0027, TICKET-0028]
tags: [ui, design, hud, inventory, compass]
---

## Summary
Define the visual language for all game UI and produce wireframe specs for every M3 HUD and menu element. The existing `docs/design/ui-style-guide.md` is a stub — this ticket fills it. Programmers implement from these specs, so wireframes must be precise enough to build from without guesswork.

## Acceptance Criteria
- [x] UI style guide completed at `docs/design/ui-style-guide.md` covering: color palette, font choices, panel/container styles, spacing/margin conventions, opacity/transparency rules, icon style guidelines
- [x] Wireframe: Compass — horizontal bar or ring showing cardinal directions, ping markers with distance readout when player faces a ping's general direction
- [x] Wireframe: Battery bar — always-visible suit energy indicator, visual states for full/draining/critical/empty
- [x] Wireframe: Scanner Phase 2 analysis readout — purity (1–5 stars), density (Low/Med/High), energy cost; layout and positioning relative to the analyzed deposit
- [x] Wireframe: Mining progress indicator — progress bar or fill shown during hold-to-extract
- [x] Wireframe: Resource pickup notification — brief popup showing item name and quantity collected
- [x] Wireframe: Inventory screen — 15-slot grid, stack count display, open/close toggle, layout and positioning
- [x] All wireframes specify screen region (top, bottom, center), anchor behavior, and approximate pixel dimensions
- [x] Wireframes delivered as images or annotated diagrams at `docs/design/wireframes/m3/`

## Implementation Notes
- Reference `docs/design/gdd.md` for visual tone: stylized sci-fi, Outer Wilds / Hades aesthetic
- Reference `docs/design/systems/meaningful-mining.md` for scanner and mining UI requirements
- Reference `docs/design/systems/player-suit.md` for battery behavior and states
- The compass must support ping markers that appear and fade — design should account for 0 to ~10 simultaneous markers
- First-person perspective only for M3 — no third-person HUD variants needed
- Inventory is a pause/overlay screen, not always visible
- Keep the HUD minimal — the game emphasizes exploration, not UI clutter

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-22 [producer] Created ticket
- 2026-02-22 [ui-ux-designer] Implemented: UI style guide at `docs/design/ui-style-guide.md` (264 lines); 7 wireframe specs at `docs/design/wireframes/m3/` (compass, battery-bar, scanner-readout, mining-progress, pickup-notification, inventory, hud-layout-overview). Committed `1331206`, merged to main via PR #5 (worktree-shimmering-wibbling-trinket).
- 2026-02-23 [producer] Status corrected to DONE — implementation confirmed in main.
- 2026-02-25 [producer] Archived
