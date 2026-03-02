## A single spatial chunk of procedurally generated terrain. Stores its own mesh section
## and collision shape independently for future LOD and streaming support.
## Owner: gameplay-programmer
class_name TerrainChunk
extends RefCounted


# ── Public Variables ──────────────────────────────────────

## Grid position of this chunk in the 2D spatial grid (column, row).
var grid_position: Vector2i = Vector2i.ZERO

## ArrayMesh containing the terrain geometry for this chunk.
var mesh_section: ArrayMesh = null

## Concave polygon collision shape for this chunk's geometry.
var collision_shape: ConcavePolygonShape3D = null

## World-space origin of this chunk's lower-left corner.
var world_origin: Vector3 = Vector3.ZERO

## Number of vertices in this chunk's mesh section.
var vertex_count: int = 0
