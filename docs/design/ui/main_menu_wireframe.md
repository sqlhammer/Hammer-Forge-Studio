# Main Menu — Wireframe & Layout Spec

**Ticket:** TICKET-0237
**Owner:** ui-ux-designer
**Status:** Approved (self-approved per producer note)
**Target Resolution:** 1920×1080 (reference); graceful degradation to 1280×720
**Blocks:** TICKET-0231

---

## Overview

Minimal first-pass main menu for M9 Root Game. A single centered **Play** button on a dark background. The layout reserves space for a title logo above the button and a footer row below — neither is implemented in M9, but the vertical rhythm is designed to accommodate them without refactoring.

---

## ASCII Wireframe

```
┌─────────────────────────────────────────────────────┐  1920×1080
│                                                     │
│                                                     │
│                                                     │
│                                                     │
│              ┌─────────────────────┐                │  <- Logo zone (reserved,
│              │   [TITLE LOGO]      │                │     empty in M9 — 400×120px)
│              │   (reserved)        │                │
│              └─────────────────────┘                │
│                                                     │
│                    ┌───────────┐                    │
│                    │   Play    │                    │  <- Play button (centered)
│                    └───────────┘                    │
│                                                     │
│                                                     │
│                                                     │
│              [Settings]  [Credits]  [Quit]          │  <- Footer row (reserved,
│                                                     │     not implemented M9)
└─────────────────────────────────────────────────────┘
```

### Vertical Distribution (at 1080p)

The scene root is a full-viewport `Control` with a single `VBoxContainer` centered vertically and horizontally via `PRESET_CENTER`.

| Zone | Height | Content |
|------|--------|---------|
| Top spacer | ~300px | `Control` spacer node, flexible |
| Logo zone | 120px | `Control` node (empty in M9; reserved slot for future logo `TextureRect`) |
| Gap | 48px | `sp-8` × 1.5 spacing |
| Button zone | 60px | Play `Button` node |
| Gap | 48px | Reserved |
| Footer zone | 40px | `Control` node (empty in M9; reserved for settings/credits row) |
| Bottom spacer | flexible | Remaining space |

---

## Scene Structure

```
MainMenu (Control)
  └─ Background (ColorRect)               ← full-rect anchor, color #1a1a2e
  └─ CenterContainer (CenterContainer)    ← full-rect anchor, stretches to viewport
       └─ MenuLayout (VBoxContainer)      ← alignment="center", no size override
            └─ LogoZone (Control)         ← custom_minimum_size = (400, 120) [reserved]
            └─ Spacer1 (Control)          ← custom_minimum_size = (0, 48)
            └─ PlayButton (Button)        ← see Button Spec below
            └─ Spacer2 (Control)          ← custom_minimum_size = (0, 48)
            └─ FooterZone (Control)       ← custom_minimum_size = (0, 40) [reserved]
```

**Root node:** `MainMenu` — type `Control`
- `anchor_preset` = `PRESET_FULL_RECT` (fills viewport)
- `process_mode` = `PROCESS_MODE_ALWAYS` (menu must respond even if game is paused)

**Background:** `ColorRect`
- `color` = `#1a1a2e` (solid, no alpha — this is a full-screen menu, not an overlay)
- `anchor_preset` = `PRESET_FULL_RECT`

**CenterContainer:** anchored `PRESET_FULL_RECT`, stretches to fill `MainMenu`; its single child `MenuLayout` is centered automatically.

---

## Button Spec — Play Button

### Size & Layout

| Property | Value |
|----------|-------|
| `custom_minimum_size` | `(200, 60)` |
| `size_flags_horizontal` | `SHRINK_CENTER` |
| Text | `"Play"` |
| Font size | `hud-lg` — 24px Bold |
| Font color (normal) | `#F1F5F9` (Text Primary) |

### StyleBox — Normal State

| Property | Value |
|----------|-------|
| Background color | `#1A2736` (Panel BG Light) |
| Border color | `#007A63` (Primary Dim) |
| Border width | 1px all sides |
| Border radius | 4px |
| Content margin | 8px vertical, 16px horizontal (`sp-2` / `sp-4`) |

### StyleBox — Hover State

| Property | Value |
|----------|-------|
| Background color | `#1A2736` lightened — use `#243447` |
| Border color | `#00D4AA` (Primary Teal) |
| Border width | 1px all sides |
| Border radius | 4px |
| Font color | `#00D4AA` (Text Highlight) |

