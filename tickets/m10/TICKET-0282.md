---
id: TICKET-0282
title: "M10 Scanner — Animated ping propagation ring with progressive compass reveal (D-015)"
type: TASK
status: OPEN
priority: P2
owner: gameplay-programmer
created_by: producer
created_at: 2026-03-03
updated_at: 2026-03-03
milestone: "M10"
phase: "Implementation"
depends_on: [TICKET-0277]
blocks: [TICKET-0285]
tags: [scanner, vfx, ping, compass, animation]
---

## Summary

Replace the instantaneous ping with an animated propagation system: a visible ring expands
outward from the player at a fixed speed up to a 1000 m hard range limit. Compass markers
appear only as the ping front reaches each deposit — not all at once — giving the player a
spatial reference for why markers appear progressively over several seconds.

---

## Acceptance Criteria

### Ping Ring VFX
- [ ] A visual ring originates at the player position on ping fire and expands outward
- [ ] Ring expansion speed is constant and matches the marker reveal rate exactly
- [ ] Ring has a hard cap at 1000 m radius, then fades out
- [ ] Ring is visible in first-person and third-person views
- [ ] Ring does not obscure gameplay or interfere with the player's ability to see deposits

### Progressive Marker Reveal
- [ ] Compass markers for pinged deposits appear only when the expanding ping front
      reaches their world position, not immediately on ping fire
- [ ] Reveal timing is derived from `distance / ping_speed` — no separate timer per deposit
- [ ] Deposits beyond the 1000 m range cap are never revealed by this ping
- [ ] Multiple deposits at similar distances appear within the same frame (acceptable) —
      do not artificially serialize reveals that happen within the same tick

### No Regressions
- [ ] `ping_completed` signal still emits (may fire at ring-start with full deposit list;
      the progressive reveal is a visual layer only — underlying data is still computed upfront)
- [ ] Ping cooldown still applies from the moment ping fires, not when the ring finishes
- [ ] Existing compass and HUD code that consumes `ping_completed` still works correctly

---

## Implementation Notes

Depends on TICKET-0277 (action renamed from `scan` to `ping`).

The ping propagation is best implemented as a timer/radius system in `scanner.gd`:
- On ping fire, record `_ping_ring_radius = 0.0` and start expanding in `_process(delta)`
- Each deposit's reveal time = `deposit.global_position.distance_to(player) / PING_SPEED`
- Check each frame if `_ping_ring_radius >= deposit_distance` and reveal on first crossing

The ring VFX can be a `MeshInstance3D` with a torus or disc mesh scaled each frame, or a
Godot particle system. Keep it visually distinct from terrain features.

Suggested `PING_SPEED = 100.0` m/s — ring reaches max range in 10 seconds. Tune during QA.

---

## Handoff Notes

(Leave blank until handoff occurs.)

---

## Activity Log

- 2026-03-03 [producer] Created ticket — M10 scanner: animated ping propagation (D-015)
