---
id: TICKET-0309
title: "BUG — NavigationConsole._biome_node_ids missing debris_field after TICKET-0292"
type: BUG
status: IN_PROGRESS
priority: P2
owner: gameplay-programmer
created_by: qa-engineer
created_at: 2026-03-03
updated_at: 2026-03-03
milestone: "M11"
phase: "QA"
depends_on: []
blocks: [TICKET-0304]
tags: [navigation, console, biome, regression, m11]
---

## Summary

After TICKET-0292 (M11 Scene-First remediation — Navigation Console), the `NavigationConsole`
no longer includes `debris_field` in its available destination biome list. When the player is
in `shattered_flats`, the console should show both `rock_warrens` and `debris_field` as
destinations. Only `rock_warrens` appears.

---

## Severity

**P2 — Defect in expected behavior, workaround exists**: Player cannot travel to Debris Field
biome from the Navigation Console. The Debris Field biome is inaccessible from Shattered Flats.

---

## Regression Source

**TICKET-0292** refactored `NavigationConsole` to a Scene-First approach. The biome node
population logic changed such that `debris_field` is not added to `_biome_node_ids` during
`open_panel()` or similar initialization when current biome is `shattered_flats`.

---

## Reproduction Steps

1. Launch game in Shattered Flats biome (default start)
2. Approach the Navigation Console and interact to open it
3. Observe the list of destination biomes
4. Expected: Both `rock_warrens` and `debris_field` appear
5. Actual: Only `rock_warrens` appears; `debris_field` is absent

---

## Expected Behavior

`NavigationConsole._biome_node_ids` contains both `rock_warrens` and `debris_field` when
current biome is `shattered_flats`.

## Actual Behavior

`_biome_node_ids` does not contain `debris_field`.

---

## Evidence

Test output from M11 Phase Gate QA run (2026-03-03):
```
[66596]   FAIL: console_shows_destination_biomes -- Destination nodes should include debris_field: Expected true but got false
```

---

## Files Involved

- `game/scripts/ui/navigation_console.gd` — biome node discovery / `_biome_node_ids` population
- `game/scenes/ui/navigation_console.tscn` — check biome node scene structure

---

## Activity Log

- 2026-03-03 [qa-engineer] Filed — P2 regression from TICKET-0292; debris_field biome absent from NavigationConsole destinations. Blocks TICKET-0304 Phase Gate QA sign-off.
- 2026-03-03 [gameplay-programmer] Starting work
