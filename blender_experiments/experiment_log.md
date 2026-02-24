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

### [2026-02-22 09:47:01] - Object: mesh_hand_drill
- **Original Prompt:** "Handheld sci-fi extraction drill, stylized chunky proportions."
- **Output Files:** `C:\repos\Hammer-Forge-Studio\blender_experiments\poc_output\mesh_hand_drill.blend`, `C:\repos\Hammer-Forge-Studio\blender_experiments\poc_output\mesh_hand_drill.obj`, `C:\repos\Hammer-Forge-Studio\blender_experiments\poc_output\mesh_hand_drill.glb`
- **Technical Strategy:** Beveled primitives with 8 PBR materials.
- **Challenges/Fixes:** None

---

### [2026-02-22 09:47:02] - Object: mesh_player_character
- **Original Prompt:** "Full-body humanoid in environmental research suit, T-pose, ~1.8m."
- **Output Files:** `C:\repos\Hammer-Forge-Studio\blender_experiments\poc_output\mesh_player_character.blend`, `C:\repos\Hammer-Forge-Studio\blender_experiments\poc_output\mesh_player_character.obj`, `C:\repos\Hammer-Forge-Studio\blender_experiments\poc_output\mesh_player_character.glb`
- **Technical Strategy:** Multi-segment primitives with BMesh visor cutout, 10 PBR materials.
- **Challenges/Fixes:** None

---

### [2026-02-22 09:47:02] - Object: mesh_ship_exterior
- **Original Prompt:** "Atmospheric research vessel, utilitarian sci-fi, ~15m long."
- **Output Files:** `C:\repos\Hammer-Forge-Studio\blender_experiments\poc_output\mesh_ship_exterior.blend`, `C:\repos\Hammer-Forge-Studio\blender_experiments\poc_output\mesh_ship_exterior.obj`, `C:\repos\Hammer-Forge-Studio\blender_experiments\poc_output\mesh_ship_exterior.glb`
- **Technical Strategy:** Beveled box hull sections with engine cylinders, 8 PBR materials.
- **Challenges/Fixes:** None

---

### [2026-02-22 09:47:02] - Object: mesh_resource_node_scrap
- **Original Prompt:** "Scrap metal deposit in alien debris, ~2m wide."
- **Output Files:** `C:\repos\Hammer-Forge-Studio\blender_experiments\poc_output\mesh_resource_node_scrap.blend`, `C:\repos\Hammer-Forge-Studio\blender_experiments\poc_output\mesh_resource_node_scrap.obj`, `C:\repos\Hammer-Forge-Studio\blender_experiments\poc_output\mesh_resource_node_scrap.glb`
- **Technical Strategy:** Deformed spheres + beveled cubes, seeded random, 7 PBR materials.
- **Challenges/Fixes:** None

---

### [2026-02-23 21:11:20] - Object: mesh_recycler_module
- **Original Prompt:** "Recycler module machine — a chunky, utilitarian processing unit for a ship interior. Input hopper on the left, output tray on the right, front-facing screen panel. 1.8m wide x 1.2m deep x 1.4m tall. Greybox quality with flat PBR materials. Industrial, cobbled-together aesthetic (Outer Wilds tool station reference)."
- **Output Files:** `C:\repos\Hammer-Forge-Studio\.claude\worktrees\declarative-jingling-treehouse\blender_experiments\mesh_recycler_module\mesh_recycler_module.blend`, `C:\repos\Hammer-Forge-Studio\.claude\worktrees\declarative-jingling-treehouse\blender_experiments\mesh_recycler_module\mesh_recycler_module.obj`, `C:\repos\Hammer-Forge-Studio\.claude\worktrees\declarative-jingling-treehouse\blender_experiments\mesh_recycler_module\mesh_recycler_module.glb`
- **Technical Strategy:** Beveled boxes for main body, base, and panel seams. Cone for hopper funnel, torus for hopper lip. Flat plane for emissive screen surface. UV spheres for status/power indicator lights. 7 PBR materials covering body, seams, base, hopper interior, emissive screen, and indicator lights.
- **Challenges/Fixes:** None

---

### [2026-02-23 21:12:50] - Object: mesh_recycler_module
- **Original Prompt:** "Recycler module machine — a chunky, utilitarian processing unit for a ship interior. Input hopper on the left, output tray on the right, front-facing screen panel. 1.8m wide x 1.2m deep x 1.4m tall. Greybox quality with flat PBR materials. Industrial, cobbled-together aesthetic (Outer Wilds tool station reference)."
- **Output Files:** `C:\repos\Hammer-Forge-Studio\.claude\worktrees\declarative-jingling-treehouse\blender_experiments\mesh_recycler_module\mesh_recycler_module.blend`, `C:\repos\Hammer-Forge-Studio\.claude\worktrees\declarative-jingling-treehouse\blender_experiments\mesh_recycler_module\mesh_recycler_module.obj`, `C:\repos\Hammer-Forge-Studio\.claude\worktrees\declarative-jingling-treehouse\blender_experiments\mesh_recycler_module\mesh_recycler_module.glb`
- **Technical Strategy:** Beveled boxes for main body, base, and panel seams. Cone for hopper funnel, torus for hopper lip. Flat plane for emissive screen surface. UV spheres for status/power indicator lights. 7 PBR materials covering body, seams, base, hopper interior, emissive screen, and indicator lights.
- **Challenges/Fixes:** None

