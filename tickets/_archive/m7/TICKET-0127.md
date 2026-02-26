---
id: TICKET-0127
title: "Cockpit diegetic status displays — ship globals on wall"
type: FEATURE
status: DONE
priority: P2
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-26
updated_at: 2026-02-26
milestone: "M7"
phase: "Build & Features"
depends_on: [TICKET-0126]
blocks: []
tags: [cockpit, ship-globals, diegetic-ui, hud, ship-interior]
---

## Summary

Add wall-mounted diegetic displays in the cockpit that show the four ship global variables (Power, Integrity, Heat, Oxygen) as in-world UI elements. These complement the existing HUD overlay — when inside the cockpit, the player can read ship status from the environment itself.

## Design Intent

The mobile-base design spec describes the ship as a "living entity." Diegetic displays reinforce this — the cockpit feels like a real control room, not just a room with a HUD overlay. The displays should read as physical screens/panels mounted on the cockpit wall.

## Visual Spec

- **Location:** Wall-mounted in the cockpit, near the navigation console (exact position defined by `StatusDisplayArea` Marker3D in TICKET-0126)
- **Count:** 4 displays — one per ship global variable
- **Layout:** Horizontal row or 2×2 grid (whichever fits the cockpit wall space per wireframes)
- **Each display shows:**
  - Variable name label (e.g., "POWER")
  - Current value as percentage (e.g., "85%")
  - Color-coded bar or fill indicator matching the HUD style guide colors
- **Display mesh:** A `MeshInstance3D` (flat plane or thin box) with a `SubViewport` rendering a simple Control UI, OR a `Label3D` for a lightweight approach
- **Material:** Emissive to be readable regardless of ambient lighting
- **Greybox style:** Simple geometric panel frame (dark grey border) with emissive content area

## Implementation Approaches

**Option A — SubViewport (richer):**
- Each display is a `SubViewportContainer` → `SubViewport` → `Control` scene with labels and progress bars
- Mounted on a `MeshInstance3D` flat plane
- Pro: Full UI toolkit available (ProgressBar, Label, theming)
- Con: 4 SubViewports adds minor overhead

**Option B — Label3D (lightweight):**
- Each display is a `Label3D` node with formatted text
- Color changes via script
- Pro: Zero UI overhead, simple
- Con: Limited formatting (no progress bars)

Choose whichever approach the wireframe spec recommends, or default to Option A for visual quality.

## Data Binding

- Read ship globals from `ShipState` autoload (same source as the existing HUD)
- Update displays via signal connections (`ShipState.power_changed`, etc.)
- Displays should update in real-time (same refresh as HUD)

## Acceptance Criteria

- [x] 4 diegetic displays exist in the cockpit showing Power, Integrity, Heat, Oxygen
- [x] Displays update in real-time from `ShipState` signals
- [x] Values match the existing HUD ship globals display exactly
- [x] Displays are readable from the player's standing position in the cockpit
- [x] Emissive material ensures readability in any lighting condition
- [x] Scene is independently testable (displays work when cockpit is loaded)
- [x] All code follows `docs/engineering/coding-standards.md`

## Implementation Notes

- The `StatusDisplayArea` Marker3D from TICKET-0126 provides the anchor position
- Consider creating a reusable `ship_status_display.tscn` subscene for a single display, then instancing it 4 times with different variable bindings
- The existing `ShipState` autoload already emits signals for all 4 globals — connect to those

## Handoff Notes
- Used Option A (SubViewport) for full UI toolkit: each display renders a 256x128 SubViewport onto a QuadMesh with emissive unshaded material
- Created reusable `ship_status_display.tscn` subscene, instanced 4 times in `ship_interior.tscn` with exported `variable_name` and `variable_type` properties
- Display positions: horizontal row at StatusDisplayArea (Y=1.5, Z=-9), X offsets: -0.825, -0.275, +0.275, +0.825
- Each display: 0.5m × 0.25m with dark grey (#333333) frame and emissive screen (emission_energy=1.5, SHADING_MODE_UNSHADED)
- Colors, thresholds, pulse animation, and percentage format match `ShipGlobalsHUD` exactly
- Signal connections: power_changed, integrity_changed, heat_changed, oxygen_changed from ShipState autoload
- No changes to ship_interior.gd — StatusDisplayArea Marker3D preserved as reference point
- Note: `.gd.uid` for `ship_status_display.gd` pending Godot editor filesystem scan

## Activity Log
- 2026-02-26 [producer] Created ticket — cockpit diegetic ship status displays
- 2026-02-26 [gameplay-programmer] Starting work — implementing diegetic status displays in cockpit
- 2026-02-26 [gameplay-programmer] Completed — commit 7222a65, PR https://github.com/sqlhammer/Hammer-Forge-Studio/pull/96 (merged)
