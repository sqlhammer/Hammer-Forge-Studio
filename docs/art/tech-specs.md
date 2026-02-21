# Art Technical Specifications

**Owner:** technical-artist
**Status:** Draft
**Last Updated:** —

> Hard limits for all art assets. All art agents must check their work against these specs before submitting. Technical Artist enforces via validation review.

---

## Texture Budgets

| Asset Type | Max Resolution | Format | Compression |
|------------|---------------|--------|-------------|
| Environment (diffuse) | _[TBD]_ | PNG/WebP | _[TBD]_ |
| Character (diffuse) | _[TBD]_ | PNG/WebP | _[TBD]_ |
| UI elements | _[TBD]_ | PNG | Lossless |
| VFX particles | _[TBD]_ | PNG | _[TBD]_ |

---

## Polygon Budgets

| Asset Type | Max Tris |
|------------|----------|
| Player character | _[TBD]_ |
| Enemy (major) | _[TBD]_ |
| Environment prop (hero) | _[TBD]_ |
| Environment prop (background) | _[TBD]_ |

---

## Draw Call Targets

| Context | Target Draw Calls |
|---------|------------------|
| Gameplay scene (60fps) | _[TBD]_ |
| UI overlay | _[TBD]_ |

---

## VFX Particle Budgets

| Performance Tier | Max Particles |
|-----------------|--------------|
| Low | < 100 |
| Medium | 100 – 500 |
| High (requires review) | > 500 |

---

## Asset Naming Convention

`<type>_<descriptor>_<variant>.<ext>`

Examples: `tex_player_diffuse.png`, `mesh_door_wooden.glb`, `sfx_footstep_stone_01.ogg`

---

## Import Settings Defaults

_[Default Godot import settings for each asset category — to be filled in by technical-artist]_
