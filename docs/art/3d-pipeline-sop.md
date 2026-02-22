# 3D Asset Pipeline — Standard Operating Procedure

**Version:** v1.0
**Owner:** technical-artist
**Last Updated:** 2026-02-22
**Pipeline:** Hybrid (AI Generation primary, Blender Python secondary)

---

## Quick Reference

```
Brief → Generate → Validate → Optimize → Import → Verify → Ship
```

| Step | Tool | Time |
|------|------|------|
| 1. Receive brief | — | — |
| 2. Generate mesh | Tripo3D API or Blender Python | 15s (AI) / 45min (Blender) |
| 3. Validate output | Python script | 5s |
| 4. Optimize (retopo/decimate) | Blender Python | 30s–5min |
| 5. Export GLB | Blender | 5s |
| 6. Import to Godot | Godot editor | Auto |
| 7. Verify in-engine | Godot editor | Manual check |
| 8. Place in asset directory | File system | 5s |

---

## Prerequisites

### Required Software

| Tool | Version | Purpose |
|------|---------|---------|
| Blender | 5.0.1+ | Mesh optimization, export, Blender Python pipeline |
| Python | 3.10+ | API scripts, validation |
| Godot Engine | 4.5.1+ | Game engine, import verification |
| `requests` module | Latest | Tripo3D API calls (`pip install requests`) |

### Required Credentials

| Credential | Storage | Notes |
|------------|---------|-------|
| `TRIPO_API_KEY` | Windows system env var | Professional plan ($11.94/month). Set via System Properties → Environment Variables. Read into bash via: `export TRIPO_API_KEY="$(powershell -Command "[System.Environment]::GetEnvironmentVariable('TRIPO_API_KEY', 'User')")"` |

### Required Files

| File | Path | Purpose |
|------|------|---------|
| Tripo API script | `ai_gen_experiments/tripo_generate.py` | AI mesh generation |
| Blender build scripts | `blender_experiments/build_*.py` | Blender Python generation |
| Blender batch runner | `blender_experiments/run_poc_all.py` | Run all Blender builds |
| Tech specs | `docs/art/tech-specs.md` | Validation budgets |
| Asset briefs | `docs/art/asset-briefs/*.md` | Source requirements |

---

## Pipeline Decision Rule

**Use AI Generation (Tripo3D) when:**
- Asset is a hero/unique item (player character, ship, key props)
- Asset has organic or complex shapes (rocks, characters, vehicles)
- Visual richness and texture detail matter
- Speed is prioritized over exact reproducibility

**Use Blender Python when:**
- Asset needs exact dimensional control (modular pieces, tiling)
- Asset must be deterministically reproducible
- Asset is procedural/parameterized (scatter objects, grid patterns)
- Post-processing cleanup of AI-generated meshes is needed
- Retopology/decimation of AI output

**Use Blender Python for ALL post-processing** regardless of which pipeline generated the base mesh.

---

## Pipeline A: AI Generation (Tripo3D)

### Step 1: Write the prompt

Start from the asset brief at `docs/art/asset-briefs/<asset>.md`. Structure the prompt as:

```
[Object description] + [Style cues] + [Scale reference] + [Exclusions]
```

**Template:**
```
A [object type], [key visual features]. [Material descriptions].
[Size reference]. [Art style reference]. [Functional context].
```

**Negative prompt template:**
```
realistic, photorealistic, [style exclusions], [object exclusions]
```

Example (hand drill):
```
Prompt: "A handheld sci-fi extraction drill tool, stylized chunky proportions.
Worn brushed metal housing with rubber grip handle, glowing cyan energy conduit
running along the top, drill bit tip at the front. Three small green charge
indicator lights on the side panel. Exhaust vents at the rear. Size of a large
cordless drill but slightly oversized for sci-fi readability. Outer Wilds art
style, utilitarian research equipment aesthetic. Not a weapon."

Negative: "realistic, photorealistic, weapon, gun, military, tiny, miniature"
```

### Step 2: Generate via API

**Single asset:**
```bash
python ai_gen_experiments/tripo_generate.py --asset hand_drill
```

**All assets:**
```bash
python ai_gen_experiments/tripo_generate.py
```

Output: `ai_gen_experiments/poc_output/<name>.glb`

