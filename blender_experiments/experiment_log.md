# Blender Experiments Log

Central log for all 3D generation attempts using `bpy`.

---

### [2026-02-21 19:56:32] - Object: test_cube
- **Original Prompt:** "A simple red subdivided cube for pipeline verification."
- **Output Files:** `C:\repos\Hammer-Forge-Studio\.claude\worktrees\elastic-joliot\blender_experiments\test_cube\test_cube.blend`, `C:\repos\Hammer-Forge-Studio\.claude\worktrees\elastic-joliot\blender_experiments\test_cube\test_cube.obj`, `C:\repos\Hammer-Forge-Studio\.claude\worktrees\elastic-joliot\blender_experiments\test_cube\test_cube.glb`
- **Technical Strategy:** Primitive cube with Subdivision Surface modifier (level 2) and Principled BSDF material.
- **Challenges/Fixes:** None

---

### [2026-02-21 20:13:54] - Object: space_suit_character
- **Original Prompt:** "Human player character fully encased in a sleek space suit with a smooth opaque visor helmet. Left wrist has a modern Pipboy-like device. Tall boots nearly to knees. Deep blue and gunmetal color theme. Posed looking at wrist device. Mix of shiny armor plates and matte suit fabric."
- **Output Files:** `C:\repos\Hammer-Forge-Studio\.claude\worktrees\elastic-joliot\blender_experiments\space_suit_character\space_suit_character.blend`, `C:\repos\Hammer-Forge-Studio\.claude\worktrees\elastic-joliot\blender_experiments\space_suit_character\space_suit_character.obj`, `C:\repos\Hammer-Forge-Studio\.claude\worktrees\elastic-joliot\blender_experiments\space_suit_character\space_suit_character.glb`
- **Technical Strategy:** Multi-segment character from primitives (cylinders, spheres, cubes) posed at static joint positions. BMesh face-deletion for visor cutout from UV sphere. Bevel + SubSurf modifiers for smooth edges. 12 PBR materials: matte deep-blue suit (roughness 0.88), shiny gunmetal armor (roughness 0.18), near-mirror visor (roughness 0.03), emissive cyan device screen. 3-point area lighting with cyan point glow from wrist device. Cycles renderer @ 128 samples.
- **Challenges/Fixes:** None

---
