---
id: TICKET-0287
title: "M10 BUG — Ping radial wheel renders in upper-left corner instead of screen center"
type: BUG
status: OPEN
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-03-03
updated_at: 2026-03-03
milestone: "M10"
phase: "Implementation"
depends_on: []
blocks: [TICKET-0285]
tags: [scanner, radial-wheel, ui, bug]
---

## Summary

The resource-type radial wheel appears in the upper-left corner of the screen instead of
the center. The wheel is partially clipped and unusable.

**Screenshot:** `C:\temp\2026-03-03_12-52-48.png` — arrow marks the wheel in the upper-left.

---

## Root Cause

`ResourceTypeWheel._draw()` computes the wheel center as:

```gdscript
var center: Vector2 = size / 2.0
```

`size` is the Control's layout-resolved size. However, the wheel is instantiated
programmatically and parented to a `CanvasLayer` node (not a Control):

```gdscript
# game_world.gd
var wheel_layer := CanvasLayer.new()
wheel_layer.add_child(resource_wheel)
```

`set_anchors_preset(Control.PRESET_FULL_RECT)` only resolves to the viewport size when
the parent is a Control or the scene root. When parented to a `CanvasLayer`, the anchors
are set but the Control's `size` remains `(0, 0)` — so `size / 2.0` evaluates to `(0, 0)`
and the entire wheel draws from the origin (top-left corner).

---

## Acceptance Criteria

- [ ] The radial wheel renders centered on screen regardless of viewport size
- [ ] Fix works for both keyboard/mouse and gamepad users
- [ ] No visual regression — wheel segments, labels, icons, and highlight arcs all appear
      at the correct positions relative to the new center
- [ ] Fix is robust on viewport resize (does not require a scene reload to re-center)

---

## Fix

**Preferred fix — update `ResourceTypeWheel._draw()` to use the viewport size:**

```gdscript
func _draw() -> void:
    if not visible or _segments.is_empty():
        return

    var viewport_rect: Rect2 = get_viewport_rect()
    var center: Vector2 = viewport_rect.size / 2.0
    # ... rest of draw unchanged
```

`get_viewport_rect()` returns the actual rendered viewport rectangle regardless of the
Control's parent type, making the centering parent-agnostic and resize-safe.

**Alternative fix — set size explicitly in `game_world.gd` after adding the wheel:**

```gdscript
wheel_layer.add_child(resource_wheel)
resource_wheel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
# Force size to viewport on creation and on resize:
resource_wheel.size = get_viewport().get_visible_rect().size
get_viewport().size_changed.connect(func(): resource_wheel.size = get_viewport().get_visible_rect().size)
```

The `get_viewport_rect()` approach in `_draw()` is simpler and preferred.

---

## Handoff Notes

(Leave blank until handoff occurs.)

---

## Activity Log

- 2026-03-03 [producer] Created bug ticket — ping radial wheel offset to upper-left corner
  Root cause: Control parented to CanvasLayer; size stays (0,0); center computed as (0,0)
