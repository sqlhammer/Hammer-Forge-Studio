---
id: TICKET-0117
title: "Refactor — UI panels and HUD elements as standalone instanced subscenes"
type: REFACTOR
status: DONE
priority: P2
owner: systems-programmer
created_by: producer
created_at: 2026-02-25
updated_at: 2026-02-26
milestone: "M7"
phase: "Refactoring"
depends_on: []
blocks: []
tags: [scene-design, ui, hud, refactor, standards]
---

## Summary
Per the updated Scene Design standard, every conceptual game object — including UI panels and HUD elements — must be its own self-contained `.tscn` scene. Multiple UI scripts exist without corresponding `.tscn` files; their node trees are embedded inline inside parent scenes. This ticket extracts each UI script into its own scene and updates all parent scenes to instance them.

## Scripts to Extract

| Script | Scene to Create | Parent Scene |
|--------|----------------|--------------|
| `scripts/ui/game_hud.gd` | `scenes/ui/game_hud.tscn` | Player scenes |
| `scripts/ui/tech_tree_panel.gd` | `scenes/ui/tech_tree_panel.tscn` | `game_hud.tscn` |
| `scripts/ui/fabricator_panel.gd` | `scenes/ui/fabricator_panel.tscn` | `game_hud.tscn` |
| `scripts/ui/recycler_panel.gd` | `scenes/ui/recycler_panel.tscn` | `game_hud.tscn` |
| `scripts/ui/automation_hub_panel.gd` | `scenes/ui/automation_hub_panel.tscn` | `game_hud.tscn` |
| `scripts/ui/inventory_screen.gd` | `scenes/ui/inventory_screen.tscn` | `game_hud.tscn` |
| `scripts/ui/mining_minigame_overlay.gd` | `scenes/ui/mining_minigame_overlay.tscn` | `game_hud.tscn` |
| `scripts/ui/scanner_readout.gd` | `scenes/ui/scanner_readout.tscn` | `game_hud.tscn` |
| `scripts/ui/battery_bar.gd` | `scenes/ui/battery_bar.tscn` | `game_hud.tscn` |
| `scripts/ui/compass_bar.gd` | `scenes/ui/compass_bar.tscn` | `game_hud.tscn` |
| `scripts/ui/mining_progress.gd` | `scenes/ui/mining_progress.tscn` | `game_hud.tscn` |
| `scripts/ui/pickup_notification.gd` | `scenes/ui/pickup_notification.tscn` | `game_hud.tscn` |
| `scripts/ui/module_placement_ui.gd` | `scenes/ui/module_placement_ui.tscn` | `game_hud.tscn` |
| `scripts/ui/ship_globals_hud.gd` | `scenes/ui/ship_globals_hud.tscn` | `game_hud.tscn` |
| `scripts/ui/ship_stats_sidebar.gd` | `scenes/ui/ship_stats_sidebar.tscn` | `game_hud.tscn` |

## Acceptance Criteria
- [x] All scenes in the table above are created in `game/scenes/ui/`
- [x] Each scene has the correct `Control`-derived root node type matching its function (e.g., `CanvasLayer`, `Panel`, `VBoxContainer`)
- [x] Each scene's script is attached to its root node
- [x] `game_hud.tscn` is the top-level HUD scene; all panel/element scenes are instanced as children of `game_hud.tscn`, not defined inline
- [x] Player scene(s) instance `game_hud.tscn` rather than embedding HUD nodes directly
- [x] All scenes are independently openable in the Godot editor without errors (dummy data or placeholder labels acceptable for isolated preview)
- [x] Existing UI scripts are not modified beyond removing any node-path assumptions that no longer apply after extraction
- [x] All code follows `docs/engineering/coding-standards.md`

## Implementation Notes
- Audit the current player scenes and any existing HUD scene to identify where each UI script is currently attached; extract the node subtree into its own `.tscn`
- Use `CanvasLayer` as the root for `game_hud.tscn` so HUD renders above 3D content
- Individual panel scenes use `Control` or `Panel` root as appropriate; they are added as children of the `CanvasLayer` at runtime or as pre-instanced children in the editor
- This is a structural refactor — do not change UI layout, styling, or behavior; only the scene hierarchy changes

## Handoff Notes
- Created all 15 standalone `.tscn` scene files under `game/scenes/ui/`
- `game_hud.tscn` is a CanvasLayer root that instances all 13 panel/element scenes as children (7 HUD elements under a HUDRoot Control, 6 overlay panels as direct CanvasLayer children)
- `ship_stats_sidebar.tscn` created as standalone scene; remains programmatically instanced by `inventory_screen.gd` (its actual parent in the layout)
- Modified `game_hud.gd`: replaced programmatic `.new()` creation with `@onready` references to scene-instanced children; added getter methods for all panels
- Modified `test_world.gd`: loads `game_hud.tscn` via `preload()` instead of `GameHUD.new()`; retrieves panel references from HUD getters; removed redundant panel creation from `_setup_ship_ui()`
- Crosshair (simple 4×4 ColorRect) remains programmatically created — too trivial for its own scene
- No UI behavior, layout, or styling was changed — structural refactor only

## Activity Log
- 2026-02-25 [producer] Created ticket — standards refactor, self-contained scene rule
- 2026-02-26 [producer] Scheduled into M7 — Ship Interior milestone
- 2026-02-26 [gameplay-programmer] Starting work — IN_PROGRESS
- 2026-02-26 [gameplay-programmer] Implementation complete — created 15 .tscn scenes, refactored game_hud.gd and test_world.gd. Submitting for code review — IN_REVIEW
- 2026-02-26 [systems-programmer] Verified merge complete — commit e832c11 merged to main via PR #85. Marking DONE.
