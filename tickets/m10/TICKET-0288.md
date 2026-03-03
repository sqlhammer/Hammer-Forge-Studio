---
id: TICKET-0288
title: "M10 Compass — Narrow resource distance readout cone to 3× ping icon width"
type: TASK
status: OPEN
priority: P2
owner: gameplay-programmer
created_by: producer
created_at: 2026-03-03
updated_at: 2026-03-03
milestone: "M10"
phase: "Implementation"
depends_on: []
blocks: [TICKET-0285]
tags: [compass, hud, scanner, feel]
---

## Summary

The compass distance readout for resource ping markers currently shows whenever the player
faces within `±22.5°` of a deposit (total 45° cone — `DISTANCE_CONE_DEG = 45.0`). This
is too wide: the label can appear for markers nowhere near screen center.

Narrow the trigger zone to **3× the width of the ping icon** (3 × 16 px = 48 px total).
Use a pixel-space comparison against the compass center rather than an angular comparison
so the relationship stays accurate regardless of FOV or compass width changes.

**Scope:** Resource ping markers only. The ship marker's distance readout is unchanged.

---

## Acceptance Criteria

### `compass_bar.gd`

- [ ] Add a new constant that expresses the half-width of the distance readout zone in pixels:
  ```gdscript
  const DISTANCE_CONE_HALF_PX: float = (16.0 * 3.0) / 2.0  # 3× ping icon width, half for each side
  ```
  The `16.0` here must match `ping_size` used when drawing the icon. If `ping_size` is ever
  changed, `DISTANCE_CONE_HALF_PX` must be updated in sync — add an inline comment to that effect.

- [ ] In `_draw_ping_markers()`, replace the angular cone check with a pixel-space check:

  **Remove:**
  ```gdscript
  var angle_diff: float = absf(bearing - player_yaw)
  if angle_diff > 180.0:
      angle_diff = 360.0 - angle_diff
  if angle_diff <= DISTANCE_CONE_DEG / 2.0:
  ```

  **Replace with:**
  ```gdscript
  var center_x: float = COMPASS_WIDTH / 2.0
  if absf(screen_x - center_x) <= DISTANCE_CONE_HALF_PX:
  ```

- [ ] `DISTANCE_CONE_DEG` remains in the file and continues to be used for the **ship marker**
      distance readout in `_draw_ship_marker()` — do not remove it or change the ship marker logic

### No Regressions
- [ ] Resource distance label still appears when the marker is near compass center
- [ ] Resource distance label no longer appears for markers far from compass center
- [ ] Ship distance label behavior is unchanged
- [ ] No visual artifacts — distance label still horizontally centered on the marker

---

## Implementation Notes

**Why pixel-space over angular:** The requirement is "3× the visual width of the arrow on
screen," which is inherently a pixel relationship, not an angular one. Expressing it in
pixels makes the intent clear and keeps the math consistent if `COMPASS_WIDTH` or the
compass FOV changes.

**Current angular equivalent for reference:** With `COMPASS_WIDTH = 600` covering a 180°
FOV, 1° = 600/180 ≈ 3.33 px/°. The new 48 px cone = ~14.4° total, compared to the
current 45°. This is a significant narrowing — approximately 3× tighter.

**ping_size sync:** `ping_size = 16.0` is currently a local variable inside
`_draw_ping_markers()`. If it is promoted to a class constant in the future, update
`DISTANCE_CONE_HALF_PX` to reference it directly:
```gdscript
const PING_ICON_SIZE: float = 16.0
const DISTANCE_CONE_HALF_PX: float = (PING_ICON_SIZE * 3.0) / 2.0
```

---

## Handoff Notes

(Leave blank until handoff occurs.)

---

## Activity Log

- 2026-03-03 [producer] Created ticket — narrow compass distance readout cone to 3× ping icon width
