---
id: TICKET-0310
title: "BUG — compass_bar._on_tree_node_added infinite loop during terrain generation in tests"
type: BUG
status: DONE
priority: P2
owner: gameplay-programmer
created_by: qa-engineer
created_at: 2026-03-03
updated_at: 2026-03-03
milestone: "M11"
phase: "QA"
depends_on: []
blocks: [TICKET-0304]
tags: [compass-bar, hud, test-runner, infinite-loop, regression, m11]
---

## Summary

After TICKET-0300 (M11 HUD layout remediation), `compass_bar.gd` connects to
`get_tree().node_added` in `_ready()` to auto-wire a `ShipExterior` reference. During
`test_travel_sequence_unit`, when `rock_warrens_biome.generate()` adds terrain nodes to the
scene tree, the `_on_tree_node_added` callback fires for each node. If `get_tree()` fails
inside the callback (returns null reference), the signal never disconnects and fires again
for every subsequent node — creating an infinite error loop that prevents the test runner
from completing.

---

## Severity

**P2 — Defect in expected behavior, workaround exists**: The headless test runner hangs on
`test_travel_sequence_unit` and never completes. `test_world_boundary_unit` also does not run.
The game may still function at runtime if `CompassBar` is in the tree before terrain generates,
but this represents fragile initialization order coupling.

---

## Regression Source

**TICKET-0300** introduced the `_on_tree_node_added` signal connection in
`game/scripts/ui/compass_bar.gd`. The callback assumes `get_tree()` is always valid inside
it, but in test scenarios where `CompassBar` may be freed (or is in an intermediate state)
while still connected to `node_added`, `get_tree()` returns null, preventing the disconnect.

---

## Reproduction Steps

1. Run the headless test suite:
   ```
   Godot --headless --path game res://addons/hammer_forge_tests/test_runner.tscn
   ```
2. Observe test runner hangs indefinitely on `test_travel_sequence_unit`
3. The output file grows without bound with repeated:
   ```
   ERROR: Parameter "data.tree" is null.
      at: get_tree (scene/main/node.h:507)
      GDScript backtrace (most recent call first):
          [0] _on_tree_node_added (res://scripts/ui/compass_bar.gd:140)
   ```

---

## Expected Behavior

`_on_tree_node_added` safely handles the case where `get_tree()` may return null (or where the
node is no longer in the tree). The signal disconnects successfully and the test suite completes.

## Actual Behavior

`get_tree()` throws `Parameter "data.tree" is null`, preventing the `disconnect()` call.
The signal remains connected and fires again for each new terrain node, creating an infinite loop.

---

## Suggested Fix

Add a null-safety guard before calling `get_tree()`:
```gdscript
func _on_tree_node_added(node: Node) -> void:
    if not is_inside_tree():
        return
    if is_instance_valid(_ship_target):
        get_tree().node_added.disconnect(_on_tree_node_added)
        return
    if node is ShipExterior:
        set_ship_target(node as Node3D)
        get_tree().node_added.disconnect(_on_tree_node_added)
```

---

## Evidence

Test output from M11 Phase Gate QA run (2026-03-03):
```
ERROR: Parameter "data.tree" is null.
   at: get_tree (scene/main/node.h:507)
   GDScript backtrace:
       [0] _on_tree_node_added (res://scripts/ui/compass_bar.gd:140)
       [1] _build_rock_formations (res://scripts/gameplay/rock_warrens_biome.gd:404)
       [2] generate (res://scripts/gameplay/rock_warrens_biome.gd:193)
       [3] _test_get_biome_player_spawn_returns_valid_position (res://tests/test_travel_sequence_unit.gd:224)
```
(Repeated 1.5M+ times — test runner hung, killed manually)

---

## Files Involved

- `game/scripts/ui/compass_bar.gd` — `_on_tree_node_added()` and `_ready()` signal connection

---

## Activity Log

- 2026-03-03 [qa-engineer] Filed — P2 regression from TICKET-0300; compass_bar.gd causes infinite loop in headless test runner. Prevents test_travel_sequence_unit and test_world_boundary_unit from running. Blocks TICKET-0304 Phase Gate QA sign-off.
- 2026-03-03 [gameplay-programmer] Starting work — adding is_inside_tree() guard to _on_tree_node_added callback.
- 2026-03-03 [gameplay-programmer] DONE — Added is_inside_tree() guard to _on_tree_node_added. Commit 32290db, PR https://github.com/sqlhammer/Hammer-Forge-Studio/pull/344 (merged).