**Expected behavior:**
- Task creation: ~1s
- Generation: ~10-15s (poll interval: 5s)
- Download: ~3-5s (signed CloudFront URL)
- Total: ~20s per asset

**Cost:** ~40 credits per generation (~$0.16 on Professional plan)

### Step 3: Validate raw output

Check file size and rough vertex count:
```bash
python -c "
import struct, json, os
path = 'ai_gen_experiments/poc_output/mesh_hand_drill.glb'
with open(path, 'rb') as f:
    f.read(12)  # skip header
    chunk_len = struct.unpack('<I', f.read(4))[0]
    f.read(4)  # skip chunk type
    gltf = json.loads(f.read(chunk_len))
    for i, mesh in enumerate(gltf.get('meshes', [])):
        for j, prim in enumerate(mesh.get('primitives', [])):
            pos = prim.get('attributes', {}).get('POSITION')
            if pos is not None:
                print(f'Mesh {i}: {gltf[\"accessors\"][pos][\"count\"]} vertices')
print(f'File size: {os.path.getsize(path) / 1024:.0f} KB')
"
```

**Expected:** AI output will be 100K-285K vertices (far over budget). Proceed to Step 4.

### Step 4: Optimize with Blender

AI-generated meshes MUST be decimated before game use. Use Blender's Decimate modifier:

```bash
blender --background --python - <<'PYEOF'
import bpy, sys

input_path = "ai_gen_experiments/poc_output/mesh_hand_drill.glb"
output_path = "game/assets/meshes/tools/mesh_hand_drill.glb"
target_ratio = 0.02  # Reduce to ~2% of original (100K -> ~2K tris)

# Clear and import
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=input_path)

# Decimate all meshes
for obj in bpy.data.objects:
    if obj.type == 'MESH':
        bpy.context.view_layer.objects.active = obj
        mod = obj.modifiers.new(name="Decimate", type='DECIMATE')
        mod.ratio = target_ratio
        bpy.ops.object.modifier_apply(modifier="Decimate")
        print(f"{obj.name}: {len(obj.data.polygons)} faces")

# Export
bpy.ops.export_scene.gltf(
    filepath=output_path,
    export_format='GLB',
    export_apply=True,
)
print(f"Exported: {output_path}")
PYEOF
```

**Target decimation ratios:**

| Asset Type | Budget Tris | Typical AI Verts | Decimate Ratio |
|------------|------------|------------------|----------------|
| Hand drill | 5,000 | ~100K | 0.025 |
| Player character | 10,000 | ~120K | 0.04 |
| Ship exterior | 15,000 | ~285K | 0.025 |
| Resource node | 4,000 | ~200K | 0.01 |

**Note:** Decimation ratios are approximate starting points. Adjust based on actual vertex count and visual quality at target resolution.

### Step 5: Export and import

After decimation, the GLB is already exported by the Blender script above. Copy to the correct game directory:

```
game/assets/meshes/tools/mesh_hand_drill.glb
game/assets/meshes/characters/mesh_player_character.glb
game/assets/meshes/vehicles/mesh_ship_exterior.glb
game/assets/meshes/props/mesh_resource_node_scrap.glb
```

Godot will auto-import when the file appears in the project directory.

### Step 6: Verify in Godot

1. Open Godot editor
2. Navigate to asset in FileSystem dock
3. Double-click GLB to open import settings — verify defaults match tech-specs
4. Drag into a 3D scene to visually inspect
5. Check: correct scale, materials display, no visual artifacts

---

## Pipeline B: Blender Python

### Step 1: Write or modify the build script

Start from existing scripts in `blender_experiments/`:
- `build_hand_drill.py`
- `build_player_character.py`
- `build_ship_exterior.py`
- `build_resource_node.py`

Use `master_control.py` framework:
```python
from master_control import generate_and_export, clear_scene, export_glb, log_entry
```

### Step 2: Generate

```bash
blender --background --python blender_experiments/build_hand_drill.py
```

Or all at once:
```bash
blender --background --python blender_experiments/run_poc_all.py
```

Output: `blender_experiments/poc_output/<name>.glb`

**Expected:** <1s per asset after Blender init (~11s first run).

### Step 3: Validate

Blender Python output is typically within budget (scripts are designed for target poly ranges). Verify with the same validation script from Pipeline A, Step 3.

