---
id: TICKET-0024
title: "Scanner Phase 1 — ping and compass"
type: FEATURE
status: DONE
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-22
updated_at: 2026-02-22
milestone: "M3"
depends_on: [TICKET-0019, TICKET-0022]
blocks: [TICKET-0027]
tags: [scanner, compass, hud, gameplay]
---

## Summary
Implement Scanner Phase 1: the player activates a ping that reveals nearby resource deposits. Detected deposits appear as markers on a compass HUD element, with distance readouts visible when the player faces a marker's general direction. This is the "scanner-first" principle in action — players discover before they act.

## Acceptance Criteria
- [ ] Player presses Scanner input (Q / Left Bumper per input-system.md) to activate a ping
- [ ] Ping expands outward from player position, detecting deposits within range
- [ ] Detected deposits are marked as "pinged" in the deposit system (TICKET-0022)
- [ ] Compass HUD element implemented per wireframe spec (TICKET-0019)
- [ ] Compass shows cardinal directions (N/S/E/W)
- [ ] Ping markers appear on compass at the correct bearing relative to player facing direction
- [ ] Distance measurement displayed on ping markers when player faces the general direction of the ping (within ~45 degree cone)
- [ ] Distance measurement hidden when player faces away from the ping
- [ ] Ping markers persist until the deposit is mined out (depleted)
- [ ] Multiple simultaneous ping markers supported (up to ~10)
- [ ] Ping has a cooldown or is instant-use (architect's choice — document the decision)
- [ ] Ping is free — does not consume suit battery
- [ ] Input routed through InputManager (no direct Input API calls)

## Implementation Notes
- M3 simplification: no radial wheel for resource type selection (only Scrap Metal exists). See `docs/studio/deferred-items.md` for the full Phase 1 design deferred to a future milestone.
- Reference `docs/design/systems/meaningful-mining.md` for full Phase 1 scanner spec
- Reference `docs/design/systems/input-system.md` for scanner input binding (Q / Left Bumper)
- The compass is a Control node anchored to top-center of screen (exact layout per wireframe)
- Ping detection range should be configurable (`@export` or constant)
- Consider using Area3D for ping radius detection, or a simple distance check against all deposits in the scene
- Reference `docs/engineering/coding-standards.md` for naming conventions

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-22 [producer] Created ticket
- 2026-02-22 [gameplay-programmer] Status → IN_PROGRESS
- 2026-02-22 [gameplay-programmer] Implementation complete. Commit f71b964. Status → DONE
- 2026-02-25 [producer] Archived
