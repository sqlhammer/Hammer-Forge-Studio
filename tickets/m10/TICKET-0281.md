---
id: TICKET-0281
title: "M10 Scanner — Resource type selection radial wheel before ping (D-001)"
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
tags: [scanner, ui, radial-wheel, ping]
---

## Summary

Add a radial wheel UI that lets the player select which resource type to ping for before
firing the scanner. With two resource types now in the game (Scrap Metal, Cryonite), a
selection step makes ping results meaningful — the ring only reveals deposits matching
the chosen type.

---

## Acceptance Criteria

### Radial Wheel UI
- [ ] Holding the `ping` action (Q / LB) opens the radial wheel; releasing fires the ping
      for the selected resource type
- [ ] The radial wheel displays one segment per known resource type
- [ ] Each segment shows the resource icon and name
- [ ] The player selects a segment by moving the mouse (keyboard) or left stick (gamepad)
- [ ] If the player releases `ping` without moving to a segment, the previously selected
      type is used (last-used memory, defaults to first available on first use)
- [ ] Tapping `ping` without holding fires immediately with the last-used resource type
      (no wheel shown) — preserves fast-play feel

### Scanner Integration
- [ ] `scanner.gd` `_do_ping()` receives the selected resource type and filters results
- [ ] Only deposits matching the selected resource type are pinged and revealed on compass
- [ ] If no type is selected / wheel cancelled, no ping fires

### Keyboard & Gamepad
- [ ] Radial wheel works with mouse direction on keyboard/mouse
- [ ] Radial wheel works with left stick direction on gamepad

### No Regressions
- [ ] Ping cooldown still applies
- [ ] `ping_completed` signal still emits with the filtered deposit array

---

## Implementation Notes

Depends on TICKET-0277 (action renamed from `scan` to `ping`) — use `"ping"` action name
throughout.

The radial wheel is a common Godot UI pattern: a `Control` node that samples input direction
each frame while the action is held and highlights the nearest segment. On release, fire the
ping. This should be implemented as a scene-instanced subscene for cleanliness.

Resource types should be sourced dynamically from a registry (e.g. `DepositRegistry` or a
new `ResourceTypeRegistry`) — do not hardcode Scrap Metal and Cryonite.

---

## Handoff Notes

(Leave blank until handoff occurs.)

---

## Activity Log

- 2026-03-03 [producer] Created ticket — M10 scanner: resource type radial wheel (D-001)
