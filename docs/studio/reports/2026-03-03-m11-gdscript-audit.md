# M11 GDScript Standards Compliance Audit

**Date:** 2026-03-03
**Auditor:** systems-programmer
**Standard:** `docs/engineering/coding-standards.md`
**Ticket:** TICKET-0289
**Method:** Static analysis only (file reads + pattern matching; no Godot execution)

---

## 1. Executive Summary

**82 files scanned** under `game/` (excluding `game/addons/` and `game/tests/`).

| Metric | Count |
|--------|-------|
| Total files scanned | 82 |
| Files with violations | 31 |
| Fully compliant files | 51 |
| Scene-First Rule violations | 44 (across 25 files) |
| Other standards violations | 21 (across 9 files) |
| **Total violations** | **65** |

**Violation breakdown by severity:**

| Severity | Scene-First | Other | Total |
|----------|-------------|-------|-------|
| HIGH | 21 | 1 | 22 |
| MEDIUM | 12 | 6 | 18 |
| LOW | 11 | 14 | 25 |

**Scene-First Rule violations are the dominant compliance issue.** 25 of 31 non-compliant files have Scene-First violations. The most severe pattern is 13 files that construct their entire UI or scene tree programmatically in `_ready()` via `_build_ui()` chains — the editor scene tree for these files is empty or skeletal while runtime has dozens of nodes. Four `CanvasLayer.new()` instances create persistent overlay layers in code rather than in the scene editor.

The codebase is otherwise well-maintained: zero bare `print()` statements, zero `extends "res://..."` paths, zero naming violations, zero structure order violations, and zero method/expression violations.

---

## 2. Scene-First Rule Violations

> **Rule:** Do not use `.new()` to create nodes that are persistent or semi-persistent parts of the scene. Author them in the scene editor instead. The only acceptable use of `.new()` at runtime is for truly dynamic objects.

### Violation Types

- `READY_SCENE_CONSTRUCTION` — `_ready()` builds the scene tree (multiple `.new()` + `add_child()` calls constructing the hierarchy)
- `NEW_FOR_PERSISTENT` — `.new()` + `add_child()` used for a node that is always present
- `CANVAS_LAYER_NEW` — `CanvasLayer.new()` used for a persistent overlay
- `LAYOUT_IN_READY` — anchors, size, position, visibility, or modulate of a persistent node set in `_ready()` rather than in the editor

### Severity Scale

- `HIGH` — node is persistent/semi-persistent; layout or visibility will be wrong at runtime; entire scene tree constructed in code
- `MEDIUM` — node is created at runtime but could easily be persistent; minor layout risk
- `LOW` — borderline case; minor property set in `_ready()`; acceptable only with justification

### Violations Table

