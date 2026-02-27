## TravelSequenceManager - Orchestrates inter-biome travel transitions: fade to black,
## disable input, unload old biome, load destination biome, reposition player and ship
## at spawn points, fade back in, re-enable input. Listens to NavigationSystem.travel_completed.
## Owner: gameplay-programmer
class_name TravelSequenceManager
extends Node


# ── Signals ──────────────────────────────────────────────

## Emitted when the travel transition sequence begins (fade-out starting).
signal travel_sequence_started(destination_id: String)

## Emitted when the travel transition sequence finishes (fade-in complete, input restored).
signal travel_sequence_completed(destination_id: String)


# ── Constants ─────────────────────────────────────────────

## Duration of the fade-to-black and fade-from-black transitions in seconds.
const FADE_DURATION: float = 0.5


# ── Private Variables ─────────────────────────────────────

## Whether a travel transition is currently in progress.
var _is_transitioning: bool = false

## Reference to the player root node for repositioning on arrival.
var _player: Node3D = null

## Reference to the ship exterior for repositioning on arrival.
var _ship_exterior: ShipExterior = null

## Container node whose children are replaced on biome swap.
var _biome_container: Node3D = null

## The currently active biome scene node inside _biome_container.
var _current_biome_node: Node3D = null

## CanvasLayer for the full-screen fade overlay.
var _fade_layer: CanvasLayer = null

## ColorRect used as the fade-to-black overlay.
var _fade_rect: ColorRect = null


# ── Public Methods ────────────────────────────────────────

## Initialises the travel sequence manager with references to the player,
## ship exterior, and biome container. Connects to NavigationSystem signals.
func setup(player: Node3D, ship_exterior: ShipExterior, biome_container: Node3D) -> void:
	_player = player
	_ship_exterior = ship_exterior
	_biome_container = biome_container
	NavigationSystem.travel_completed.connect(_on_travel_completed)
	_build_fade_overlay()
	Global.log("TravelSequenceManager: setup complete")


## Disconnects from NavigationSystem. Call before freeing this node.
func teardown() -> void:
	if NavigationSystem.travel_completed.is_connected(_on_travel_completed):
		NavigationSystem.travel_completed.disconnect(_on_travel_completed)


## Returns true if a travel transition is currently in progress.
func is_transitioning() -> bool:
	return _is_transitioning


## Returns the currently loaded biome scene node, or null if none loaded.
func get_current_biome_node() -> Node3D:
	return _current_biome_node


## Executes the biome swap synchronously: clears the biome container, creates
## the destination biome node, adds it to the container, and repositions the
## player and ship at the new biome spawn points. Returns true on success.
func execute_biome_swap(destination_id: String) -> bool:
	var new_biome: Node3D = create_biome_node(destination_id)
	if new_biome == null:
		push_error("TravelSequenceManager: unknown biome '%s' — swap aborted" % destination_id)
		return false

	# Clear existing biome content
	_clear_biome_container()

	# Add the new biome to the container
	new_biome.name = "Biome_%s" % destination_id
	_biome_container.add_child(new_biome)

	# Some biomes auto-generate in _ready(), others need explicit calls
	if new_biome.get_child_count() == 0:
		if new_biome.has_method("generate"):
			new_biome.generate()
		elif new_biome.has_method("build_scene"):
			new_biome.build_scene()

	_current_biome_node = new_biome

	# Reposition player and ship at the new biome spawn points
	_reposition_at_spawn(new_biome)

	Global.log("TravelSequenceManager: biome swap to '%s' complete" % destination_id)
	return true


## Creates a biome scene node for the given biome ID. Returns null for invalid IDs.
static func create_biome_node(biome_id: String) -> Node3D:
	match biome_id:
		"shattered_flats":
			return ShatteredFlatsBiome.new()
		"rock_warrens":
			return RockWarrensBiome.new()
		"debris_field":
			return DebrisFieldBiome.new()
	return null


## Returns the player spawn position from a biome node using duck typing.
## Checks for get_player_spawn_position() and get_player_spawn_point().
static func get_biome_player_spawn(biome_node: Node3D) -> Vector3:
	if biome_node.has_method("get_player_spawn_position"):
		return biome_node.call("get_player_spawn_position")
	if biome_node.has_method("get_player_spawn_point"):
		return biome_node.call("get_player_spawn_point")
	push_warning("TravelSequenceManager: biome node has no player spawn method")
	return Vector3.ZERO


