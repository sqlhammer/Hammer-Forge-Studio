---
id: TICKET-0120
title: "Asset — Create automation hub module mesh (mesh_automation_hub_module.glb)"
type: TASK
status: TODO
priority: P2
owner: technical-artist
created_by: producer
created_at: 2026-02-25
updated_at: 2026-02-25
milestone: "M5"
phase: "QA"
depends_on: []
blocks: []
tags: [asset, automation-hub, mesh, missing-file]
---

## Summary

The automation hub module mesh is missing from the project. When a player installs the Automation Hub module, `test_world.gd:541` attempts to load `res://assets/meshes/machines/mesh_automation_hub_module.glb` and Godot logs:

```
E 0:01:12:386   test_world.gd:541 @ _place_module_visual(): Resource file not found:
                res://assets/meshes/machines/mesh_automation_hub_module.glb (expected type: unknown)
```

The code falls through to `_place_module_fallback()` (placeholder box mesh), so the game does not crash, but the asset must be delivered for the module to have a proper visual.

## Expected Delivery

Produce and import `mesh_automation_hub_module.glb` at:

```
game/assets/meshes/machines/mesh_automation_hub_module.glb
```

### Design Reference

- Follow the same art style as the recycler (`mesh_recycler_module.glb`) and fabricator (`mesh_fabricator_module.glb`) already in the same directory.
- Intended collision box: `Vector3(2.2, 1.4, 1.2)` — size the mesh to fit within those dimensions.
- The module occupies Zone C (rightmost zone) of the ship interior bay.

### Import Requirements

- Export as `.glb` (GLTF binary)
- Scene root must be a `MeshInstance3D` or `Node3D` containing one; the code calls `.instantiate()` on the loaded `PackedScene`
- No rig or animation required — static mesh only

## Acceptance Criteria

- [ ] `game/assets/meshes/machines/mesh_automation_hub_module.glb` exists and is committed
- [ ] Installing the Automation Hub module renders the mesh in Zone C — no resource-not-found error in the log
- [ ] Mesh visually fits within `Vector3(2.2, 1.4, 1.2)` with no significant overflow
- [ ] Art style matches the recycler and fabricator modules
- [ ] All code follows `docs/engineering/coding-standards.md`

## Activity Log

- 2026-02-25 [producer] Created ticket — automation hub placed as fallback box due to missing GLB asset
