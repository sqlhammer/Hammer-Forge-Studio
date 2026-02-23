## Tracks all deposits in the world and provides query/generation utilities.
class_name DepositRegistryType
extends Node

# ── Signals ──────────────────────────────────────────────
signal deposit_registered(deposit: Deposit)
signal deposit_depleted(deposit: Deposit)

# ── Constants ─────────────────────────────────────────────
const M3_DEPOSIT_COUNT_MIN: int = 8
const M3_DEPOSIT_COUNT_MAX: int = 12

# ── Private Variables ─────────────────────────────────────
var _deposits: Array[Deposit] = []

# ── Public Methods ────────────────────────────────────────

## Registers an existing Deposit node for tracking.
func register(deposit: Deposit) -> void:
	if deposit in _deposits:
		return
	_deposits.append(deposit)
	deposit.depleted.connect(_on_deposit_depleted.bind(deposit))
	deposit_registered.emit(deposit)

## Removes a deposit from tracking.
func unregister(deposit: Deposit) -> void:
	var idx: int = _deposits.find(deposit)
	if idx >= 0:
		if deposit.depleted.is_connected(_on_deposit_depleted):
			deposit.depleted.disconnect(_on_deposit_depleted)
		_deposits.remove_at(idx)

## Returns all registered deposits.
func get_all() -> Array[Deposit]:
	return _deposits.duplicate()

## Returns all deposits that still have resources.
func get_active() -> Array[Deposit]:
	var active: Array[Deposit] = []
	for deposit: Deposit in _deposits:
		if not deposit.is_depleted():
			active.append(deposit)
	return active

## Returns all depleted deposits.
func get_depleted() -> Array[Deposit]:
	var result: Array[Deposit] = []
	for deposit: Deposit in _deposits:
		if deposit.is_depleted():
			result.append(deposit)
	return result

## Returns the nearest non-depleted deposit to a world position.
func get_nearest_active(world_position: Vector3) -> Deposit:
	var nearest: Deposit = null
	var nearest_dist_sq: float = INF
	for deposit: Deposit in _deposits:
		if deposit.is_depleted():
			continue
		var dist_sq: float = world_position.distance_squared_to(deposit.global_position)
		if dist_sq < nearest_dist_sq:
			nearest_dist_sq = dist_sq
			nearest = deposit
	return nearest

## Returns all non-depleted deposits within `radius` of a world position.
func get_in_range(world_position: Vector3, radius: float) -> Array[Deposit]:
	var result: Array[Deposit] = []
	var radius_sq: float = radius * radius
	for deposit: Deposit in _deposits:
		if deposit.is_depleted():
			continue
		if world_position.distance_squared_to(deposit.global_position) <= radius_sq:
			result.append(deposit)
	return result

## Generates M3 greybox deposits procedurally around an origin point.
## Returns the array of created Deposit nodes (caller must add to scene tree).
func generate_m3_deposits(origin: Vector3, spread_radius: float) -> Array[Deposit]:
	var count: int = randi_range(M3_DEPOSIT_COUNT_MIN, M3_DEPOSIT_COUNT_MAX)
	var generated: Array[Deposit] = []
	for i: int in range(count):
		var deposit: Deposit = Deposit.new()
		var purity: ResourceDefs.Purity = _random_m3_purity()
		var density: ResourceDefs.DensityTier = _random_density()
		var quantity_range: Vector2i = ResourceDefs.DENSITY_QUANTITY_RANGES.get(
			density, Vector2i(10, 25)
		)
		var quantity: int = randi_range(quantity_range.x, quantity_range.y)
		deposit.setup(ResourceDefs.ResourceType.SCRAP_METAL, purity, density, quantity)
		# Place in random XZ position around origin, on ground plane (Y=0)
		var angle: float = randf() * TAU
		var dist: float = randf_range(spread_radius * 0.2, spread_radius)
		deposit.global_position = Vector3(
			origin.x + cos(angle) * dist,
			origin.y,
			origin.z + sin(angle) * dist,
		)
		deposit.name = "Deposit_%d" % i
		generated.append(deposit)
		register(deposit)
	return generated

# ── Private Methods ───────────────────────────────────────

## M3 purity distribution: biased toward 1-3 star (Tier 1 biome).
func _random_m3_purity() -> ResourceDefs.Purity:
	var roll: float = randf()
	if roll < 0.30:
		return ResourceDefs.Purity.ONE_STAR
	elif roll < 0.60:
		return ResourceDefs.Purity.TWO_STAR
	elif roll < 0.85:
		return ResourceDefs.Purity.THREE_STAR
	elif roll < 0.95:
		return ResourceDefs.Purity.FOUR_STAR
	else:
		return ResourceDefs.Purity.FIVE_STAR

## Random density tier with even distribution.
func _random_density() -> ResourceDefs.DensityTier:
	var roll: int = randi_range(0, 2)
	return roll as ResourceDefs.DensityTier

func _on_deposit_depleted(deposit: Deposit) -> void:
	deposit_depleted.emit(deposit)