| File | Line(s) | Violation Type | Description | Severity |
|------|---------|----------------|-------------|----------|
| `ship_interior.gd` | 64–559 | `READY_SCENE_CONSTRUCTION` | `_ready()` calls 9 builder methods that construct the **entire** ship interior in code: geometry (~30 StaticBody3D/MeshInstance3D), 4 module zones (Area3D + CollisionShape3D each), spawn markers, cockpit features, SubViewport + Camera3D window, 2 OmniLight3D, terminal Area3D, console prompt area. ~60+ persistent nodes. | HIGH |
| `ship_interior.gd` | 500–510 | `CANVAS_LAYER_NEW` | `CanvasLayer.new()` named "FadeLayer" + `ColorRect.new()` — persistent fade overlay, always present, alpha-toggled | HIGH |
| `game_world.gd` | 74–87 | `NEW_FOR_PERSISTENT` | `WorldEnvironment.new()` + `DirectionalLight3D.new()` — always-present environment/sun nodes created in code | HIGH |
| `game_world.gd` | 225–244 | `NEW_FOR_PERSISTENT` | `Scanner.new()`, `Mining.new()` + `add_child()` — persistent gameplay system nodes, always present | HIGH |
| `game_world.gd` | 231–237 | `CANVAS_LAYER_NEW` | `CanvasLayer.new()` named "ResourceWheelLayer" + `ResourceTypeWheel.new()` — persistent radial wheel overlay | HIGH |
| `game_world.gd` | 272–282 | `NEW_FOR_PERSISTENT` | `ShipEnterZone.new()` + `CollisionShape3D.new()` + `BoxShape3D.new()` — persistent boarding zone for ship | HIGH |
| `game_world.gd` | 303–323 | `NEW_FOR_PERSISTENT` | `DebugShipBoardingHandler.new()`, `TravelSequenceManager.new()` + `add_child()` — persistent system nodes | HIGH |
| `game_world.gd` | 373–385 | `CANVAS_LAYER_NEW` | `CanvasLayer.new()` named "DebugOverlay" + `Label.new()` with font overrides — persistent debug label | MEDIUM |
| `automation_hub_panel.gd` | 88–413 | `READY_SCENE_CONSTRUCTION` | `_ready()` → `_build_ui()` constructs entire panel: dim layer, center container, main panel, title, config/status columns with filter rows, footer with instructions and close button — all persistent | HIGH |
| `automation_hub_panel.gd` | 89–91 | `LAYOUT_IN_READY` | `layer = 2`, `process_mode`, `visible = false` set in `_ready()` | MEDIUM |
| `fabricator_panel.gd` | 74–539 | `READY_SCENE_CONSTRUCTION` | `_ready()` → `_build_ui()` constructs entire panel: dim layer, main panel, recipe list with per-recipe rows, detail column with labeled slots, progress section — all persistent | HIGH |
| `fabricator_panel.gd` | 75–77 | `LAYOUT_IN_READY` | `layer = 2`, `process_mode`, `visible = false` set in `_ready()` | MEDIUM |
| `navigation_console.gd` | 78–585 | `READY_SCENE_CONSTRUCTION` | `_ready()` → `_build_ui()` constructs entire panel: dim layer, main panel, map column with biome node buttons, detail/fuel column with 14+ labels, action bar — all persistent | HIGH |
| `navigation_console.gd` | 79–81 | `LAYOUT_IN_READY` | `layer = 2`, `process_mode`, `visible = false` set in `_ready()` | MEDIUM |
| `module_placement_ui.gd` | 44–233 | `READY_SCENE_CONSTRUCTION` | `_ready()` → `_build_ui()` constructs entire panel: dim layer, main panel, module list, detail panel with cost/power/tech labels, footer — all persistent | HIGH |
| `module_placement_ui.gd` | 45–47 | `LAYOUT_IN_READY` | `layer = 3`, `process_mode`, `visible = false` set in `_ready()` | MEDIUM |
| `recycler_panel.gd` | 47–368 | `READY_SCENE_CONSTRUCTION` | `_ready()` → `_build_ui()` constructs entire panel: dim layer, main panel, slot row, progress section, button row with Start/Collect — all persistent | HIGH |
| `recycler_panel.gd` | 48–50 | `LAYOUT_IN_READY` | `layer = 3`, `process_mode`, `visible = false` set in `_ready()` | MEDIUM |
| `tech_tree_panel.gd` | 65–449 | `READY_SCENE_CONSTRUCTION` | `_ready()` → `_build_ui()` constructs entire panel: dim layer, main panel, node cards with icons, Line2D connectors, detail panel, confirm dialog with overlay — all persistent | HIGH |
| `tech_tree_panel.gd` | 66–68 | `LAYOUT_IN_READY` | `layer = 2`, `process_mode`, `visible = false` set in `_ready()` | MEDIUM |
| `inventory_screen.gd` | 242–451 | `READY_SCENE_CONSTRUCTION` | `_build_ui()` constructs entire screen: dim rect, inventory grid with 15 slots (each PanelContainer + TextureRect + Label), detail panel, ShipStatsSidebar, InventoryActionPopup, destroy confirm dialog — all persistent | HIGH |
| `inventory_screen.gd` | 72–73 | `LAYOUT_IN_READY` | `layer = 2`, `visible = false` set in `_ready()` | LOW |
| `ship_status_display.gd` | 48–159 | `READY_SCENE_CONSTRUCTION` | `_build_display()` constructs entire 3D status panel: MeshInstance3D frame, SubViewport with Panel + 2 Labels + ProgressBar, screen mesh with ViewportTexture — all persistent | HIGH |
| `travel_sequence_manager.gd` | 208–219 | `CANVAS_LAYER_NEW` | `CanvasLayer.new()` named "TravelFadeLayer" + `ColorRect.new()` with anchors preset — persistent fade overlay | HIGH |
| `scanner_readout.gd` | 86–184 | `READY_SCENE_CONSTRUCTION` | `_build_ui()` constructs entire readout: VBoxContainer, icon TextureRect, multiple Labels, HSeparator, 5 star TextureRects, panel style override — all persistent | HIGH |
| `scanner_readout.gd` | 42–43 | `LAYOUT_IN_READY` | `visible = false`, `custom_minimum_size` set in `_ready()` | LOW |
| `ship_globals_hud.gd` | 93–139 | `READY_SCENE_CONSTRUCTION` | `_build_ui()` constructs ship globals panel: PanelContainer with style, title Label, HSeparator, 4 variable rows (each HBoxContainer + TextureRect + ProgressBar + Label) — all persistent | HIGH |
| `ship_globals_hud.gd` | 56–62 | `LAYOUT_IN_READY` | `mouse_filter`, `position.x`, `visible`, `modulate.a` set in `_ready()` | MEDIUM |
| `ship_stats_sidebar.gd` | 60–131 | `READY_SCENE_CONSTRUCTION` | `_build_ui()` constructs entire sidebar: PanelContainer, title, HSeparator, 4 variable rows (each HBoxContainer + TextureRect + ProgressBar + Label), alerts section — all persistent | HIGH |
| `main_menu.gd` | 76–131 | `READY_SCENE_CONSTRUCTION` | `_build_ui()` constructs entire menu: ColorRect background, CenterContainer, VBoxContainer, logo zone, spacers, 4 styled Buttons, footer — all persistent | HIGH |
| `main_menu.gd` | 67–69 | `LAYOUT_IN_READY` | `process_mode` set in `_ready()` | LOW |
| `inventory_action_popup.gd` | 170–248 | `READY_SCENE_CONSTRUCTION` | `_build_ui()` constructs entire popup: PanelContainer, title Label, HSeparator, 3 action rows (each PanelContainer + HBoxContainer + indicator + text), destroy fill ColorRect — all persistent | HIGH |
| `inventory_action_popup.gd` | 59–61 | `LAYOUT_IN_READY` | `visible = false`, `mouse_filter` set in `_ready()` | LOW |
| `interaction_prompt_hud.gd` | 208–329 | `NEW_FOR_PERSISTENT` | `_add_jump_control_row()` and `_add_headlamp_control()` create persistent HBoxContainer rows with Label + ColorRect + Label via `_create_control_row()` — jump row is always present | MEDIUM |
| `interaction_prompt_hud.gd` | 56–57 | `LAYOUT_IN_READY` | `_contextual_prompt.modulate.a = 0.0`, `visible = false` set in `_ready()` | LOW |
| `game_hud.gd` | 146–149 | `NEW_FOR_PERSISTENT` | Crosshair created via `ColorRect.new()` + `add_child()` — always-present HUD element | MEDIUM |
| `game_hud.gd` | 32, 152–172 | `LAYOUT_IN_READY` | `layer = 1` and anchor presets/positions set in `_ready()` for scanner_readout, pickup_notifications, ship_globals nodes | MEDIUM |
| `resource_type_wheel.gd` | 35–37 | `LAYOUT_IN_READY` | `visible = false`, `mouse_filter`, `set_anchors_preset()` set in `_ready()` | MEDIUM |
| `mining_minigame_overlay.gd` | 35–38 | `LAYOUT_IN_READY` | `custom_minimum_size`, `visible = false`, `mouse_filter` set in `_ready()` | LOW |
| `compass_bar.gd` | 41 | `LAYOUT_IN_READY` | `custom_minimum_size` set in `_ready()` | LOW |
| `battery_bar.gd` | 38 | `LAYOUT_IN_READY` | `custom_minimum_size` set in `_ready()` | LOW |
| `fuel_gauge.gd` | 41 | `LAYOUT_IN_READY` | `custom_minimum_size` set in `_ready()` | LOW |
| `mining_progress.gd` | 33 | `LAYOUT_IN_READY` | `custom_minimum_size`, `visible = false` set in `_ready()` | LOW |
| `dropped_item.gd` | 38–149 | `READY_SCENE_CONSTRUCTION` | `_ready()` builds collision shape + visual mesh; however DroppedItem is a dynamic object (spawned/freed at runtime) — borderline acceptable but would benefit from a `.tscn` template | LOW |

