# Wireframe: Third-Person Scan/Mine HUD

**Component:** Third-Person Camera — Scanner and Mining HUD Adaptation
**Ticket:** TICKET-0065
**Blocks:** TICKET-0071 (Third-person scan/mine gameplay)
**Last Updated:** 2026-02-24
**Reference:** `docs/design/wireframes/m3/hud-layout-overview.md` (first-person baseline)

---

## Purpose

The third-person camera mode (orbital around the ship) requires adapted scanner and mining HUD elements. The core systems are identical to first-person — this spec covers only the layout and positioning differences driven by third-person camera perspective. No redesign of the underlying systems; only the camera-perspective-specific presentation.

**Third-person context:** The player controls the ship in a top-down or orbital camera view. Scanner pings sweep outward from the ship. Mining interaction (drilling deposits near the ship) still occurs. The orbital camera means the crosshair model does not apply; deposit targeting uses proximity/highlight rather than aim-based raycasting.

---

## What Carries Over Unchanged

These HUD elements are used in both camera modes without modification:

| Element | Status |
|---------|--------|
| Compass bar | ✅ Same — compass north/deposit markers unchanged |
| Battery bar | ✅ Same — bottom-left corner, unchanged |
| Pickup notifications | ✅ Same — center-right stacking, unchanged |
| Ship globals HUD | ✅ Same — bottom-right corner (when applicable) |

---

## What Changes in Third-Person

| Element | First-Person | Third-Person |
|---------|-------------|-------------|
| Crosshair | Center crosshair (+) | **Removed** — no aim-based targeting |
| Scanner readout panel | Center-right of screen | **Bottom-center**, above battery bar area |
| Mining progress bar | Center, below crosshair | **Bottom-center**, above scanner readout |
| Deposit target highlight | Aim-based (raycast to center screen) | **Proximity-based** — nearest deposit within range highlighted in world space |
| Mining action prompt | Center-screen "EXTRACTING" label | **Above deposit marker** in world space (world-space label, not HUD) |
| Minigame overlay | Bottom-center (same as first-person) | ✅ Same position — no change needed |

---

## Third-Person HUD Layout Diagram

```
    ┌──────────────────────────────────────────────────────────────────────────┐
    │  32px safe margin                                                        │
    │  ┌────────────────────────────────────────────────────────────────────┐  │
    │  │                                                                    │  │
    │  │                  ┌─────────────────────────┐                      │  │
    │  │                  │       COMPASS BAR        │  ← top-center       │  │
    │  │                  │  W  NW  N  NE  E  ▼47m  │    (unchanged)      │  │
    │  │                  └─────────────────────────┘                      │  │
    │  │                                                                    │  │
    │  │                                                                    │  │
    │  │       [3D ship model — third-person orbital camera view]           │  │
    │  │                                                                    │  │
    │  │                                                                    │  │
    │  │              [highlighted deposit in world space]                  │  │
    │  │              ↑ world-space outline (Teal ring), not HUD            │  │
    │  │                                                                    │  │
    │  │                                                                    │  │
    │  │                                                                    │  │
    │  │                                                                    │  │
    │  │             ┌─────────────────────────────────────┐               │  │
    │  │             │█████████████████░░░░░░░░░░░░░░░░░░░░│               │  │
    │  │             └─────────────────────────────────────┘               │  │
    │  │             ↑ mining progress bar, bottom-center                  │  │
    │  │               (same spec as first-person, same position)          │  │
    │  │                                                                    │  │
    │  │             ┌──────────────────────────┐                          │  │
    │  │             │  ◆ SCAN RESULTS           │                         │  │
    │  │             │  Purity   ★★★★☆          │                         │  │
    │  │             │  Density  Medium          │                         │  │
    │  │             │  Energy   34% ⚡          │                         │  │
    │  │             └──────────────────────────┘                          │  │
    │  │             ↑ scanner readout, bottom-center                      │  │
    │  │               repositioned from center-right (1P) to              │  │
    │  │               bottom-center (3P), 32px above mining bar           │  │
    │  │                                                                    │  │
    │  │  ⚡ ████████░░░░  72%                                              │  │
    │  │  ↑ battery bar (bottom-left, unchanged)                           │  │
    │  └────────────────────────────────────────────────────────────────────┘  │
    │  32px safe margin                                                        │
    └──────────────────────────────────────────────────────────────────────────┘
                              1920 x 1080
```

---

## Scanner Readout — Third-Person Repositioning

In first-person, the scanner readout sits at center-right because the player aims at deposits and the readout appears near the aim direction. In third-person, there is no aim direction — the readout moves to bottom-center where it is accessible without obscuring the world view.

### Third-Person Readout Position

- **Position:** Bottom-center
- **Anchor:** `center_bottom`
- **Offset from bottom:** 96px (32px safe area + mining bar height 48px + 16px gap)
- **Panel spec:** Identical to first-person (`docs/design/wireframes/m3/scanner-readout.md`)
- **Width:** 260px (unchanged)
- **Dismiss:** Same trigger as first-person — dismissed when mining starts, or after 8s

