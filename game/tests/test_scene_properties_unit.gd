## Data-driven scene property validation tests. Loads .tscn files and asserts on
## node properties — anchor presets, collision shape types, group membership, and
## node existence. Prevents the entire class of defects seen in M7 hotfixes
## (TICKET-0152, 0154, 0155, 0156).
class_name TestScenePropertiesUnit
extends TestSuite


# ── Constants ─────────────────────────────────────────────
const ANCHOR_PRESET_TOP_LEFT: int = 0
const ANCHOR_PRESET_BOTTOM_RIGHT: int = 3
const ANCHOR_PRESET_CENTER_TOP: int = 5
const ANCHOR_PRESET_BOTTOM_WIDE: int = 12
const ANCHOR_PRESET_FULL_RECT: int = 15
const ANCHOR_PRESET_CENTER: int = 8


# ── Private Variables ─────────────────────────────────────
var _specs: Array = []


# ── Test Registration ─────────────────────────────────────

func register_tests() -> void:
	_build_specs()
	for spec in _specs:
		var scene_spec: ScenePropertySpec = spec as ScenePropertySpec
		add_test(scene_spec.test_name, _run_property_check.bind(scene_spec))


# ── Test Methods ──────────────────────────────────────────

func _run_property_check(spec: ScenePropertySpec) -> void:
	var scene: PackedScene = load(spec.scene_path) as PackedScene
	if not scene:
		assert_true(false, "Could not load scene: %s" % spec.scene_path)
		return

	var root: Node = scene.instantiate()
	if not root:
		assert_true(false, "Could not instantiate scene: %s" % spec.scene_path)
		return

	add_child(root)

	match spec.check_type:
		"property":
			_check_property(root, spec)
		"node_exists":
			_check_node_exists(root, spec)
		"node_has_group":
			_check_node_has_group(root, spec)
		"collision_shape_type":
			_check_collision_shape_type(root, spec)
		"no_collision_shape_type":
			_check_no_collision_shape_type(root, spec)
		"child_type_exists":
			_check_child_type_exists(root, spec)

	root.queue_free()


# ── Check Implementations ─────────────────────────────────

func _check_property(root: Node, spec: ScenePropertySpec) -> void:
	var target: Node = _resolve_node(root, spec.node_path)
	if not target:
		assert_true(false, "%s: node '%s' not found in %s" % [
			spec.test_name, spec.node_path, spec.scene_path])
		return

	var actual: Variant = target.get(spec.property_name)
	assert_equal(actual, spec.expected_value,
		"%s: %s.%s" % [spec.test_name, spec.node_path, spec.property_name])


func _check_node_exists(root: Node, spec: ScenePropertySpec) -> void:
	var target: Node = _resolve_node(root, spec.node_path)
	assert_not_null(target, "%s: expected node '%s' in %s" % [
		spec.test_name, spec.node_path, spec.scene_path])


func _check_node_has_group(root: Node, spec: ScenePropertySpec) -> void:
	var target: Node = _resolve_node(root, spec.node_path)
	if not target:
		assert_true(false, "%s: node '%s' not found in %s" % [
			spec.test_name, spec.node_path, spec.scene_path])
		return

	var group_name: String = spec.expected_value as String
	assert_true(target.is_in_group(group_name),
		"%s: node '%s' should be in group '%s'" % [
			spec.test_name, spec.node_path, group_name])


func _check_collision_shape_type(root: Node, spec: ScenePropertySpec) -> void:
	var found_valid: bool = false
	var shapes: Array[Node] = _find_nodes_of_type(root, "CollisionShape3D")
	var expected_type: String = spec.expected_value as String

	if shapes.is_empty():
		assert_true(false, "%s: no CollisionShape3D found in %s" % [
			spec.test_name, spec.scene_path])
		return

	for shape_node: Node in shapes:
		var col_shape: CollisionShape3D = shape_node as CollisionShape3D
		if col_shape.shape == null:
			continue
		var shape_class: String = col_shape.shape.get_class()
		if shape_class == expected_type:
			found_valid = true
			break

	assert_true(found_valid, "%s: expected at least one %s in %s" % [
		spec.test_name, expected_type, spec.scene_path])


