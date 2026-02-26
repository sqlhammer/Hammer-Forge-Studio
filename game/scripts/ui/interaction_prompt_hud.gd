## HUD overlay for contextual interaction prompts and persistent control hints.
## Driven by raycast from the player camera and area-based proximity detection.
## Owner: gameplay-programmer
class_name InteractionPromptHUD
extends CanvasLayer

# ── Constants ─────────────────────────────────────────────
## Raycast detection range — matches scanner interaction distance
const INTERACTION_RAY_LENGTH: float = 6.0

## Layout
const PROMPT_BOTTOM_MARGIN: float = 80.0
const PERSISTENT_MARGIN: float = 16.0
const KEY_BADGE_SIZE := Vector2(36.0, 36.0)
const KEY_BADGE_BORDER_NORMAL: float = 2.0
const KEY_BADGE_BORDER_HOLD: float = 4.0

## Animation
const FADE_DURATION: float = 0.15

## Colors (consistent with existing HUD palette)
const COLOR_KEY_BG := Color("#1A2736")
const COLOR_KEY_BORDER := Color("#00D4AA")
const COLOR_KEY_TEXT := Color("#F1F5F9")
const COLOR_ACTION_TEXT := Color("#F1F5F9")
const COLOR_PERSISTENT_BG := Color("#1A2736", 0.7)
const COLOR_PERSISTENT_KEY := Color("#00D4AA")
const COLOR_PERSISTENT_LABEL := Color("#94A3B8")

# ── Private Variables ─────────────────────────────────────
var _camera: Camera3D = null
var _player: CharacterBody3D = null
var _current_prompt: Dictionary = {}
var _is_prompt_visible: bool = false
var _fade_tween: Tween = null

# ── Onready Variables ─────────────────────────────────────
@onready var _contextual_prompt: Control = $ContextualPrompt
@onready var _prompt_panel: PanelContainer = $ContextualPrompt/PromptPanel
@onready var _key_badge: Panel = $ContextualPrompt/PromptPanel/PromptBox/KeyBadge
@onready var _key_label: Label = $ContextualPrompt/PromptPanel/PromptBox/KeyBadge/KeyLabel
@onready var _action_label: Label = $ContextualPrompt/PromptPanel/PromptBox/ActionLabel

# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	_contextual_prompt.modulate.a = 0.0
	_contextual_prompt.visible = false

func _process(_delta: float) -> void:
	if not _camera or not _player:
		return
	var prompt: Dictionary = _detect_interaction_prompt()
	_update_prompt_display(prompt)

# ── Public Methods ────────────────────────────────────────

## Initializes the HUD with player camera and body references.
func setup(camera: Camera3D, player: CharacterBody3D) -> void:
	_camera = camera
	_player = player
	Global.log("InteractionPromptHUD: setup complete")

## Updates the active camera reference (used on view mode switch).
func set_camera(camera: Camera3D) -> void:
	_camera = camera

# ── Private Methods ───────────────────────────────────────

func _detect_interaction_prompt() -> Dictionary:
	# First try raycast detection (point-at interactables like deposits)
	var raycast_prompt: Dictionary = _get_raycast_prompt()
	if not raycast_prompt.is_empty():
		return raycast_prompt
	# Fallback: check area-based proximity interactions (ship enter zone, etc.)
	var area_prompt: Dictionary = _get_area_prompt()
	return area_prompt

func _get_raycast_prompt() -> Dictionary:
	var space_state: PhysicsDirectSpaceState3D = _camera.get_world_3d().direct_space_state
	var from: Vector3 = _camera.global_position
	var forward: Vector3 = -_camera.global_transform.basis.z
	var to: Vector3 = from + forward * INTERACTION_RAY_LENGTH
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = PhysicsLayers.INTERACTABLE
	var result: Dictionary = space_state.intersect_ray(query)
	if result.is_empty():
		return {}
	var collider: Object = result.get("collider")
	if not collider:
		return {}
	# Traverse up the node tree looking for get_interaction_prompt()
	var node: Node = collider as Node
	while node:
		if node.has_method("get_interaction_prompt"):
			return node.get_interaction_prompt()
		node = node.get_parent()
	return {}

func _get_area_prompt() -> Dictionary:
	# Check if the player body overlaps any Area3D that provides interaction prompts
	# This covers proximity-based interactions like ship entry zones
	var areas: Array[Area3D] = []
	for group_node: Node in get_tree().get_nodes_in_group("interaction_prompt_source"):
		if group_node is Area3D:
			areas.append(group_node as Area3D)
	for area: Area3D in areas:
		if area.has_method("get_interaction_prompt") and area.get_overlapping_bodies().has(_player):
			return area.get_interaction_prompt()
	return {}

func _update_prompt_display(prompt: Dictionary) -> void:
	if prompt.is_empty():
		if _is_prompt_visible:
			_hide_prompt()
		return
	# Check if prompt content changed
	if prompt != _current_prompt:
		_current_prompt = prompt
		_apply_prompt_content(prompt)
	if not _is_prompt_visible:
		_show_prompt()

func _apply_prompt_content(prompt: Dictionary) -> void:
	var key_text: String = prompt.get("key", "E") as String
	var label_text: String = prompt.get("label", "Interact") as String
	var is_hold: bool = prompt.get("hold", false) as bool
	_key_label.text = key_text
	_action_label.text = label_text
	# Update key badge border thickness based on hold vs tap
	var badge_style: StyleBoxFlat = _key_badge.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	var border_width: float = KEY_BADGE_BORDER_HOLD if is_hold else KEY_BADGE_BORDER_NORMAL
	badge_style.border_width_left = int(border_width)
	badge_style.border_width_right = int(border_width)
	badge_style.border_width_top = int(border_width)
	badge_style.border_width_bottom = int(border_width)
	_key_badge.add_theme_stylebox_override("panel", badge_style)

func _show_prompt() -> void:
	_is_prompt_visible = true
	_contextual_prompt.visible = true
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_contextual_prompt, "modulate:a", 1.0, FADE_DURATION)

func _hide_prompt() -> void:
	_is_prompt_visible = false
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_contextual_prompt, "modulate:a", 0.0, FADE_DURATION)
	_fade_tween.tween_callback(func() -> void:
		_contextual_prompt.visible = false
	)