---

### [2026-02-23 21:13:44] - Object: mesh_recycler_module
- **Original Prompt:** "Recycler module machine — a chunky, utilitarian processing unit for a ship interior. Input hopper on the left, output tray on the right, front-facing screen panel. 1.8m wide x 1.2m deep x 1.4m tall. Greybox quality with flat PBR materials. Industrial, cobbled-together aesthetic (Outer Wilds tool station reference)."
- **Output Files:** `C:\repos\Hammer-Forge-Studio\.claude\worktrees\declarative-jingling-treehouse\blender_experiments\mesh_recycler_module\mesh_recycler_module.blend`, `C:\repos\Hammer-Forge-Studio\.claude\worktrees\declarative-jingling-treehouse\blender_experiments\mesh_recycler_module\mesh_recycler_module.obj`, `C:\repos\Hammer-Forge-Studio\.claude\worktrees\declarative-jingling-treehouse\blender_experiments\mesh_recycler_module\mesh_recycler_module.glb`
- **Technical Strategy:** Beveled boxes for main body, base, and panel seams. Cone for hopper funnel, torus for hopper lip. Flat plane for emissive screen surface. UV spheres for status/power indicator lights. 7 PBR materials covering body, seams, base, hopper interior, emissive screen, and indicator lights.
- **Challenges/Fixes:** None

---

### [2026-02-23 21:14:24] - Object: mesh_recycler_module
- **Original Prompt:** "Recycler module machine — a chunky, utilitarian processing unit for a ship interior. Input hopper on the left, output tray on the right, front-facing screen panel. 1.8m wide x 1.2m deep x 1.4m tall. Greybox quality with flat PBR materials. Industrial, cobbled-together aesthetic (Outer Wilds tool station reference)."
- **Output Files:** `C:\repos\Hammer-Forge-Studio\.claude\worktrees\declarative-jingling-treehouse\blender_experiments\mesh_recycler_module\mesh_recycler_module.blend`, `C:\repos\Hammer-Forge-Studio\.claude\worktrees\declarative-jingling-treehouse\blender_experiments\mesh_recycler_module\mesh_recycler_module.obj`, `C:\repos\Hammer-Forge-Studio\.claude\worktrees\declarative-jingling-treehouse\blender_experiments\mesh_recycler_module\mesh_recycler_module.glb`
- **Technical Strategy:** Beveled boxes for main body, base, and panel seams. Cone for hopper funnel, torus for hopper lip. Flat plane for emissive screen surface. UV spheres for status/power indicator lights. 7 PBR materials covering body, seams, base, hopper interior, emissive screen, and indicator lights.
- **Challenges/Fixes:** None

---

### [2026-02-24 09:06:57] - Object: mesh_fabricator_module
- **Original Prompt:** "Fabricator module machine — a wide, low crafting workbench for a ship interior. Flat work surface on top with articulated press arm, front-facing screen panel, output drawer on the right, storage bins on the left. 2.0m wide x 1.0m deep x 1.2m tall. Greybox quality with flat PBR materials. Assembly station aesthetic, visually distinct from the taller Recycler machine."
- **Output Files:** `C:\repos\Hammer-Forge-Studio\.claude\worktrees\buzzing-splashing-firefly\blender_experiments\mesh_fabricator_module\mesh_fabricator_module.blend`, `C:\repos\Hammer-Forge-Studio\.claude\worktrees\buzzing-splashing-firefly\blender_experiments\mesh_fabricator_module\mesh_fabricator_module.obj`, `C:\repos\Hammer-Forge-Studio\.claude\worktrees\buzzing-splashing-firefly\blender_experiments\mesh_fabricator_module\mesh_fabricator_module.glb`
- **Technical Strategy:** Beveled boxes for cabinet body, base, surface, and panel details. Cylinder and cone for press arm head/nozzle. Torus for arm joint collar. Flat plane for emissive screen. UV spheres for status/power lights. 9 PBR materials covering body, seams, base, work surface, arm metal, drawer interior, emissive screen, and indicator lights.
- **Challenges/Fixes:** None

---

### [2026-02-24 13:38:44] - Object: mesh_ship_exterior
- **Original Prompt:** "Atmospheric research vessel, mobile base. Chunky utilitarian sci-fi, Outer Wilds aesthetic. Asymmetric hull with cargo pod, dual main engines, cockpit windshield, antenna array, landing gear deployed. ~45m long (3x original). Riveted plating, orange accent stripes."
- **Output Files:** `C:\repos\Hammer-Forge-Studio\blender_experiments\mesh_ship_exterior\mesh_ship_exterior.blend`, `C:\repos\Hammer-Forge-Studio\blender_experiments\mesh_ship_exterior\mesh_ship_exterior.obj`, `C:\repos\Hammer-Forge-Studio\blender_experiments\mesh_ship_exterior\mesh_ship_exterior.glb`
- **Technical Strategy:** Beveled box primitives for hull sections (main, fore, aft, cargo pod). Cylinders for engines and thruster nozzles. Asymmetric cargo pod on starboard. Hull detail via accent strips, panel seams, hatches. Antenna array with dish and mast. Three-point landing gear with strut + pad + hydraulic. 8 PBR materials. 3x uniform scale applied post-build and baked into mesh data (TICKET-0081).
- **Challenges/Fixes:** None

---
