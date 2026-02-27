## Container for the output of TerrainGenerator.generate(). Holds the final terrain mesh,
## baked collision shape, confirmed world-space positions for each feature request,
## any warnings for unresolvable requests, and the chunk grid for future streaming support.
## Owner: gameplay-programmer
class_name TerrainGenerationResult
extends RefCounted


# ── Private Variables ─────────────────────────────────────

## The fully assembled terrain ArrayMesh with vertices, normals, and UVs.
var terrain_mesh: ArrayMesh = null

## Baked concave polygon collision shape matching the terrain mesh geometry.
var collision_shape: ConcavePolygonShape3D = null

## Confirmed world-space positions per feature request.
## Key: request index (int). Value: Array of Vector3 positions.
## For plateau/clearing/walkable_clearance: single-element array with the resolved center.
## For resource_spawn: array of N sampled surface positions.
var confirmed_positions: Dictionary = {}

## Warning messages for requests that could not be fully resolved.
var warnings: Array[String] = []

## Chunk grid keyed by Vector2i grid coordinates.
## Each value is a TerrainChunk containing its mesh section and collision shape.
var chunk_grid: Dictionary = {}

## Raw heightmap data as a flat array indexed by (z * heightmap_resolution + x).
var heightmap: PackedFloat32Array = PackedFloat32Array()

## Number of vertices per axis in the heightmap.
var heightmap_resolution: int = 0
