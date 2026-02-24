## HeadLamp autoload: manages the player's head lamp equipment state.
## Once crafted at the Fabricator, the head lamp is permanently equipped to the suit.
## It can be toggled on/off; while active it drains the suit battery at a fixed rate.
## State (equipped and active) persists across scene transitions and game restarts.
extends Node

# ── Signals ──────────────────────────────────────────────
signal head_lamp_toggled(active: bool)
signal head_lamp_equipped

# ── Constants ─────────────────────────────────────────────

## Battery drain rate in units per second while the lamp is active.
## Placeholder — confirm with Studio Head. Suit battery max is 100.0 units.
const DRAIN_RATE_PER_SECOND: float = 2.0

## Fabricator recipe constants — used by FabricatorDefs to register the recipe.
const RECIPE_INPUT_RESOURCE_TYPE: ResourceDefs.ResourceType = ResourceDefs.ResourceType.METAL
const RECIPE_INPUT_QUANTITY: int = 5
const RECIPE_DURATION: float = 10.0

const SAVE_PATH: String = "user://head_lamp.cfg"

# ── Private Variables ─────────────────────────────────────
var _is_equipped: bool = false
var _active: bool = false

# ── Built-in Virtual Methods ──────────────────────────────
func _ready() -> void:
	set_process(false)
	_load_save()
	Global.log("HeadLamp: initialized (equipped=%s, active=%s)" % [str(_is_equipped), str(_active)])
	# Resume drain processing if lamp was active when the game was last saved.
	if _is_equipped and _active:
		set_process(true)

func _process(delta: float) -> void:
	if not _active or not _is_equipped:
		set_process(false)
		return
	SuitBattery.drain(DRAIN_RATE_PER_SECOND * delta)

# ── Public Methods ────────────────────────────────────────

## Returns true if the head lamp has been crafted and equipped to the suit.
func is_equipped() -> bool:
	return _is_equipped

## Returns true if the head lamp is currently switched on.
func is_active() -> bool:
	return _active

## Equips the head lamp after it is crafted at the Fabricator.
## Has no effect if the lamp is already equipped.
func equip() -> void:
	if _is_equipped:
		Global.log("HeadLamp: equip called but already equipped — ignored")
		return
	_is_equipped = true
	_save()
	head_lamp_equipped.emit()
	Global.log("HeadLamp: equipped to suit")

## Toggles the head lamp on or off. Requires the lamp to be equipped.
## Emits head_lamp_toggled with the new active state.
func toggle() -> void:
	if not _is_equipped:
		Global.log("HeadLamp: toggle ignored — lamp not equipped")
		return
	_active = not _active
	set_process(_active)
	_save()
	head_lamp_toggled.emit(_active)
	Global.log("HeadLamp: toggled — now %s" % ("ON" if _active else "OFF"))

## Forces the head lamp off without toggling. Used when suit battery is depleted.
func force_off() -> void:
	if not _active:
		return
	_active = false
	set_process(false)
	_save()
	head_lamp_toggled.emit(false)
	Global.log("HeadLamp: forced off (battery depleted)")

# ── Private Methods ───────────────────────────────────────

## Persists equipped and active state to disk.
func _save() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("state", "is_equipped", _is_equipped)
	config.set_value("state", "active", _active)
	var err: Error = config.save(SAVE_PATH)
	if err != OK:
		push_error("HeadLamp: failed to save state (error %d)" % err)

## Loads persisted state from disk on startup.
func _load_save() -> void:
	var config: ConfigFile = ConfigFile.new()
	var err: Error = config.load(SAVE_PATH)
	if err == ERR_FILE_NOT_FOUND:
		Global.log("HeadLamp: no save file — starting unequipped")
		return
	if err != OK:
		push_error("HeadLamp: failed to load save (error %d)" % err)
		return
	_is_equipped = config.get_value("state", "is_equipped", false) as bool
	# Always start inactive regardless of last saved state — player must re-toggle after loading.
	_active = false
	Global.log("HeadLamp: loaded save (equipped=%s)" % str(_is_equipped))