func _check_no_collision_shape_type(root: Node, spec: ScenePropertySpec) -> void:
	var shapes: Array[Node] = _find_nodes_of_type(root, "CollisionShape3D")
	var forbidden_type: String = spec.expected_value as String

	for shape_node: Node in shapes:
		var col_shape: CollisionShape3D = shape_node as CollisionShape3D
		if col_shape.shape == null:
			continue
		var shape_class: String = col_shape.shape.get_class()
		# Skip RechargeZone shapes — BoxShape3D is valid for Area3D trigger volumes
		var parent: Node = col_shape.get_parent()
		if parent is Area3D:
			continue
		assert_false(shape_class == forbidden_type,
			"%s: found forbidden %s on '%s' in %s" % [
				spec.test_name, forbidden_type, col_shape.name, spec.scene_path])


func _check_child_type_exists(root: Node, spec: ScenePropertySpec) -> void:
	var target: Node = _resolve_node(root, spec.node_path)
	if not target:
		assert_true(false, "%s: node '%s' not found in %s" % [
			spec.test_name, spec.node_path, spec.scene_path])
		return

	var expected_type: String = spec.expected_value as String
	var children: Array[Node] = _find_nodes_of_type(target, expected_type)
	assert_true(children.size() > 0,
		"%s: expected child of type %s under '%s' in %s" % [
			spec.test_name, expected_type, spec.node_path, spec.scene_path])


# ── Helpers ───────────────────────────────────────────────

func _resolve_node(root: Node, node_path: String) -> Node:
	if node_path == "" or node_path == ".":
		return root
	return root.get_node_or_null(NodePath(node_path))


func _find_nodes_of_type(root: Node, type_name: String) -> Array[Node]:
	var result: Array[Node] = []
	_collect_nodes_of_type(root, type_name, result)
	return result


func _collect_nodes_of_type(node: Node, type_name: String, result: Array[Node]) -> void:
	if node.get_class() == type_name or node.is_class(type_name):
		result.append(node)
	for child: Node in node.get_children():
		_collect_nodes_of_type(child, type_name, result)


# ── Spec Builder ──────────────────────────────────────────

func _build_specs() -> void:
	_specs.clear()
	_build_game_hud_specs()
	_build_interaction_prompt_hud_specs()
	_build_ship_exterior_specs()
	_build_ship_interior_specs()
	_build_deep_resource_node_specs()
	_build_navigation_console_specs()


func _build_game_hud_specs() -> void:
	# HUDRoot — full-rect anchor (prevents TICKET-0152/0156 class defects)
	_specs.append(ScenePropertySpec.create_property(
		"game_hud_root_anchors_preset",
		"res://scenes/ui/game_hud.tscn",
		"HUDRoot",
		"anchors_preset",
		ANCHOR_PRESET_FULL_RECT
	))
	_specs.append(ScenePropertySpec.create_property(
		"game_hud_root_anchor_right",
		"res://scenes/ui/game_hud.tscn",
		"HUDRoot",
		"anchor_right",
		1.0
	))
	_specs.append(ScenePropertySpec.create_property(
		"game_hud_root_anchor_bottom",
		"res://scenes/ui/game_hud.tscn",
		"HUDRoot",
		"anchor_bottom",
		1.0
	))
	_specs.append(ScenePropertySpec.create_property(
		"game_hud_root_mouse_filter",
		"res://scenes/ui/game_hud.tscn",
		"HUDRoot",
		"mouse_filter",
		2  # MOUSE_FILTER_IGNORE
	))

	# CompassBar — center-top anchor
	_specs.append(ScenePropertySpec.create_property(
		"game_hud_compass_bar_anchors_preset",
		"res://scenes/ui/game_hud.tscn",
		"HUDRoot/CompassBar",
		"anchors_preset",
		ANCHOR_PRESET_CENTER_TOP
	))

	# MiningProgress — center anchor
	_specs.append(ScenePropertySpec.create_property(
		"game_hud_mining_progress_anchors_preset",
		"res://scenes/ui/game_hud.tscn",
		"HUDRoot/MiningProgress",
		"anchors_preset",
		ANCHOR_PRESET_CENTER
	))

	# MiningMinigameOverlay — center anchor
	_specs.append(ScenePropertySpec.create_property(
		"game_hud_mining_minigame_overlay_anchors_preset",
		"res://scenes/ui/game_hud.tscn",
		"HUDRoot/MiningMinigameOverlay",
		"anchors_preset",
		ANCHOR_PRESET_CENTER
	))

	# BatteryBar — bottom-left (anchor_top = 1.0, anchor_bottom = 1.0)
	_specs.append(ScenePropertySpec.create_property(
		"game_hud_battery_bar_anchor_top",
		"res://scenes/ui/game_hud.tscn",
		"HUDRoot/BatteryBar",
		"anchor_top",
		1.0
	))
	_specs.append(ScenePropertySpec.create_property(
		"game_hud_battery_bar_anchor_bottom",
		"res://scenes/ui/game_hud.tscn",
		"HUDRoot/BatteryBar",
		"anchor_bottom",
		1.0
	))

	# FuelGauge — bottom-center
	_specs.append(ScenePropertySpec.create_property(
		"game_hud_fuel_gauge_anchor_left",
		"res://scenes/ui/game_hud.tscn",
		"HUDRoot/FuelGauge",
		"anchor_left",
		0.5
	))
	_specs.append(ScenePropertySpec.create_property(
		"game_hud_fuel_gauge_anchor_top",
		"res://scenes/ui/game_hud.tscn",
		"HUDRoot/FuelGauge",
		"anchor_top",
		1.0
	))


