---
id: TICKET-0128
title: "Cockpit exterior viewport/window"
type: FEATURE
status: IN_PROGRESS
priority: P2
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-26
updated_at: 2026-02-26
milestone: "M7"
phase: "Build & Features"
depends_on: [TICKET-0126]
blocks: []
tags: [cockpit, viewport, window, ship-interior, visual]
---

## Summary

Add a window or viewport in the cockpit that shows the exterior world. When the player is in the cockpit, they should be able to look through a window and see the outside environment — reinforcing the sense that the ship exists in the world, not in a separate disconnected interior.

## Design Intent

The cockpit window is a key immersion element. It connects the interior space to the exterior world, making the ship feel like a real vessel rather than a teleportation destination. In M8 (Ship Navigation), this viewport will become the primary visual during travel sequences.

## Implementation Approaches

**Option A — SubViewport with exterior camera:**
- A `SubViewport` renders a secondary camera positioned at the ship's exterior location, facing forward
- The viewport texture is applied to a `MeshInstance3D` (flat plane) representing the window
- Pro: True real-time view of the exterior world; works for navigation in M8
- Con: Performance cost of a second camera render; needs camera position syncing

**Option B — Transparent opening in geometry:**
- A gap in the cockpit wall geometry (no mesh where the window is)
- The player's camera naturally sees through the opening to the exterior
- Requires the ship interior and exterior to exist in the same world space simultaneously
- Pro: Zero performance cost; natural parallax
- Con: Requires rethinking how the ship interior is loaded (currently separate scene with fade transition)

**Option C — Static skybox/texture (placeholder):**
- A `TextureRect` or `MeshInstance3D` with a static exterior image or simple procedural sky shader
- Not a real view, but reads as a window
- Pro: Simplest implementation; no architectural changes needed
- Con: Not dynamic; will need replacement for M8

**Recommendation:** Start with Option C (static/procedural) for M7 greybox. Leave architecture notes for M8 to upgrade to Option A or B when navigation requires a live exterior view.

## Visual Spec

- **Location:** Front wall of cockpit, above or beside the navigation console (exact position defined by `ViewportArea` Marker3D in TICKET-0126)
- **Size:** ~3m wide × 1.5m tall (large enough to feel like a real ship window)
- **Frame:** Dark grey border mesh (consistent with greybox palette)
- **Content:** Procedural sky gradient or static exterior screenshot — should read as "outside" at a glance
- **Emissive:** The window content should be slightly emissive to simulate natural light coming through

## Acceptance Criteria

- [ ] A window/viewport element exists in the cockpit at the designated position
- [ ] The window visually reads as showing the exterior (static or procedural is acceptable for M7)
- [ ] Window has a physical frame mesh consistent with greybox style
- [ ] Window is visible and legible from the player's normal walking position in the cockpit
- [ ] A comment or `Marker3D` documents where to anchor a live camera feed for M8
- [ ] Scene runs without errors
- [ ] All code follows `docs/engineering/coding-standards.md`

## Implementation Notes

- The `ViewportArea` Marker3D from TICKET-0126 provides the anchor position
- For the static approach: a `MeshInstance3D` plane with an emissive `ShaderMaterial` that renders a simple sky gradient (blue top → orange horizon) is sufficient for greybox
- Leave a clear TODO comment in the script/scene for M8 upgrade path
- If performance is not a concern and the wireframe recommends it, Option A (SubViewport) can be used directly

## Handoff Notes
- Added `_build_viewport_window()` to `ship_interior.gd` — creates a QuadMesh (3.8m×1.4m) with a procedural sky gradient shader (blue top → orange horizon)
- Window pane positioned at (0, 2.25, -11.95), centered in the existing viewport opening (4m×1.5m, framed by `_build_viewport_frame()`)
- Shader uses `render_mode unshaded, cull_disabled` — window content always visible regardless of interior lighting
- Added `ViewportLight` OmniLight3D at (0, 2.25, -11.5) with warm color (0.85, 0.75, 0.6) to simulate sunlight through window
- Existing `ViewportArea` Marker3D at (0, 2.25, -12) documented as M8 camera anchor with TODO comments
- TODO comments in both `_build_cockpit_features()` and `_build_viewport_window()` describe the M8 SubViewport upgrade path
- No new scripts created — all changes in existing `ship_interior.gd`
- Frame mesh (bottom, left, right edges) was already built by TICKET-0126

## Activity Log
- 2026-02-26 [producer] Created ticket — cockpit exterior viewport/window
- 2026-02-26 [gameplay-programmer] Starting work — implementing cockpit exterior viewport/window
