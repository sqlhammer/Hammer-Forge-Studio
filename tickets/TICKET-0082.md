---
id: TICKET-0082
title: "Bugfix — player blocked from entering ship when standing close to hull"
type: BUG
status: OPEN
priority: P2
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-25
updated_at: 2026-02-25
milestone: "M5"
milestone_gate: "M4"
phase: "Gameplay"
depends_on: [TICKET-0081, TICKET-0083]
blocks: [TICKET-0075]
tags: [bugfix, ship, entry, player, interaction]
---

## Summary

The player cannot trigger ship entry when standing flush against or very close to the hull. The entry interaction fails silently — no prompt or feedback — until the player backs away from the ship. This depends on TICKET-0081 (ship rescale) because the fix must target the final hull geometry and the interaction zone must be validated at the new ship size.

## Acceptance Criteria

- [ ] Player can trigger ship entry from any position within the designated interaction zone, including when standing flush against the hull
- [ ] Entry interaction prompt is visible and functional from all expected approach angles and distances
- [ ] No regression: player cannot trigger ship entry from outside the intended interaction zone
- [ ] Fix validated against the rescaled ship geometry (TICKET-0081 must be DONE before this ticket begins)
- [ ] All existing tests pass — no regressions against M1–M4 suite (284 tests) or any M5 tests added to date

## Implementation Notes

- Likely root causes (investigate in order):
  1. **Raycast clipping** — the interaction raycast originates at the camera and may clip into the hull mesh at close range, missing the `InteractionArea`; try offsetting the ray origin forward or switching to an overlap/proximity check
  2. **Area3D visibility / overlap** — the `InteractionArea` on the ship entrance may require a clear line-of-sight that the player body occludes when pressed against the hull
  3. **Distance gate with incorrect origin** — a simple distance check using ship node origin rather than hull surface will fail when the player is near the hull but far from the ship center
- Interaction entry logic lives in the player script or test world script — locate the ship entry interaction before deciding on the fix approach
- After TICKET-0081 completes, verify the interaction zone Area3D or trigger radius is proportionally correct relative to the new 3× hull size; it likely needs to be repositioned or enlarged

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-25 [producer] Created ticket
