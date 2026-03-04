---
id: TICKET-0311
title: "BUG — fabricator_panel.gd Array[Dictionary] type mismatch + travel_sequence_manager.gd missing TravelFadeLayer nodes"
type: BUG
status: DONE
priority: P2
owner: gameplay-programmer
created_by: producer
created_at: 2026-03-04
updated_at: 2026-03-04
milestone: "M11"
phase: "QA"
depends_on: []
blocks: []
tags: [fabricator-panel, travel-sequence-manager, type-mismatch, node-not-found, regression, m11]
---

## Summary

Two runtime errors observed in M11:

1. **`fabricator_panel.gd`** — Assigning a plain `Array` to a typed `Array[Dictionary]` variable triggers a GDScript type error at runtime.
2. **`travel_sequence_manager.gd`** — `@implicit_ready()` crashes because expected child nodes `TravelFadeLayer` and `TravelFadeLayer/TravelFadeRect` are not present in the scene tree at `/root/GameWorld/TravelSequenceManager`.

---

## Severity

**P2 — Defect in expected behavior**: Both errors produce hard failures at startup or on first use. The fabricator panel cannot function with the type mismatch, and the travel sequence is broken entirely if the fade nodes are missing from the scene.

---

## Error Details

### Error 1 — fabricator_panel.gd

```
Trying to assign an array of type "Array" to a variable of type "Array[Dictionary]".
```

A plain untyped `Array` is being assigned to a variable declared as `Array[Dictionary]`. GDScript 2.0 enforces typed array compatibility — assigning an untyped array to a typed array slot is not allowed without an explicit cast.

**Likely cause:** The source array was not declared as `Array[Dictionary]` (e.g., a method returns `Array` or a literal `[]` is used), but the destination variable is typed.

---

### Error 2 — travel_sequence_manager.gd

```
E 0:00:03:975   travel_sequence_manager.gd:50 @ @implicit_ready(): Node not found: "TravelFadeLayer/TravelFadeRect" (relative to "/root/GameWorld/TravelSequenceManager").
E 0:00:03:975   travel_sequence_manager.gd:47 @ @implicit_ready(): Node not found: "TravelFadeLayer" (relative to "/root/GameWorld/TravelSequenceManager").
```

`@implicit_ready()` (lines 47 and 50) calls `get_node()` for `TravelFadeLayer` and `TravelFadeLayer/TravelFadeRect`, but these nodes do not exist as children of `TravelSequenceManager` in the `GameWorld` scene.

**Likely cause:** The `TravelFadeLayer` (CanvasLayer) and `TravelFadeRect` (ColorRect) nodes were either not added to `game_world.tscn` as children of `TravelSequenceManager`, or were moved/removed during a recent scene restructure.

---

## Reproduction Steps

1. Launch the game (`game.tscn` → `GameWorld`).
2. Observe the Godot console output immediately at startup.
3. **Error 1:** Open the fabricator panel — expect the array type error to fire when the panel populates its recipe list.
4. **Error 2:** Errors appear in `@implicit_ready()` before any player input; `TravelSequenceManager` fails to initialize.

---

## Expected Behavior

- `fabricator_panel.gd` assigns an `Array[Dictionary]` (or compatible typed array) without type errors.
- `travel_sequence_manager.gd` successfully resolves `TravelFadeLayer` and `TravelFadeLayer/TravelFadeRect` as children of `TravelSequenceManager` in `GameWorld`.

## Actual Behavior

- GDScript type error fires in `fabricator_panel.gd` when assigning array data.
- `TravelSequenceManager._ready()` crashes with two `Node not found` errors, leaving the travel sequence in a broken state.

---

## Suggested Fix

### fabricator_panel.gd
Find the assignment that triggers the type error and either:
- Change the source to return `Array[Dictionary]`, or
- Add an explicit cast: `variable = (source_array as Array[Dictionary])`

### travel_sequence_manager.gd
Open `game/scenes/gameplay/game_world.tscn` and ensure `TravelSequenceManager` has the following child hierarchy:
```
TravelSequenceManager (Node)
└── TravelFadeLayer (CanvasLayer)
    └── TravelFadeRect (ColorRect)
```
If these nodes were removed or reparented, restore them or update the `get_node()` paths in `travel_sequence_manager.gd` to match the current scene structure.

---

## Files Involved

- `game/scripts/ui/fabricator_panel.gd` — typed array assignment
- `game/scripts/systems/travel_sequence_manager.gd` — lines 47 and 50, `get_node()` calls in `_ready()`
- `game/scenes/gameplay/game_world.tscn` — likely missing `TravelFadeLayer` / `TravelFadeRect` under `TravelSequenceManager`

---

## Activity Log

- 2026-03-04 [producer] Filed — two runtime errors reported: fabricator_panel.gd Array[Dictionary] type mismatch and travel_sequence_manager.gd missing TravelFadeLayer nodes.
- 2026-03-04 [gameplay-programmer] Starting work — fixing both runtime errors.
- 2026-03-04 [gameplay-programmer] DONE — Both fixes applied. (1) fabricator_defs.gd get_inputs() now returns Array[Dictionary] with explicit cast. (2) Added TravelFadeLayer + TravelFadeRect nodes to TravelSequenceManager in game_world.tscn. Commit: a4af7e8, PR: https://github.com/sqlhammer/Hammer-Forge-Studio/pull/353
- 2026-03-04 [qa-engineer] Verified DONE status — code fix merged via PR #353 (commit a4af7e8); ticket file status updated to DONE on main (orphan commit f007393 was not on main branch).
