## Immutable data container for a single biome. Holds the biome's canonical
## identifier, display name, description, terrain seed, and resource profile
## summary. Created exclusively by BiomeRegistry — do not instantiate directly.
## Ticket: TICKET-0159
class_name BiomeData
extends RefCounted

# ── Public Variables ──────────────────────────────────────

## Canonical snake_case identifier used to reference this biome in code.
var id: String = ""

## Human-readable biome name shown in the UI.
var display_name: String = ""

## Short description of the biome's character and hazards.
var description: String = ""

## Fixed integer seed that controls terrain generation. Constant per biome so
## the layout is identical on every visit.
var terrain_seed: int = 0

## Informational summary of resources found in this biome. Consumed by biome
## scene tickets — not used for game logic in this system.
var resource_profile: String = ""