**Scene-First totals:** 21 HIGH, 12 MEDIUM, 11 LOW across 25 files.

### Key Pattern

13 files follow an identical anti-pattern: they extend `CanvasLayer` or `Control`, and their `_ready()` calls a `_build_ui()` method that constructs the **entire** panel/screen/menu UI tree using dozens of `.new()` + `add_child()` calls. Every node created is persistent (the panel is shown/hidden, never destroyed). These files should each be refactored into a `.tscn` scene with `@onready` references.

**Files sharing this pattern:** `automation_hub_panel.gd`, `fabricator_panel.gd`, `navigation_console.gd`, `recycler_panel.gd`, `tech_tree_panel.gd`, `module_placement_ui.gd`, `inventory_screen.gd`, `ship_status_display.gd`, `scanner_readout.gd`, `ship_globals_hud.gd`, `ship_stats_sidebar.gd`, `main_menu.gd`, `inventory_action_popup.gd`.

`ship_interior.gd` is the most severe single file — it constructs the entire ship interior (geometry, zones, lighting, viewport, terminal) from ~60+ `.new()` calls, making the editor scene tree a skeleton of its runtime state.

---

## 3. All Other Standards Violations

### Communication

| Category | File | Line(s) | Violation | Description | Severity |
|----------|------|---------|-----------|-------------|----------|
| Communication | `inventory_screen.gd` | 84 | Direct `Input.is_action_just_pressed()` | `Input.is_action_just_pressed("inventory_toggle")` bypasses InputManager. Comment notes this is intentional to bypass suppression, but the standard is unambiguous — should be resolved architecturally (e.g., InputManager exemption mechanism). | HIGH |

