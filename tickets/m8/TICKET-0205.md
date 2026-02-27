---
id: TICKET-0205
title: "Bugfix — Ping/scan detection radius is too small; quadruple it"
type: BUGFIX
status: DONE
priority: P2
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "M8"
phase: "QA"
depends_on: []
blocks: []
tags: [bugfix, scanner, ping, radius, balance, m8-qa]
---

## Summary

The scanner ping detection radius is too small. Players must be very close to a resource node before it registers on the compass after a ping. The radius should be quadrupled from its current value to give the ping meaningful range for biome-scale exploration.

## Steps to Reproduce

1. Launch any biome via the debug launcher
2. Stand at a distance from a resource node and perform a ping (Q)
3. Observe: the node does not appear on the compass until the player is already very close to it

## Expected Behavior

After a ping, resource nodes within a generous detection radius (4× the current value) are marked on the compass, allowing the player to locate resources across meaningful distances in the biome.

## Acceptance Criteria

- [x] Ping detection radius is exactly 4× its current value (change the constant, not a magic number)
- [x] Nodes at the new range correctly appear on the compass after a ping
- [x] No regression to ping behavior in any biome
- [x] Full test suite passes with no new failures; update any tests that assert the old radius value

## Implementation Notes

- Locate the constant that defines ping/scan range — likely in the scanner script or a shared game constants file (e.g., `PING_RADIUS`, `SCAN_RANGE`, `DETECTION_RADIUS`)
- Multiply the constant by 4; do not hardcode the new value inline
- Update any unit tests that assert the specific radius value to reflect the new constant
- Verify the compass correctly handles markers at the new extended range (no rendering or clipping issues at distance)

## Activity Log

- 2026-02-27 [producer] Created — Studio Head reported during final M8 playtest review
- 2026-02-27 [gameplay-programmer] Starting work — quadrupling PING_RANGE constant and updating affected tests
