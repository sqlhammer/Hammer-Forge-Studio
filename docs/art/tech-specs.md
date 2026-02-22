# Art Technical Specifications

**Owner:** technical-artist
**Status:** v1.0
**Last Updated:** 2026-02-22

> Hard limits for all art assets. All art agents must check their work against these specs before submitting. Technical Artist enforces via validation review.

---

## Quick Reference

| Asset Type | Max Tris | Max Texture Res | Max GLB Size |
|------------|----------|----------------|-------------|
| Player Character | 10,000 | 2048x2048 | 2 MB |
| Ship/Vehicle (hero) | 15,000 | 2048x2048 | 3 MB |
| Handheld Tool/Weapon | 5,000 | 1024x1024 | 1 MB |
| Environment Prop (hero) | 4,000 | 1024x1024 | 1 MB |
| Environment Prop (background) | 1,500 | 512x512 | 500 KB |
| Enemy (major) | 8,000 | 2048x2048 | 2 MB |
| UI Element | N/A | 512x512 | N/A |

---

## Polygon Budgets

| Asset Type | Triangle Range | Hard Max | Notes |
|------------|---------------|----------|-------|
| Player character | 5,000–10,000 | 10,000 | Must read at 10m orbital camera distance |
| Ship/vehicle (hero) | 8,000–15,000 | 15,000 | Largest single mesh in game |
| Handheld tool/weapon | 2,000–5,000 | 5,000 | Viewed close-up in first-person |
| Environment prop (hero) | 1,500–4,000 | 4,000 | Resource nodes, key interactables |
| Environment prop (background) | 500–1,500 | 1,500 | Non-interactive scenery, scatter objects |
| Enemy (major) | 4,000–8,000 | 8,000 | Visible at combat distance |

**Source:** Asset briefs from TICKET-0008. Validated against Blender PoC output (all assets within budget) and AI gen PoC (all assets exceeded budget — retopology required).

### PoC Actuals for Reference

| Asset | Blender PoC Tris | AI Gen PoC Verts | Budget |
|-------|------------------|------------------|--------|
| Hand Drill | ~3,000 (est) | ~100,000 | 2,000–5,000 |
| Player Character | ~6,000 (est) | ~120,000 | 5,000–10,000 |
| Ship Exterior | ~4,000 (est) | 285,204 | 8,000–15,000 |
| Resource Node | ~2,000 (est) | ~200,000 | 1,500–4,000 |

---

## Texture Budgets

| Asset Type | Max Resolution | Format | Compression | Maps |
|------------|---------------|--------|-------------|------|
| Character (PBR) | 2048x2048 | JPG/PNG | VRAM Compressed (S3TC/BPTC) | Color, Normal, ORM |
| Vehicle/Ship (PBR) | 2048x2048 | JPG/PNG | VRAM Compressed (S3TC/BPTC) | Color, Normal, ORM |
| Handheld prop (PBR) | 1024x1024 | JPG/PNG | VRAM Compressed (S3TC/BPTC) | Color, Normal, ORM |
| Environment prop (PBR) | 1024x1024 | JPG/PNG | VRAM Compressed (S3TC/BPTC) | Color, Normal, ORM |
| Environment (background) | 512x512 | JPG/PNG | VRAM Compressed | Color only |
| UI elements | 512x512 | PNG | Lossless | Color + Alpha |
| VFX particles | 256x256 | PNG | Lossless | Color + Alpha |

**Texture map definitions:**
- **Color:** Albedo/diffuse color (sRGB)
- **Normal:** Normal map in OpenGL format (green-up). Godot auto-detects and compresses as red-green.
- **ORM:** Occlusion (R), Roughness (G), Metallic (B) packed into single texture.

**Note:** Blender Python pipeline produces flat PBR colors (no texture maps). AI generation pipeline produces full PBR texture sets automatically. For Blender assets, texture maps are optional — flat materials are acceptable if the color differentiation is clear.

---

## Draw Call Targets

| Context | Target Draw Calls | Max Draw Calls |
|---------|------------------|----------------|
| Gameplay scene (60fps) | < 200 | 300 |
| UI overlay | < 30 | 50 |
| Loading/transition | < 10 | 20 |

**Godot-specific notes:**
- Use MultiMeshInstance3D for repeated props (resource nodes, scatter objects)
- Merge static geometry where possible to reduce draw calls
- Forward+ renderer (default) handles ~300 draw calls at 60fps on mid-range hardware
- RTX 4070 Laptop GPU (dev hardware): comfortable at 500+ draw calls

---

## VFX Particle Budgets

| Performance Tier | Max Particles |
|-----------------|--------------|
| Low | < 100 |
| Medium | 100–500 |
| High (requires review) | > 500 |

---

## Asset Naming Convention

`<type>_<descriptor>_<variant>.<ext>`

### Type Prefixes

| Prefix | Asset Type |
|--------|-----------|
| `mesh_` | 3D mesh (GLB) |
| `tex_` | Texture (PNG/JPG) |
| `mat_` | Material resource |
| `sfx_` | Sound effect |
| `mus_` | Music track |
| `vfx_` | Visual effect |
| `scn_` | Scene file |

### Examples

```
mesh_hand_drill.glb
mesh_player_character.glb
mesh_ship_exterior.glb
mesh_resource_node_scrap.glb
tex_player_diffuse.png
tex_ship_normal.png
sfx_footstep_stone_01.ogg
```

---

## Directory Structure

```
game/assets/
├── meshes/
│   ├── characters/      # Player, NPCs, enemies
│   ├── vehicles/        # Ships, transports
│   ├── tools/           # Handheld equipment
│   └── props/           # Environment props, resource nodes
├── textures/            # Standalone textures (not embedded in GLB)
├── materials/           # Godot material resources
├── audio/
│   ├── sfx/
│   └── music/
└── vfx/
```

---

## Import Settings Defaults

### 3D Meshes (GLB)

| Setting | Value |
|---------|-------|
| Importer | `scene` |
| Root scale | `1.0` |
| Apply root scale | `true` |
| Generate LODs | `true` |
| Create shadow meshes | `true` |
| Ensure tangents | `true` |
| Light baking | `Static Lightmaps` (1) |
| Force disable compression | `false` |
| GLTF naming version | `2` |
| Embedded image handling | `Extract textures` (1) |

### Textures (when extracted from GLB)

Godot auto-detects texture usage and sets compression:
- **Color maps:** VRAM Compressed (S3TC/ETC/BPTC) with mipmaps
- **Normal maps:** Red-green compressed with mipmaps
- **ORM maps:** VRAM Compressed with mipmaps

### Audio (future)

| Setting | Value |
|---------|-------|
| SFX format | `.ogg` (Vorbis) |
| Music format | `.ogg` (Vorbis) |
| Max sample rate | 44.1 kHz |

---

## Validation Checklist

Before submitting any asset, verify:

- [ ] Triangle count within budget for asset type
- [ ] GLB file size within budget for asset type
- [ ] Texture resolution within budget for asset type
- [ ] Naming follows `<type>_<descriptor>_<variant>.<ext>` convention
- [ ] Imports into Godot without errors
- [ ] Correct scale (player = ~1.8m, use Godot ruler)
- [ ] Materials display correctly (not all black, not missing)
- [ ] No inverted normals visible
- [ ] Placed in correct `game/assets/` subdirectory
