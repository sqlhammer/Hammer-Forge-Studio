---
id: TICKET-0025
title: "Scanner Phase 2 — analyze deposit"
type: FEATURE
status: DONE
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-22
updated_at: 2026-02-22
milestone: "M3"
depends_on: [TICKET-0019, TICKET-0022]
blocks: [TICKET-0026]
tags: [scanner, analysis, hud, gameplay]
---

## Summary
Implement Scanner Phase 2: the player walks up to a pinged deposit and holds a button to analyze it. Analysis reveals purity, density, and energy cost. This information is displayed as a readout near the deposit. A deposit must be analyzed before it can be mined.

## Acceptance Criteria
- [ ] Player aims at a pinged deposit within close range and holds the Interact input (E / West Button per input-system.md)
- [ ] Analysis takes 2–3 seconds of continuous hold (configurable)
- [ ] Progress indicator shown during analysis hold (simple fill bar or radial)
- [ ] On completion, deposit transitions to "analyzed" state in the deposit system (TICKET-0022)
- [ ] Analysis readout displayed: purity (1–5 stars), density (Low/Med/High), energy cost to mine
- [ ] Readout layout and positioning per wireframe spec (TICKET-0019)
- [ ] Readout persists on the deposit (visible when looking at it) until the deposit is depleted
- [ ] Already-analyzed deposits skip the hold — readout is immediately visible
- [ ] Analysis is free — does not consume suit battery
- [ ] Cannot analyze a deposit that has not been pinged (Phase 1 must come first)
- [ ] Input routed through InputManager (no direct Input API calls)

## Implementation Notes
- Reference `docs/design/systems/meaningful-mining.md` for full Phase 2 scanner spec
- Reference `docs/design/systems/input-system.md` for interact input binding (E / West Button)
- The readout could be a 3D viewport label (Label3D) or a screen-space overlay anchored to the deposit — architect's choice
- Purity and density values come from the deposit's data (set per-instance via `@export` in TICKET-0022)
- Energy cost is derived from deposit tier (all Tier 1 in M3, but the formula should reference tier)
- Proximity detection: raycast from camera center or distance check — must feel natural in first-person
- Reference `docs/engineering/coding-standards.md` for naming conventions

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-22 [producer] Created ticket
- 2026-02-22 [gameplay-programmer] Status → IN_PROGRESS
- 2026-02-22 [gameplay-programmer] Implementation complete. Commit f71b964. Status → DONE