### Step 4: Copy to game directory

```bash
cp blender_experiments/poc_output/mesh_hand_drill.glb game/assets/meshes/tools/
```

### Step 5: Verify in Godot

Same as Pipeline A, Step 6.

---

## Common Failure Modes

### Import fails in Godot

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| "Failed loading resource" | GLB too large or reimport in progress | Wait for reimport to complete, then retry |
| All materials black | Missing texture references | Re-export with embedded textures |
| Wrong scale (too large/small) | AI tools don't guarantee scale | Apply scale in Blender: `bpy.ops.object.transform_apply(scale=True)` |
| Flipped normals (dark patches) | Blender export normal direction | `bpy.ops.mesh.normals_make_consistent(inside=False)` in edit mode |
| Missing UVs | Blender procedural meshes lack UVs | Add smart UV project: `bpy.ops.uv.smart_project()` |

### AI generation issues

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| 403 Forbidden | API key invalid or no credits | Check `TRIPO_API_KEY` env var; verify credit balance at tripo3d.ai/app |
| Task stuck at "running" | API congestion | Wait up to 300s (MAX_WAIT); if timeout, retry |
| Download URL 404 | Signed URL expired | Re-poll task to get fresh URL from `output.pbr_model` |
| Output doesn't match prompt | Prompt too vague | Add more specific details, use negative prompts aggressively |

### Blender Python issues

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `bpy` not found | Running with system Python, not Blender | Use `blender --background --python script.py` |
| Edit mode crash | Context not set correctly | Ensure `bpy.context.view_layer.objects.active = obj` before edit mode |
| Orphan data warning | Objects deleted but data blocks remain | `bpy.ops.outliner.orphans_purge()` |

---

## Worked Example: Hand Drill (AI Pipeline)

### Input

Asset brief: `docs/art/asset-briefs/hand-drill.md`
- Budget: 2,000–5,000 triangles
- Scale: ~30cm long
- Requirements: Sci-fi drill, chunky, Outer Wilds style

### Generation

```bash
export TRIPO_API_KEY="$(powershell -Command "[System.Environment]::GetEnvironmentVariable('TRIPO_API_KEY', 'User')")"
python ai_gen_experiments/tripo_generate.py --asset hand_drill
```

**Result:** `ai_gen_experiments/poc_output/mesh_hand_drill.glb` (9.8 MB, ~100K vertices)

### Validation

Raw output: ~100K vertices — exceeds 5,000 tri budget by ~20x. Decimation required.

### Optimization

```bash
blender --background --python - <<'PYEOF'
import bpy
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath="ai_gen_experiments/poc_output/mesh_hand_drill.glb")
for obj in bpy.data.objects:
    if obj.type == 'MESH':
        bpy.context.view_layer.objects.active = obj
        mod = obj.modifiers.new(name="Decimate", type='DECIMATE')
        mod.ratio = 0.025
        bpy.ops.object.modifier_apply(modifier="Decimate")
        print(f"{obj.name}: {len(obj.data.polygons)} faces")
bpy.ops.export_scene.gltf(
    filepath="game/assets/meshes/tools/mesh_hand_drill.glb",
    export_format='GLB',
    export_apply=True,
)
PYEOF
```

### Import

Copy to `game/assets/meshes/tools/mesh_hand_drill.glb`. Godot auto-imports.

### Verification

Open in Godot editor → drag into 3D scene → verify:
- Silhouette reads as "drill"
- Materials display correctly
- Scale approximately 30cm
- Triangle count within budget

---

## Appendix: Blender CLI Reference

```bash
# Blender path (Windows)
"/c/Program Files/Blender Foundation/Blender 5.0/blender.exe"

# Run script in background
blender --background --python script.py

# Run with specific blend file
blender --background file.blend --python script.py

# Override output path via environment
OUTPUT_DIR=/custom/path blender --background --python script.py
```

## Appendix: Tripo3D API Reference

```
Base URL: https://api.tripo3d.ai/v2/openapi

POST /task                  → Create generation task
GET  /task/{task_id}        → Poll task status
                              Result: data.output.pbr_model → signed GLB URL

Auth: Bearer token via Authorization header
Credits: ~40 per text-to-model generation
```