### Variable Typing

| Category | File | Line(s) | Violation | Description | Severity |
|----------|------|---------|-----------|-------------|----------|
| Typing | `InputManager.gd` | 180 | Untyped `Array` parameters | `func _add_action_if_missing(action_name: String, keys: Array = [], mouse_buttons: Array = [], joy_buttons: Array = [])` — all three Array params lack element type (should be `Array[int]`) | MEDIUM |
| Typing | `InputManager.gd` | 185 | Untyped loop variable | `for key in keys:` — should be `for key: int in keys:` | MEDIUM |
| Typing | `InputManager.gd` | 189 | Untyped loop variable | `for button in mouse_buttons:` — should be `for button: int in mouse_buttons:` | MEDIUM |
| Typing | `InputManager.gd` | 193 | Untyped loop variable | `for joy_button in joy_buttons:` — should be `for joy_button: int in joy_buttons:` | MEDIUM |
| Typing | `collision_probe.gd` | 79 | Untyped `Array` return type | `func sweep_all_directions(...) -> Array:` — should return `Array[ProbeResult]` | MEDIUM |
| Typing | `collision_probe.gd` | 131 | Untyped `Array` return type | `func sweep_tangential(...) -> Array:` — should return `Array[ProbeResult]` | MEDIUM |
| Typing | `tech_tree_defs.gd` | 53 | Untyped `Array` variable | `var raw: Array = entry.get("prerequisites", [])` — should specify element type | LOW |
| Typing | `terrain_generator.gd` | 208 | Untyped `Array` variable | `var positions: Array = []` — should be `Array[Vector3]` | LOW |
| Typing | `terrain_generator.gd` | 408 | Untyped `Array` variable | `var arrays: Array = chunk.mesh_section.surface_get_arrays(0)` — engine return; could document expected type | LOW |
| Typing | `fabricator_panel.gd` | 508 | Untyped `Array` variable | `var inputs: Array = FabricatorDefs.get_inputs(recipe_id)` — should be `Array[Dictionary]` | LOW |
| Typing | `fabricator_panel.gd` | 614 | Untyped `Array` variable | `var inputs: Array = FabricatorDefs.get_inputs(recipe_id)` — same pattern | LOW |
| Typing | `fabricator_panel.gd` | 692 | Untyped `Array` variable | `var inputs: Array = FabricatorDefs.get_inputs(recipe_id)` — same pattern | LOW |
| Typing | `mining_minigame_overlay.gd` | 82, 99, 121 | Untyped loop variables | `for i in range(...)` — should be `for i: int in range(...)` (3 instances) | LOW |
| Typing | `collision_probe.gd` | 80, 132 | Untyped `Array` variables | `var results: Array = []` — should be `Array[ProbeResult]` (2 instances) | LOW |

### Documentation

| Category | File | Line(s) | Violation | Description | Severity |
|----------|------|---------|-----------|-------------|----------|
| Documentation | `debug_ship_boarding_handler.gd` | 1–4 | `#` used instead of `##` | Lines 1–4 use single `#` comments before `class_name` on line 5. Standard requires `##` docstring format. | MEDIUM |
| Documentation | `game.gd` | 4 | Mixed `#` and `##` | Lines 1–3 use `##` correctly but line 4 uses single `#`. Inconsistent. | LOW |
| Documentation | `inventory_action_popup.gd` | 1 | `#` used instead of `##` | Line 1 uses `#` while lines 2–5 use `##`. First line should also use `##`. | LOW |

