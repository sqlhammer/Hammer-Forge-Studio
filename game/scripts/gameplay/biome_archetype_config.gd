## Biome archetype configuration. Defines noise parameters that control the character
## of procedurally generated terrain. Each archetype produces a distinct terrain feel
## (gentle plains, dense rock formations, scattered mounds) without encoding biome-specific
## gameplay logic. The TerrainGenerator consumes this to shape the heightmap.
## Owner: gameplay-programmer
class_name BiomeArchetypeConfig
extends RefCounted


# ── Private Variables ─────────────────────────────────────

## Human-readable archetype identifier.
var archetype_name: String = ""

## Primary noise frequency — lower values produce broader, smoother features.
var noise_frequency: float = 0.01

## Number of fractal noise octaves — more octaves add finer detail.
var noise_octaves: int = 4

## Base amplitude scaling for noise output.
var noise_amplitude: float = 1.0

## Fractal lacunarity — frequency multiplier per octave.
var noise_lacunarity: float = 2.0

## Fractal gain — amplitude multiplier per octave.
var noise_gain: float = 0.5

## Baseline height offset applied to all terrain points.
var base_height: float = 0.0

## Vertical scaling factor applied to noise values to produce world-space heights.
var height_scale: float = 10.0

## Side length of the biome play area in metres. Shared by terrain generator and boundary system.
var terrain_size: float = 500.0


# ── Public Methods ────────────────────────────────────────

## Creates the Shattered Flats archetype — low-frequency noise, gentle undulation,
## open traversal suitable for the starting biome.
static func shattered_flats() -> BiomeArchetypeConfig:
	var config: BiomeArchetypeConfig = BiomeArchetypeConfig.new()
	config.archetype_name = "shattered_flats"
	config.noise_frequency = 0.003
	config.noise_octaves = 3
	config.noise_amplitude = 1.0
	config.noise_lacunarity = 2.0
	config.noise_gain = 0.5
	config.base_height = 0.0
	config.height_scale = 8.0
	config.terrain_size = 500.0
	return config


## Creates the Rock Warrens archetype — high-frequency noise, dense vertical variation,
## produces narrow corridors between tall rock formations.
static func rock_warrens() -> BiomeArchetypeConfig:
	var config: BiomeArchetypeConfig = BiomeArchetypeConfig.new()
	config.archetype_name = "rock_warrens"
	config.noise_frequency = 0.02
	config.noise_octaves = 6
	config.noise_amplitude = 1.0
	config.noise_lacunarity = 2.0
	config.noise_gain = 0.5
	config.base_height = 0.0
	config.height_scale = 25.0
	config.terrain_size = 500.0
	return config


## Creates the Debris Field archetype — medium-frequency noise, scattered mound
## clusters with flat clearings between them.
static func debris_field() -> BiomeArchetypeConfig:
	var config: BiomeArchetypeConfig = BiomeArchetypeConfig.new()
	config.archetype_name = "debris_field"
	config.noise_frequency = 0.008
	config.noise_octaves = 4
	config.noise_amplitude = 1.0
	config.noise_lacunarity = 2.0
	config.noise_gain = 0.5
	config.base_height = 0.0
	config.height_scale = 15.0
	config.terrain_size = 500.0
	return config
