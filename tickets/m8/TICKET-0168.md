---
id: TICKET-0168
title: "Travel sequence — transition animation, biome load, player respawn at destination"
type: FEATURE
status: IN_PROGRESS
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "M8"
phase: "Gameplay"
depends_on: [TICKET-0167]
blocks: []
tags: [travel, transition, biome-load, respawn, m8-gameplay]
---

## Summary

Implement the full travel sequence triggered when the player confirms a navigation jump. Covers the transition out of the current biome, loading the destination biome scene, and respawning the player and ship at the destination. Listens to `NavigationSystem.travel_completed` signal.

## Acceptance Criteria

- [x] On travel initiation: screen fades to black, player input disabled
- [x] Current biome scene unloaded during transition
- [x] Destination biome scene loaded using the biome ID from NavigationSystem
- [x] Player spawns at a defined spawn point in the destination biome
- [x] Ship spawns at a defined spawn point in the destination biome
- [x] Screen fades back in after load completes
- [x] Player input re-enabled after fade-in
- [x] `NavigationSystem.biome_changed` signal fires correctly (triggering respawn system in TICKET-0161)
- [x] Travel sequence handles load errors gracefully — does not leave player in a broken state
- [x] Unit tests cover: scene transition completes, player position valid after arrival, biome_changed signal fired, input re-enabled
- [ ] Full test suite passes — pending QA run (TICKET-0176 or QA gate)

## Implementation Notes

- Use Godot's `SceneTree.change_scene_to_packed()` or additive scene loading depending on architecture
- Fade transition can be a simple `ColorRect` overlay animated via Tween — no complex shader needed for M8 greybox
- Spawn points in each biome scene are defined by the biome scene tickets (TICKET-0170–0172)

## Handoff Notes

**TravelSequenceManager public API** (for Systems Programmer code review):

- `TravelSequenceManager.setup(player: Node3D, ship_exterior: ShipExterior, biome_container: Node3D) -> void` — initialise with references, connect to NavigationSystem.travel_completed
- `TravelSequenceManager.teardown() -> void` — disconnect from NavigationSystem
- `TravelSequenceManager.is_transitioning() -> bool` — true during active travel transition
- `TravelSequenceManager.get_current_biome_node() -> Node3D` — current biome scene node
- `TravelSequenceManager.execute_biome_swap(destination_id: String) -> bool` — synchronous biome swap
- `static TravelSequenceManager.create_biome_node(biome_id: String) -> Node3D` — factory for biome scenes
- `static TravelSequenceManager.get_biome_player_spawn(biome_node: Node3D) -> Vector3` — duck-typed spawn lookup
- `static TravelSequenceManager.get_biome_ship_spawn(biome_node: Node3D) -> Vector3` — duck-typed spawn lookup
- `signal travel_sequence_started(destination_id: String)` — emitted on fade-out start
- `signal travel_sequence_completed(destination_id: String)` — emitted after fade-in complete

**Files created/modified:**
- `game/scripts/gameplay/travel_sequence_manager.gd` — travel sequence orchestrator (new)
- `game/tests/test_travel_sequence_unit.gd` — 16 unit tests (updated from scaffold)
- `game/scripts/levels/test_world.gd` — added biome content container, travel sequence wiring
- `tickets/m8/TICKET-0168.md` — ticket status updates

**Architecture notes:**
- TestWorld groups biome-specific content (ground, boundaries, deposits) under `_biome_content: Node3D`
- TravelSequenceManager clears and replaces `_biome_content` children on biome travel
- Fade overlay uses CanvasLayer (layer 10) + ColorRect animated via Tween
- Biome nodes created via duck typing: supports `generate()`, `build_scene()`, and varied spawn point method names across biome classes
- When not in scene tree (unit tests), fade methods are no-ops — entire handler runs synchronously for testability

**Known limitations:**
- DebrisFieldBiome uses `get_player_spawn_point()` (not `get_player_spawn_position()`) — duck typing handles both
- RockWarrensBiome requires manual `generate()` call (no `_ready()`) — handled via child count check
- Ship enter zone position update after travel is approximate — relies on fixed offset from ship position

## Activity Log

- 2026-02-27 [producer] Created — M8 Gameplay phase
- 2026-02-27 [gameplay-programmer] Starting work — implementing travel sequence: fade transition, biome load/unload, player/ship respawn, unit tests.
