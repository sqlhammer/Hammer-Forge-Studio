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

- [ ] On travel initiation: screen fades to black, player input disabled
- [ ] Current biome scene unloaded during transition
- [ ] Destination biome scene loaded using the biome ID from NavigationSystem
- [ ] Player spawns at a defined spawn point in the destination biome
- [ ] Ship spawns at a defined spawn point in the destination biome
- [ ] Screen fades back in after load completes
- [ ] Player input re-enabled after fade-in
- [ ] `NavigationSystem.biome_changed` signal fires correctly (triggering respawn system in TICKET-0161)
- [ ] Travel sequence handles load errors gracefully — does not leave player in a broken state
- [ ] Unit tests cover: scene transition completes, player position valid after arrival, biome_changed signal fired, input re-enabled
- [ ] Full test suite passes

## Implementation Notes

- Use Godot's `SceneTree.change_scene_to_packed()` or additive scene loading depending on architecture
- Fade transition can be a simple `ColorRect` overlay animated via Tween — no complex shader needed for M8 greybox
- Spawn points in each biome scene are defined by the biome scene tickets (TICKET-0170–0172)

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created — M8 Gameplay phase
- 2026-02-27 [gameplay-programmer] Starting work — implementing travel sequence: fade transition, biome load/unload, player/ship respawn, unit tests.