### Naming, Script Structure, Debugging, Method & Expression, Editor Compliance

No violations found in these categories.

- **Naming:** All files use `snake_case.gd`. All classes use `PascalCase` `class_name` (autoloads correctly exempt). Variables/functions are `snake_case`, constants are `SCREAMING_SNAKE_CASE`, signals are `past_tense_snake_case`, private members use `_` prefix.
- **Script Structure Order:** All scripts follow the prescribed section order.
- **Debugging:** Zero bare `print()` calls. All debug output uses `Global.debug_log()`.
- **Method & Expression:** Complex expressions are consistently broken into named local variables.
- **Editor Compliance:** No issues discovered during static scan (full editor run not performed for this ticket).

### Observation (Not a Current Standard Violation)

`Input.set_mouse_mode()` is called directly in 10 files (12 instances total). The standard currently prohibits only `Input.is_action_pressed()` / `Input.is_action_just_pressed()` bypasses. However, centralizing mouse mode management through InputManager would improve consistency. Consider adding this to the standard in a future revision.

**Files with `Input.set_mouse_mode()` calls:** `game_world.gd`, `scanner.gd`, `automation_hub_panel.gd`, `fabricator_panel.gd`, `module_placement_ui.gd`, `recycler_panel.gd`, `tech_tree_panel.gd`, `navigation_console.gd`, `inventory_screen.gd` (2 calls each in open/close methods).

---

## 4. Compliant Files

The following 51 files have zero violations across all categories:

**Autoloads (2):**
- `game/autoloads/AgentLogger.gd`
- `game/autoloads/Global.gd`

**Config (1):**
- `game/config/resource_respawn_config.gd`

**Core (1):**
- `game/scripts/core/physics_layers.gd`

**Data (9):**
- `game/scripts/data/biome_data.gd`
- `game/scripts/data/biome_registry.gd`
- `game/scripts/data/drone_agent.gd`
- `game/scripts/data/drone_program.gd`
- `game/scripts/data/fabricator_defs.gd`
- `game/scripts/data/fuel_system_defs.gd`
- `game/scripts/data/module_defs.gd`
- `game/scripts/data/resource_defs.gd`
- `game/scripts/data/tech_tree_defs.gd` *(1 LOW typing issue — untyped Array from Dictionary.get(); included here as borderline compliant)*

**Gameplay (19):**
- `game/scripts/gameplay/biome_archetype_config.gd`
- `game/scripts/gameplay/cockpit_console_prompt_area.gd`
- `game/scripts/gameplay/debris_field_biome.gd`
- `game/scripts/gameplay/debug_launcher.gd`
- `game/scripts/gameplay/deep_resource_node.gd`
- `game/scripts/gameplay/drone_controller.gd`
- `game/scripts/gameplay/drone_manager.gd`
- `game/scripts/gameplay/mining.gd`
- `game/scripts/gameplay/mining_minigame.gd`
- `game/scripts/gameplay/player_first_person.gd`
- `game/scripts/gameplay/player_manager.gd`
- `game/scripts/gameplay/player_third_person.gd`
- `game/scripts/gameplay/rock_warrens_biome.gd`
- `game/scripts/gameplay/scanner.gd`
- `game/scripts/gameplay/shattered_flats_biome.gd`
- `game/scripts/gameplay/ship_enter_zone.gd`
- `game/scripts/gameplay/ship_exit_zone.gd`
- `game/scripts/gameplay/terrain_chunk.gd`
- `game/scripts/gameplay/terrain_feature_request.gd`
- `game/scripts/gameplay/terrain_generation_result.gd`
- `game/scripts/gameplay/world_boundary_manager.gd`

**Objects (2):**
- `game/scripts/objects/cockpit_console.gd`
- `game/scripts/objects/ship_exterior.gd`

**Systems (15):**
- `game/scripts/systems/automation_hub.gd`
- `game/scripts/systems/deposit.gd`
- `game/scripts/systems/deposit_registry.gd`
- `game/scripts/systems/fabricator.gd`
- `game/scripts/systems/fuel_cell.gd`
- `game/scripts/systems/fuel_system.gd`
- `game/scripts/systems/head_lamp.gd`
- `game/scripts/systems/inventory.gd`
- `game/scripts/systems/module_manager.gd`
- `game/scripts/systems/navigation_system.gd`
- `game/scripts/systems/recycler.gd`
- `game/scripts/systems/resource_respawn_system.gd`
- `game/scripts/systems/ship_state.gd`
- `game/scripts/systems/spare_battery.gd`
- `game/scripts/systems/suit_battery.gd`