## Returns the ship spawn position from a biome node using duck typing.
## Checks for get_ship_spawn_position() and get_ship_spawn_point().
static func get_biome_ship_spawn(biome_node: Node3D) -> Vector3:
	if biome_node.has_method("get_ship_spawn_position"):
		return biome_node.call("get_ship_spawn_position")
	if biome_node.has_method("get_ship_spawn_point"):
		return biome_node.call("get_ship_spawn_point")
	push_warning("TravelSequenceManager: biome node has no ship spawn method")
	return Vector3.ZERO


# ── Private Methods ───────────────────────────────────────

## Handles NavigationSystem.travel_completed — runs the full async travel
## transition: disable input, fade out, swap biome, fade in, re-enable input.
func _on_travel_completed(destination_id: String) -> void:
	if _is_transitioning:
		Global.log("TravelSequenceManager: ignoring travel_completed — already transitioning")
		return

	_is_transitioning = true
	travel_sequence_started.emit(destination_id)
	InputManager.set_gameplay_inputs_enabled(false)
	Global.log("TravelSequenceManager: travel sequence started → '%s'" % destination_id)

	# Fade to black
	await _fade_out()

	# Swap biome content
	var success: bool = execute_biome_swap(destination_id)

	if not success:
		# Error recovery: fade back in and restore input
		push_error("TravelSequenceManager: biome swap failed for '%s' — recovering" % destination_id)
		await _fade_in()
		InputManager.set_gameplay_inputs_enabled(true)
		_is_transitioning = false
		return

	# Fade back in
	await _fade_in()

	# Restore input and mark transition complete
	InputManager.set_gameplay_inputs_enabled(true)
	_is_transitioning = false
	travel_sequence_completed.emit(destination_id)
	Global.log("TravelSequenceManager: travel sequence completed → '%s'" % destination_id)


## Builds the full-screen fade overlay (CanvasLayer + ColorRect).
func _build_fade_overlay() -> void:
	if not is_inside_tree():
		return

	_fade_layer = CanvasLayer.new()
	_fade_layer.name = "TravelFadeLayer"
	_fade_layer.layer = 10
	add_child(_fade_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.name = "TravelFadeRect"
	_fade_rect.color = Color.BLACK
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.modulate.a = 0.0
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_layer.add_child(_fade_rect)


## Fades the overlay to fully opaque (black screen). No-op if no overlay exists.
func _fade_out() -> void:
	if not _fade_rect or not is_inside_tree():
		return
	var tween: Tween = create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 1.0, FADE_DURATION)
	await tween.finished


## Fades the overlay to fully transparent (clear screen). No-op if no overlay exists.
func _fade_in() -> void:
	if not _fade_rect or not is_inside_tree():
		return
	var tween: Tween = create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 0.0, FADE_DURATION)
	await tween.finished


## Removes all children from the biome container.
## Removes biome nodes first, then unregisters deposits from DepositRegistry.
## queue_free() is deferred, so deposits remain valid for unregistration after
## the biome is removed from the container.
func _clear_biome_container() -> void:
	if not _biome_container:
		return
	for child: Node in _biome_container.get_children():
		_biome_container.remove_child(child)
		child.queue_free()
	var registered: Array[Deposit] = DepositRegistry.get_all()
	for deposit: Deposit in registered:
		if is_instance_valid(deposit):
			DepositRegistry.unregister(deposit)
	_current_biome_node = null
	Global.log("TravelSequenceManager: biome container cleared")


## Repositions the player and ship exterior at the biome spawn points.
func _reposition_at_spawn(biome_node: Node3D) -> void:
	var player_spawn: Vector3 = get_biome_player_spawn(biome_node)
	var ship_spawn: Vector3 = get_biome_ship_spawn(biome_node)

	if _player:
		_player.position = player_spawn
		# Reset velocity on the active character controller
		var first_person: CharacterBody3D = _player.get_node_or_null("FirstPersonController") as CharacterBody3D
		if first_person:
			first_person.velocity = Vector3.ZERO
		Global.log("TravelSequenceManager: player repositioned to %s" % str(player_spawn))

	if _ship_exterior:
		_ship_exterior.position = ship_spawn
		Global.log("TravelSequenceManager: ship repositioned to %s" % str(ship_spawn))