func _build_interaction_prompt_hud_specs() -> void:
	# ContextualPrompt — bottom-wide anchor (preset 12)
	_specs.append(ScenePropertySpec.create_property(
		"interaction_prompt_contextual_anchors_preset",
		"res://scenes/ui/interaction_prompt_hud.tscn",
		"ContextualPrompt",
		"anchors_preset",
		ANCHOR_PRESET_BOTTOM_WIDE
	))

	# PersistentControls — bottom-right anchor (preset 3)
	_specs.append(ScenePropertySpec.create_property(
		"interaction_prompt_persistent_controls_anchors_preset",
		"res://scenes/ui/interaction_prompt_hud.tscn",
		"PersistentControls",
		"anchors_preset",
		ANCHOR_PRESET_BOTTOM_RIGHT
	))
	_specs.append(ScenePropertySpec.create_property(
		"interaction_prompt_persistent_controls_anchor_left",
		"res://scenes/ui/interaction_prompt_hud.tscn",
		"PersistentControls",
		"anchor_left",
		1.0
	))
	_specs.append(ScenePropertySpec.create_property(
		"interaction_prompt_persistent_controls_anchor_top",
		"res://scenes/ui/interaction_prompt_hud.tscn",
		"PersistentControls",
		"anchor_top",
		1.0
	))

	# Key prompt nodes exist
	_specs.append(ScenePropertySpec.create_node_exists(
		"interaction_prompt_key_badge_exists",
		"res://scenes/ui/interaction_prompt_hud.tscn",
		"ContextualPrompt/PromptPanel/PromptBox/KeyBadge"
	))
	_specs.append(ScenePropertySpec.create_node_exists(
		"interaction_prompt_action_label_exists",
		"res://scenes/ui/interaction_prompt_hud.tscn",
		"ContextualPrompt/PromptPanel/PromptBox/ActionLabel"
	))


func _build_ship_exterior_specs() -> void:
	# Ship exterior collision body must NOT have BoxShape3D on the StaticBody3D
	# (prevents TICKET-0154 regression — collision shapes regressed to BoxShape3D)
	# Note: Area3D children (RechargeZone) are excluded from this check
	_specs.append(ScenePropertySpec.create_no_collision_shape(
		"ship_exterior_no_box_collision",
		"res://scenes/objects/ship_exterior.tscn",
		"BoxShape3D"
	))

	# Ship exterior root is a StaticBody3D with correct collision layer
	_specs.append(ScenePropertySpec.create_property(
		"ship_exterior_collision_layer",
		"res://scenes/objects/ship_exterior.tscn",
		".",
		"collision_layer",
		4
	))

	# EntranceDoor marker exists
	_specs.append(ScenePropertySpec.create_node_exists(
		"ship_exterior_entrance_door_exists",
		"res://scenes/objects/ship_exterior.tscn",
		"EntranceDoor"
	))

	# RechargeZone exists
	_specs.append(ScenePropertySpec.create_node_exists(
		"ship_exterior_recharge_zone_exists",
		"res://scenes/objects/ship_exterior.tscn",
		"RechargeZone"
	))


func _build_ship_interior_specs() -> void:
	# CockpitConsole child exists
	_specs.append(ScenePropertySpec.create_node_exists(
		"ship_interior_cockpit_console_exists",
		"res://scenes/gameplay/ship_interior.tscn",
		"CockpitConsole"
	))

	# All four ship status displays exist
	var display_names: Array[String] = [
		"PowerDisplay", "IntegrityDisplay", "HeatDisplay", "OxygenDisplay"
	]
	for display_name: String in display_names:
		_specs.append(ScenePropertySpec.create_node_exists(
			"ship_interior_%s_exists" % display_name.to_snake_case(),
			"res://scenes/gameplay/ship_interior.tscn",
			display_name
		))


