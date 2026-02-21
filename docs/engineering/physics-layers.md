# Physics Layer Assignments

**Owner:** systems-programmer
**Status:** Draft
**Last Updated:** —

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

```gdscript
# Reference layers by name via ProjectSettings — never by number
collision_layer = 1 << 0  # Layer 1 (player) — index is layer - 1
collision_mask = (1 << 2) | (1 << 3)  # Layers 3 and 4
```

_To be replaced with named constants once defined in a core constants resource._
