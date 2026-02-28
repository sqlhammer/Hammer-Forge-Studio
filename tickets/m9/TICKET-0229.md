---
id: TICKET-0229
title: "Root Game: Add starting_biome and starting_inventory params to Global"
type: TASK
status: OPEN
priority: P1
owner: systems-programmer
created_by: producer
created_at: 2026-02-28
updated_at: 2026-02-28
milestone: "M9"
phase: "Root Game"
depends_on: []
blocks: [TICKET-0230, TICKET-0231, TICKET-0233]
tags: [root-game, global, startup-params]
---

## Summary

Add two startup-configuration properties to the `Global` autoload that serve as the source of truth for how the game launches. These properties are written by the debug launcher (in debug mode) and read by the main menu when Play is pressed.

- `starting_biome: String` — the biome ID to load on Play. Defaults to `"shattered_flats"`.
- `starting_inventory: Dictionary` — maps `ResourceDefs.ResourceType` (int key) to quantity (int value). Represents items to grant the player when the game begins. Defaults to `{}` (empty inventory — normal play).

These properties are intentionally simple value holders with no logic. They are set before the main menu is shown and consumed by the game world on load.

## Acceptance Criteria

- [ ] `Global` has a `starting_biome: String` property initialized to `"shattered_flats"`.
- [ ] `Global` has a `starting_inventory: Dictionary` property initialized to `{}`.
- [ ] Both properties are exported or clearly accessible to other scenes and scripts via `Global.starting_biome` / `Global.starting_inventory`.
- [ ] No existing behavior changes — these are additive properties only.
- [ ] `Global.log()` call on autoload `_ready()` or similar notes the default values at startup (optional but encouraged for debuggability).

## Implementation Notes

- `Global.gd` lives at `game/autoloads/Global.gd`.
- Both properties should be declared at the top of the class alongside other global state.
- `starting_inventory` is a `Dictionary` keyed by `ResourceDefs.ResourceType` (int) mapping to quantity (int). An empty dict means no items are granted. A typical begin-wealthy set would have one entry per resource type with quantity equal to that resource's max stack size.
- Do **not** add `@export` annotation — these are runtime properties, not editor-tweakable.

## Activity Log

- 2026-02-28 [producer] Created ticket — foundation for Root Game phase startup parameter flow
