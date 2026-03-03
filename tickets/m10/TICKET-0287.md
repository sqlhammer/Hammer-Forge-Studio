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

### Scene architecture — `ResourceTypeWheel` must become a persistent scene node
- [ ] `ResourceTypeWheel` is added as a persistent child node in the appropriate scene
      (e.g. `game_hud.tscn` or a dedicated overlay scene), **not** instantiated via
      `ResourceTypeWheel.new()` in `game_world.gd`
- [ ] The node starts hidden (`visible = false`) and is shown/hidden by the scanner as
      needed — the existing `show_wheel()` / `hide_wheel()` API is unchanged
- [ ] The `CanvasLayer` + `ResourceTypeWheel.new()` block is removed from `game_world.gd`;
      `scanner.set_resource_wheel()` is called with a reference to the persistent node
      obtained via `get_node()` or an `@onready` export on the scene that owns it
- [ ] `ResourceTypeWheel._ready()` retains `set_anchors_preset(Control.PRESET_FULL_RECT)`
      — this now resolves correctly because the parent is a Control-based scene tree, not
      a bare `CanvasLayer`

### Centering fix
- [ ] The radial wheel renders centered on screen regardless of viewport size
- [ ] Fix works for both keyboard/mouse and gamepad users
- [ ] No visual regression — wheel segments, labels, icons, and highlight arcs all appear
      at the correct positions relative to the new center
- [ ] Fix is robust on viewport resize (does not require a scene reload to re-center)

---

## Fix

**Required approach — move `ResourceTypeWheel` into the scene tree as a persistent node:**

The programmatic instantiation pattern is the root cause. The correct fix is to author
`ResourceTypeWheel` as a scene node placed in the scene editor (or via an instanced
subscene), so Godot's layout engine can resolve its anchors and size normally.

**Step 1:** Add `ResourceTypeWheel` as a child node in `game_hud.tscn` (or an appropriate
overlay scene that is always present). Set anchors to Full Rect in the editor or via
`set_anchors_preset`. The node should be hidden by default.

**Step 2:** In the scene that wires up the scanner (e.g. `game_world.gd`), replace the
current programmatic creation:

```gdscript
# REMOVE:
var wheel_layer := CanvasLayer.new()
wheel_layer.name = "ResourceWheelLayer"
wheel_layer.layer = 5
add_child(wheel_layer)
var resource_wheel := ResourceTypeWheel.new()
resource_wheel.name = "ResourceTypeWheel"
wheel_layer.add_child(resource_wheel)
scanner.set_resource_wheel(resource_wheel)

# REPLACE WITH (exact path depends on scene structure):
var resource_wheel := $HUD/ResourceTypeWheel  # or equivalent node path
scanner.set_resource_wheel(resource_wheel)
```

**Step 3:** Verify `size / 2.0` in `_draw()` now resolves to the correct screen center.
If the layout still does not fill the viewport (e.g. due to a container parent constraining
the size), fall back to `get_viewport_rect().size / 2.0` as a secondary fix.

---

## Handoff Notes

(Leave blank until handoff occurs.)

---

## Activity Log

- 2026-03-03 [producer] Created bug ticket — ping radial wheel offset to upper-left corner
  Root cause: Control parented to CanvasLayer; size stays (0,0); center computed as (0,0)
- 2026-03-03 [producer] Updated fix approach per Studio Head direction:
  ResourceTypeWheel must be a persistent scene node, not programmatically instantiated.
  Removed get_viewport_rect() workaround as primary fix; scene architecture change is required.
