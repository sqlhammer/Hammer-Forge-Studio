## Declarative terrain feature request. Biome scenes construct these to describe what
## terrain features they need — plateaus, clearings, ramps, resource spawn zones — and
## the TerrainGenerator shapes the mesh to satisfy them.
## Owner: gameplay-programmer
class_name TerrainFeatureRequest
extends RefCounted


# ── Enums ─────────────────────────────────────────────────

enum FeatureType { PLATEAU, CLEARING, RESOURCE_SPAWN, WALKABLE_CLEARANCE }
enum AccessType { NONE, RAMP }


# ── Private Variables ─────────────────────────────────────

## The type of terrain feature requested.
var type: FeatureType = FeatureType.PLATEAU

## Width (X extent in metres) — used by PLATEAU.
var width: float = 0.0

## Depth (Z extent in metres) — used by PLATEAU.
var depth: float = 0.0

## Elevation above base terrain — used by PLATEAU.
var height: float = 0.0

## Access method for elevated features — used by PLATEAU.
var access: AccessType = AccessType.NONE

## Width of ascent path when access is RAMP — used by PLATEAU.
var ramp_width: float = 3.0

## Position hint: String ("center", "edge") or Vector2 for world-space XZ.
## Used by PLATEAU, CLEARING, RESOURCE_SPAWN.
var position_hint: Variant = "center"

## Radius in metres — used by CLEARING, WALKABLE_CLEARANCE.
var radius: float = 0.0

## Number of surface positions to sample — used by RESOURCE_SPAWN.
var count: int = 0

## Maximum slope in degrees for spawn filtering — used by RESOURCE_SPAWN.
var slope_max: float = 45.0

## Minimum clearance between spawn positions — used by RESOURCE_SPAWN.
var clearance_radius: float = 1.0

## Exact world-space XZ position — used by WALKABLE_CLEARANCE.
var position: Vector2 = Vector2.ZERO


# ── Public Methods ────────────────────────────────────────

## Creates a plateau request — a flat elevated area of specified dimensions.
static func create_plateau(
	p_width: float,
	p_depth: float,
	p_height: float,
	p_access: AccessType = AccessType.NONE,
	p_ramp_width: float = 3.0,
	p_position_hint: Variant = "center"
) -> TerrainFeatureRequest:
	var request: TerrainFeatureRequest = TerrainFeatureRequest.new()
	request.type = FeatureType.PLATEAU
	request.width = p_width
	request.depth = p_depth
	request.height = p_height
	request.access = p_access
	request.ramp_width = p_ramp_width
	request.position_hint = p_position_hint
	return request


## Creates a clearing request — a flat, obstacle-free circular area.
static func create_clearing(
	p_radius: float,
	p_position_hint: Variant = "edge"
) -> TerrainFeatureRequest:
	var request: TerrainFeatureRequest = TerrainFeatureRequest.new()
	request.type = FeatureType.CLEARING
	request.radius = p_radius
	request.position_hint = p_position_hint
	return request


## Creates a resource spawn request — samples N surface positions meeting criteria.
static func create_resource_spawn(
	p_count: int,
	p_slope_max: float = 45.0,
	p_clearance_radius: float = 1.0,
	p_position_hint: Variant = null
) -> TerrainFeatureRequest:
	var request: TerrainFeatureRequest = TerrainFeatureRequest.new()
	request.type = FeatureType.RESOURCE_SPAWN
	request.count = p_count
	request.slope_max = p_slope_max
	request.clearance_radius = p_clearance_radius
	request.position_hint = p_position_hint
	return request


## Creates a walkable clearance request — guarantees minimum unobstructed ground radius.
static func create_walkable_clearance(
	p_position: Vector2,
	p_radius: float
) -> TerrainFeatureRequest:
	var request: TerrainFeatureRequest = TerrainFeatureRequest.new()
	request.type = FeatureType.WALKABLE_CLEARANCE
	request.position = p_position
	request.radius = p_radius
	return request