> Hover is mouse-only. Gamepad uses Focused state (Teal 2px outline — Godot's built-in focus visual, `theme_override_styles/focus` StyleBoxFlat with no background, 2px teal border).

### StyleBox — Pressed State

| Property | Value |
|----------|-------|
| Background color | `#0F1923` (Panel BG) |
| Border color | `#00D4AA` (Primary Teal) |
| Border width | 2px all sides |
| Border radius | 4px |
| Font color | `#F1F5F9` |
| Scale | `0.97` (via `Tween` on `scale`, 50ms ease-out) |

### StyleBox — Focused State (gamepad)

| Property | Value |
|----------|-------|
| Background color | transparent |
| Border color | `#00D4AA` (Primary Teal) |
| Border width | 2px all sides |
| Border radius | 4px |

### Button State Summary

| State | BG Color | Border Color | Border Width | Text Color | Notes |
|-------|----------|--------------|--------------|------------|-------|
| Normal | `#1A2736` | `#007A63` | 1px | `#F1F5F9` | Default |
| Hover | `#243447` | `#00D4AA` | 1px | `#00D4AA` | Mouse cursor over |
| Pressed | `#0F1923` | `#00D4AA` | 2px | `#F1F5F9` | 0.97x scale, 50ms |
| Focused | `#1A2736` | `#00D4AA` | 2px | `#F1F5F9` | Gamepad focus ring |
| Disabled | `#1A2736` at 40% | `#94A3B8` at 40% | 1px | `#94A3B8` | (not used in M9) |

---

## Color Reference

| Element | Hex | Style Guide Token |
|---------|-----|-------------------|
| Screen background | `#1a1a2e` | (custom — darker than Panel BG, full-screen menu) |
| Button background | `#1A2736` | Panel BG Light |
| Button border (normal) | `#007A63` | Primary Dim |
| Button border (active) | `#00D4AA` | Primary Teal |
| Button text | `#F1F5F9` | Text Primary |
| Button text (hover) | `#00D4AA` | Text Highlight |

---

## Anchoring & Responsiveness

- `MainMenu` Control: `PRESET_FULL_RECT` — fills viewport at any resolution
- `CenterContainer`: `PRESET_FULL_RECT` — always centers its child
- `MenuLayout` (`VBoxContainer`): no explicit size; grows to fit content, centered by parent
- The `LogoZone` and `FooterZone` are fixed-height placeholder `Control` nodes — they expand the vertical rhythm but contain no visible content in M9
- The Play button is `SHRINK_CENTER` horizontally — never stretches wider than `custom_minimum_size.x` (200px)

**Target behavior:** At 720p the button remains 200×60px centered on screen. At 4K, Godot's `canvas_items` stretch mode scales everything proportionally.

---

## Signals (for TICKET-0231 — Gameplay Programmer)

The `MainMenu` scene emits one signal. The gameplay programmer wires this to start the game.

```gdscript
signal play_pressed
```

The Play `Button`'s `pressed` signal connects to a handler in `MainMenu` that emits `play_pressed`. No game logic lives in this scene — all transition logic is in the wiring layer.

**Exported property for wiring:**

```gdscript
@export var next_scene_path: String = ""
```

The gameplay programmer sets this to `res://scenes/gameplay/game_world.tscn` (or equivalent) in the inspector.

---

## Future Extension Points

| Future Element | Where It Slots |
|----------------|----------------|
| Title logo / game title text | `LogoZone` Control node — add a `TextureRect` or `Label` child. No structural change needed. |
| Settings button | `FooterZone` — add an `HBoxContainer` with Settings / Credits / Quit buttons. No structural change needed. |
| Version label | `FooterZone` corner — absolute-positioned `Label` child, anchored bottom-right of `MainMenu` |
| Background parallax / animated bg | Replace `Background` `ColorRect` with a `SubViewport` or shader layer — `CenterContainer` sits above it unchanged |
| Music / ambient audio | `AudioStreamPlayer` child of `MainMenu` root — no layout impact |

---

## Implementation Checklist (for TICKET-0231)

- [ ] Create `game/scenes/ui/main_menu.tscn` with the scene structure above
- [ ] `MainMenu` root: `Control`, full-rect anchor, `PROCESS_MODE_ALWAYS`
- [ ] `Background`: `ColorRect`, full-rect anchor, `#1a1a2e`
- [ ] `CenterContainer`: full-rect anchor
- [ ] `MenuLayout`: `VBoxContainer`, alignment center
- [ ] `LogoZone`: `Control`, `custom_minimum_size = (400, 120)` [empty in M9]
- [ ] `Spacer1`: `Control`, `custom_minimum_size = (0, 48)`
- [ ] `PlayButton`: `Button`, text "Play", `custom_minimum_size = (200, 60)`, size_flags_h = SHRINK_CENTER
- [ ] `Spacer2`: `Control`, `custom_minimum_size = (0, 48)`
- [ ] `FooterZone`: `Control`, `custom_minimum_size = (0, 40)` [empty in M9]
- [ ] Apply StyleBoxFlat to PlayButton for all states (Normal, Hover, Pressed, Focused)
- [ ] Connect `PlayButton.pressed` → emit `play_pressed` signal
- [ ] Export `next_scene_path: String`
- [ ] Verify renders correctly at 1920×1080 and 1280×720
