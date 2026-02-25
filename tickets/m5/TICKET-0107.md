---
id: TICKET-0107
title: "Bugfix — Mining minigame pattern overlay missing and causes node-not-in-tree errors"
type: BUGFIX
status: DONE
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-25
updated_at: 2026-02-25
milestone: "M5"
phase: "QA"
depends_on: []
blocks: []
tags: [bugfix, mining, minigame, visual, required-feature, crash]
---

## Summary
The mining minigame does not display the required tracing pattern overlay on the resource node. The pattern lines fail to render and throw two errors every time mining starts, because `_create_pattern_lines()` runs before the node is inside the scene tree.

## Errors

```
E 0:00:08:359   mining.gd:254 @ _create_pattern_lines(): Condition "!is_inside_tree()" is true. Returning: Transform3D()
  <C++ Source>  scene/3d/node_3d.cpp:621 @ get_global_transform()
  <Stack Trace> mining.gd:254 @ _create_pattern_lines()
                mining.gd:228 @ _start_minigame()
                mining.gd:166 @ _start_mining()
                mining.gd:135 @ _update_mining()
                mining.gd:73 @ _process()

E 0:00:08:359   mining.gd:255 @ _create_pattern_lines(): Node not inside tree. Use look_at_from_position() instead.
  <C++ Error>   Condition "!is_inside_tree()" is true.
  <C++ Source>  scene/3d/node_3d.cpp:1224 @ look_at()
  <Stack Trace> mining.gd:255 @ _create_pattern_lines()
                mining.gd:228 @ _start_minigame()
                mining.gd:166 @ _start_mining()
                mining.gd:135 @ _update_mining()
                mining.gd:73 @ _process()
```

## Reproduction
1. Approach a resource deposit
2. Begin mining
3. Observe — no pattern overlay appears on the resource
4. Check editor output for the two errors above

## Root Cause
`_create_pattern_lines()` is called from `_start_minigame()` before the pattern line nodes have been added to the scene tree. `get_global_transform()` and `look_at()` both require the node to be inside the tree. The function bails early on line 254, so the pattern is never drawn.

## Fix
- In `_start_minigame()` (mining.gd:228), ensure pattern line nodes are added to the tree **before** `_create_pattern_lines()` is called
- Alternatively, defer `_create_pattern_lines()` until `_ready()` or until the nodes are confirmed in-tree (e.g., via `await get_tree().process_frame` or by adding nodes synchronously before calling the method)
- After fixing the tree-order issue, verify that the pattern overlay is visible on the resource node during the minigame
- Replace `look_at()` with `look_at_from_position()` if any call site requires the node to orient before being in the tree

## Acceptance Criteria
- [ ] No "node not inside tree" errors when mining begins
- [ ] A visible tracing pattern is displayed on the resource node during the minigame
- [ ] Player can see and follow the pattern to complete the minigame
- [ ] No new errors introduced

## Activity Log
- 2026-02-25 [producer] Created from UAT feedback. Pattern overlay is a required feature; errors confirm the root cause is premature node access before tree insertion.
- 2026-02-25 [gameplay-programmer] DONE — reordered _create_pattern_lines() to call deposit.add_child(mesh_inst) before setting global_position and look_at. Commit 9b6e53d, PR #53.