**UI (1):**
- `game/scripts/ui/pickup_notification.gd`

---

## 5. Remediation Priority Recommendation

### Priority 1 — Scene-First: Full UI Panel Refactors (13 files)

**Blast radius: HIGH | Effort: HIGH | Impact: Highest**

These 13 files all follow the same anti-pattern: entire UI constructed in `_ready()` via `_build_ui()`. Each needs a corresponding `.tscn` scene authored in the editor, with `@onready` references replacing programmatic node creation.

**Recommended grouping into remediation tickets:**

1. **Ship Machine Panels** (similar structure, can share a refactoring template):
   - `recycler_panel.gd`
   - `fabricator_panel.gd`
   - `automation_hub_panel.gd`

2. **Navigation & Module UI**:
   - `navigation_console.gd`
   - `module_placement_ui.gd`

3. **Inventory & Action UI**:
   - `inventory_screen.gd`
   - `inventory_action_popup.gd`

4. **HUD Readouts**:
   - `scanner_readout.gd`
   - `ship_globals_hud.gd`
   - `ship_stats_sidebar.gd`

5. **Tech Tree**:
   - `tech_tree_panel.gd`

6. **Main Menu**:
   - `main_menu.gd`

### Priority 2 — Scene-First: Ship Interior (1 file)

**Blast radius: HIGH | Effort: VERY HIGH | Impact: High**

`ship_interior.gd` constructs the entire ship interior (~60+ nodes) in code. This is the single largest Scene-First violation and should be refactored into a proper `.tscn` scene. Due to the scope (geometry, zones, lighting, viewport, terminal), this is a substantial refactoring effort and should be its own dedicated ticket.

### Priority 3 — Scene-First: GameWorld System Nodes (1 file)

**Blast radius: HIGH | Effort: MEDIUM | Impact: High**

`game_world.gd` creates multiple persistent system nodes via `.new()` (WorldEnvironment, DirectionalLight3D, Scanner, Mining, ShipEnterZone, TravelSequenceManager, DebugShipBoardingHandler). These should be placed as child nodes in the `game_world.tscn` scene, and the CanvasLayer overlays (ResourceWheelLayer, DebugOverlay) should be persistent scene children.

### Priority 4 — Scene-First: Ship Status Display + Travel Fade (2 files)

**Blast radius: MEDIUM | Effort: MEDIUM | Impact: Medium**

- `ship_status_display.gd` — 3D status panel built in code; should be a `.tscn`
- `travel_sequence_manager.gd` — fade overlay CanvasLayer created in code

### Priority 5 — Scene-First: HUD Layout Properties (6 files)

**Blast radius: LOW | Effort: LOW | Impact: Low**

Minor `LAYOUT_IN_READY` violations in `game_hud.gd`, `interaction_prompt_hud.gd`, `resource_type_wheel.gd`, `mining_minigame_overlay.gd`, `compass_bar.gd`, `battery_bar.gd`, `fuel_gauge.gd`, `mining_progress.gd`. Properties like `custom_minimum_size`, `visible`, `mouse_filter`, and anchors should be set in the scene editor. These are low-risk and can be batched into a single cleanup ticket.

### Priority 6 — Communication: InputManager Bypass (1 file)

**Blast radius: LOW | Effort: LOW | Impact: Medium**

`inventory_screen.gd` line 84 directly calls `Input.is_action_just_pressed()`. Requires an architectural solution — either an InputManager exemption mechanism or a separate always-active action check method.

### Priority 7 — Typing: Untyped Arrays and Loop Variables (6 files)

**Blast radius: LOW | Effort: LOW | Impact: Low**

Add element types to `Array` declarations and type annotations to loop variables. Most impactful in `InputManager.gd` (foundational autoload). Can be done as a single batch ticket across: `InputManager.gd`, `collision_probe.gd`, `terrain_generator.gd`, `fabricator_panel.gd`, `mining_minigame_overlay.gd`, `tech_tree_defs.gd`.

### Priority 8 — Documentation: Docstring Format (3 files)

**Blast radius: NONE | Effort: TRIVIAL | Impact: Low**

Fix `#` → `##` docstring format in `debug_ship_boarding_handler.gd`, `game.gd`, `inventory_action_popup.gd`. Single batch ticket.