---

## Mining Progress Bar — Third-Person Position

The mining progress bar is already at bottom-center in first-person. It stays at bottom-center in third-person — no repositioning needed.

- **Position:** Bottom-center, 48px above safe margin (same as first-person)
- Spec: identical to `docs/design/wireframes/m3/mining-progress.md`

---

## Deposit Targeting — World-Space Highlight

In third-person, deposits are targeted by proximity (nearest deposit within scanner range that the player is moving toward, or the deposit the player has activated via scanner ping). No crosshair.

### Highlighted Deposit Visual (World Space — not HUD)

- **Outline:** Teal ring (`#00D4AA`, 3px) around the base of the deposit mesh
- **Glow:** Subtle Teal bloom around the ring (shader-level — coordinate with gameplay-programmer)
- **Label:** Small world-space label floating 0.5m above the deposit: resource type name, `hud-xs` (14px), Text Primary, Panel BG background pill

### Mining Action Prompt — World Space

When the player is within mining range of a highlighted deposit:

```
    [Hold E / Hold X] Mine
```

- **Position:** World-space label, 1m above the deposit (above the resource type label)
- **Font:** `hud-sm` (16px)
- **Background:** Panel BG pill (`#0F1923` at 80%), rounded, `sp-2` padding
- **Input glyph:** Show keyboard key label or gamepad button label (same input system as first-person prompts)

**Note:** The world-space prompts are implemented by gameplay-programmer; this spec defines the visual design only.

---

## Scanner Ping — Third-Person Adaptation

In first-person, the scanner ping is initiated via a radial wheel (D-013 / meaningful-mining.md Phase 1). In third-person, the radial wheel interaction is identical — same UI, same input. The ping expands from the ship's position (not the camera's position) in third-person.

No new HUD elements are required for the ping itself in third-person. The compass markers that appear post-ping are identical to first-person.

---

## Phase 2 Analysis — Third-Person Adaptation

In first-person, the player holds the Analyze button while standing near a deposit. In third-person, the same mechanic applies — the player navigates the ship adjacent to a deposit and holds Analyze.

The scan results panel in third-person:
- Same component spec as first-person
- **Position:** Bottom-center (as defined above) instead of center-right
- Animation: Same slide-in/out behavior

---

## Conflict Zone Check (Third-Person)

| Element A | Element B | Conflict? | Resolution |
|-----------|-----------|-----------|------------|
| Mining progress (bottom-center) | Scanner readout (bottom-center) | Possible — scanner dismisses when mining starts | Scanner dismisses on mine start; no co-visible conflict |
| Mining progress (bottom-center) | Minigame overlay (above mining bar) | No — minigame overlay sits above bar | Stacks vertically as designed |
| Pickup notifications (right) | Scanner readout (bottom-center) | No — different screen regions | |
| Battery bar (bottom-left) | Mining progress (bottom-center) | No — sufficient horizontal gap | |
| Compass (top-center) | Everything else | No — top region exclusive | |

---

## Gamepad Notes

- Third-person scanner ping: same radial wheel as first-person — no new controls
- Deposit targeting: D-pad or left stick moves ship/cursor; nearest valid deposit auto-highlights
- All interactions use the existing input map — no new bindings for third-person mode

---

## Implementation Notes

- The third-person HUD is the same HUD `CanvasLayer` as first-person — elements are repositioned, not replaced
- Scanner readout: Change anchor from center-right to center_bottom when third-person mode activates
- Mining progress bar: No positional change needed
- World-space labels (deposit name, action prompt): Implemented by gameplay-programmer using `Label3D` or a world-space `SubViewport` — this spec defines their visual appearance only
- Mode switch signal: `PlayerController.camera_mode_changed(mode)` triggers HUD element repositioning via `Tween` (200ms ease-out slide to new position)

---

## Mode-Switch Animation

When the player switches from first-person to third-person (or back):

- Scanner readout slides from center-right to bottom-center (or reverse), 200ms ease-out
- Other elements that don't move: no animation
- Crosshair: fade out 100ms when switching to third-person; fade in when returning to first-person

---

## Summary of Positional Differences

| Element | First-Person | Third-Person |
|---------|-------------|-------------|
| Crosshair | Center screen | Removed |
| Scanner readout | Center-right, mid-height | Bottom-center, above mining bar |
| Mining progress | Bottom-center | Bottom-center (unchanged) |
| Minigame overlay | Bottom-center, above mining bar | Bottom-center (unchanged) |
| Compass | Top-center | Top-center (unchanged) |
| Battery bar | Bottom-left | Bottom-left (unchanged) |
| Pickup notifications | Right, stacking | Right, stacking (unchanged) |
| Ship globals HUD | Bottom-right (in-ship only) | Bottom-right (unchanged) |