func _build_deep_resource_node_specs() -> void:
	# DeepResourceNode scene properties — infinite yield enabled
	_specs.append(ScenePropertySpec.create_property(
		"deep_resource_node_infinite",
		"res://scenes/objects/deposit_deep.tscn",
		".",
		"infinite",
		true
	))
	_specs.append(ScenePropertySpec.create_property(
		"deep_resource_node_drone_accessible",
		"res://scenes/objects/deposit_deep.tscn",
		".",
		"drone_accessible",
		true
	))


func _build_navigation_console_specs() -> void:
	# Navigation console scene exists and has script
	_specs.append(ScenePropertySpec.create_node_exists(
		"navigation_console_root_exists",
		"res://scenes/ui/navigation_console.tscn",
		"."
	))


# ── Inner Classes ─────────────────────────────────────────

## Specification for a single scene property validation check.
class ScenePropertySpec:
	extends RefCounted

	## Unique test name used for registration and reporting.
	var test_name: String = ""
	## Resource path to the .tscn scene file.
	var scene_path: String = ""
	## Relative node path from the scene root to the target node.
	var node_path: String = ""
	## Type of check to perform: property, node_exists, node_has_group,
	## collision_shape_type, no_collision_shape_type, child_type_exists.
	var check_type: String = ""
	## Property name to query (for property checks).
	var property_name: String = ""
	## Expected value — type depends on check_type.
	var expected_value: Variant = null

	## Creates a property equality check spec.
	static func create_property(
		p_test_name: String,
		p_scene_path: String,
		p_node_path: String,
		p_property_name: String,
		p_expected_value: Variant
	) -> ScenePropertySpec:
		var spec := ScenePropertySpec.new()
		spec.test_name = p_test_name
		spec.scene_path = p_scene_path
		spec.node_path = p_node_path
		spec.check_type = "property"
		spec.property_name = p_property_name
		spec.expected_value = p_expected_value
		return spec

	## Creates a node existence check spec.
	static func create_node_exists(
		p_test_name: String,
		p_scene_path: String,
		p_node_path: String
	) -> ScenePropertySpec:
		var spec := ScenePropertySpec.new()
		spec.test_name = p_test_name
		spec.scene_path = p_scene_path
		spec.node_path = p_node_path
		spec.check_type = "node_exists"
		return spec

	## Creates a group membership check spec.
	static func create_group_check(
		p_test_name: String,
		p_scene_path: String,
		p_node_path: String,
		p_group_name: String
	) -> ScenePropertySpec:
		var spec := ScenePropertySpec.new()
		spec.test_name = p_test_name
		spec.scene_path = p_scene_path
		spec.node_path = p_node_path
		spec.check_type = "node_has_group"
		spec.expected_value = p_group_name
		return spec

	## Creates a collision shape type assertion (at least one of this type exists).
	static func create_collision_shape_check(
		p_test_name: String,
		p_scene_path: String,
		p_expected_shape_type: String
	) -> ScenePropertySpec:
		var spec := ScenePropertySpec.new()
		spec.test_name = p_test_name
		spec.scene_path = p_scene_path
		spec.check_type = "collision_shape_type"
		spec.expected_value = p_expected_shape_type
		return spec

	## Creates a forbidden collision shape type assertion (none of this type on
	## StaticBody3D/RigidBody3D children, Area3D shapes excluded).
	static func create_no_collision_shape(
		p_test_name: String,
		p_scene_path: String,
		p_forbidden_shape_type: String
	) -> ScenePropertySpec:
		var spec := ScenePropertySpec.new()
		spec.test_name = p_test_name
		spec.scene_path = p_scene_path
		spec.check_type = "no_collision_shape_type"
		spec.expected_value = p_forbidden_shape_type
		return spec

	## Creates a child type existence check (at least one descendant of the given
	## type exists under the target node).
	static func create_child_type_check(
		p_test_name: String,
		p_scene_path: String,
		p_node_path: String,
		p_expected_type: String
	) -> ScenePropertySpec:
		var spec := ScenePropertySpec.new()
		spec.test_name = p_test_name
		spec.scene_path = p_scene_path
		spec.node_path = p_node_path
		spec.check_type = "child_type_exists"
		spec.expected_value = p_expected_type
		return spec
