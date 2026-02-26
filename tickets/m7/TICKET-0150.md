---
id: TICKET-0150
title: "Bugfix — missing UID file for physics_layers.gd"
type: BUGFIX
status: DONE
priority: P2
owner: systems-programmer
created_by: qa-engineer
created_at: 2026-02-26
updated_at: 2026-02-26
milestone: "M7"
phase: "QA"
depends_on: []
blocks: [TICKET-0130]
tags: [uid, physics-layers, process, bugfix, p2]
---

## Summary

`game/scripts/core/physics_layers.gd` was created in TICKET-0144 but the GDScript UID Commit procedure was not followed. The `.gd.uid` sidecar file was never generated or committed. This causes `PhysicsLayers` to be absent from the global script class cache on fresh checkouts, which breaks headless test execution for any test suite referencing `PhysicsLayers`.

## Steps to Reproduce

1. Fresh clone of the repository (or delete `.godot/global_script_class_cache.cfg`)
2. Run: `godot --headless --path game res://addons/hammer_forge_tests/test_runner.tscn`
3. Observe: `Parse Error: Identifier "PhysicsLayers" not declared in the current scope` on `test_collision_coverage_unit.gd`

**Workaround:** Running `godot --headless --path game --import` regenerates the class cache and resolves the issue for that machine. But this does not persist across fresh checkouts.

## Expected Behavior

`physics_layers.gd.uid` exists and is committed to the repository. The `PhysicsLayers` class is discoverable by Godot on any fresh checkout without requiring a manual reimport.

## Actual Behavior

No `.gd.uid` file exists for `game/scripts/core/physics_layers.gd`. Fresh checkouts fail to resolve `PhysicsLayers` in headless mode.

## Acceptance Criteria

- [x] `game/scripts/core/physics_layers.gd.uid` generated and committed
- [x] `PhysicsLayers` appears in the global script class cache after `--import`
- [x] Full test suite passes on a fresh checkout after `--import`

## Implementation Notes

Follow the GDScript UID Commit procedure from CLAUDE.md:
1. Trigger Godot filesystem scan via MCP `execute_editor_script` or `--import`
2. Check for UID file: `git ls-files --others --exclude-standard -- '*.gd.uid'`
3. Commit the UID file

## Activity Log
- 2026-02-26 [qa-engineer] Created — process gap from TICKET-0144 (PhysicsLayers creation); GDScript UID Commit procedure was not followed
- 2026-02-26 [systems-programmer] Starting work — physics_layers.gd.uid exists on disk as untracked file; will commit it
- 2026-02-26 [systems-programmer] DONE — Investigation revealed `game/scripts/core/physics_layers.gd.uid` (uid://onlbdeeejc3u) was already committed in commit 3b0f530 as part of TICKET-0130 (M7 QA full loop, 457/457 pass). All acceptance criteria are satisfied. No additional work required.
