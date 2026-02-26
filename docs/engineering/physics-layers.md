# Physics Layer Assignments

**Owner:** systems-programmer
**Status:** Active
**Last Updated:** 2026-02-26

> Canonical collision layer definitions. Never use raw integers in collision mask code — reference these layer names.

---

## Layer Assignments

| Layer # | Name | Used By |
|---------|------|---------|
| 1 | `player` | Player character body |
| 2 | `enemy` | Enemy character bodies |
| 3 | `environment` | Static world geometry |
| 4 | `interactable` | Doors, pickups, triggers |
| 5 | `projectile` | Player and enemy projectiles |
| 6–32 | _[Reserved]_ | |

---

## Usage in GDScript

Reference the `PhysicsLayers` class from `game/scripts/core/physics_layers.gd`. Never use raw integers.

```gdscript
# Use named constants from PhysicsLayers
collision_layer = PhysicsLayers.PLAYER           # Layer 1
collision_mask = PhysicsLayers.ENVIRONMENT | PhysicsLayers.INTERACTABLE  # Layers 3 and 4
```

### Available Constants

| Constant | Value | Layer # |
|----------|-------|---------|
| `PhysicsLayers.PLAYER` | `1 << 0` | 1 |
| `PhysicsLayers.ENEMY` | `1 << 1` | 2 |
| `PhysicsLayers.ENVIRONMENT` | `1 << 2` | 3 |
| `PhysicsLayers.INTERACTABLE` | `1 << 3` | 4 |
| `PhysicsLayers.PROJECTILE` | `1 << 4` | 5 |
