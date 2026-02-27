---
id: TICKET-0169
title: "Fuel consumption HUD — low-fuel warning, tank gauge display"
type: FEATURE
status: PENDING
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "M8"
phase: "Gameplay"
depends_on: [TICKET-0158, TICKET-0165]
blocks: []
tags: [hud, fuel, warning, gauge, m8-gameplay]
---

## Summary

Implement the persistent fuel gauge HUD element. Displays the ship's current fuel level at all times. Shows a low-fuel warning state at ≤25% and a distinct empty state at 0. Follows the wireframe from TICKET-0165.

## Acceptance Criteria

- [ ] Fuel gauge visible in HUD at all times (not only inside ship)
- [ ] Gauge updates in real time when fuel changes (listens to `FuelSystem.fuel_changed` signal)
- [ ] Three visual states: normal (>25%), low-fuel warning (≤25%, amber — consistent with battery warning), empty (0%, distinct color/icon)
- [ ] Low-fuel warning state triggered by `FuelSystem.fuel_low` signal
- [ ] Empty state triggered by `FuelSystem.fuel_empty` signal
- [ ] HUD positioned per TICKET-0165 wireframe — no overlap with compass, battery bar, or other HUD elements
- [ ] Unit tests cover: normal state, low-fuel threshold transition, empty state, signal-driven updates
- [ ] Full test suite passes

## Implementation Notes

- Follow the battery bar implementation as a reference for signal-driven HUD updates and color state transitions
- Fuel gauge should use the same visual language as the battery bar for consistency (bar fill, color tiers)

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created — M8 Gameplay phase
