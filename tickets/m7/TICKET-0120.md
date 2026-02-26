---
id: TICKET-0120
title: "Feature — Interaction Prompt HUD: contextual action hints and persistent controls"
type: FEATURE
status: TODO
priority: P2
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-25
updated_at: 2026-02-26
milestone: "M7"
phase: "Build & Features"
depends_on: [TICKET-0117]
blocks: []
tags: [ui, hud, interaction, input, ux]
---

## Summary

Add a two-part HUD overlay for player guidance:

1. **Contextual Interaction Prompt** — centered at the bottom of the screen. Appears when the player's crosshair is aimed at an interactable object within interaction range. Shows the active input binding and a short action descriptor. Actions that require holding the key are visually distinguished with a thicker border on the key badge.

2. **Persistent Controls Panel** — anchored to the bottom-right of the screen. Always visible. Shows controls that are available at all times regardless of what the player is looking at.

Both elements are self-contained subscenes instanced into `game_hud.tscn`.

---

## Interaction Prompt — Contextual Area

### Trigger Logic
- The prompt is driven by a raycast from the player's camera (reuse or extend the existing interaction raycast if one exists; add one if not).
- If the ray hits a `CollisionObject3D` that implements `get_interaction_prompt() -> Dictionary`, show the prompt. Otherwise, hide it.
- Interaction range matches the existing interaction distance constant (check `player_first_person.gd` or `InputManager`).

### `get_interaction_prompt()` Contract
Every interactable object that wants to surface a prompt must implement:

```gdscript
func get_interaction_prompt() -> Dictionary:
    return {
        "key": "E",        # String — the keyboard key or action name to display
        "label": "Scan",   # String — short descriptor (1–3 words max)
        "hold": true       # bool — true if the action requires holding the key
    }
```

Duck-typing check: use `object.has_method("get_interaction_prompt")` before calling. Do not require a formal interface or base class.

### Visual Design
- Container: `HBoxContainer` or `PanelContainer`, centered horizontally, anchored to the bottom of the screen with a consistent bottom margin (e.g., 80px from bottom edge).
- Key badge: a `Panel` or `Label` with a rounded or square border showing the key letter/symbol.
  - Normal action: standard 2px border.
  - Hold action (`"hold": true`): 4px border (or equivalent `StyleBoxFlat` border width increase) to signal "hold this key."
- Descriptor label: plain `Label` to the right of the key badge. Text from `"label"`.
- The entire prompt animates in/out (fade or slide) when it appears or disappears — a simple `Tween` on alpha or position is sufficient. No animation library required.
- Device-aware key display: if a gamepad is the active input device (detectable via `InputManager`), show the gamepad button glyph or label instead of the keyboard key. Fall back to keyboard if device detection is unavailable — do not block the ticket on full device detection if it is not yet implemented.

### Examples
| Situation | Display |
|-----------|---------|
| Pointing at unscanned resource node | `[E]` (thick border) `Scan` |
| Pointing at scanned resource node | `[E]` `Mine` |
| In ship entry zone | `[E]` `Enter Ship` |
| Nothing interactable in range | *(prompt hidden)* |

---

## Persistent Controls Panel — Bottom Right

A fixed panel, always visible, listing controls that are never context-dependent.

### Initial Entries

| Key | Icon Description | Label |
|-----|-----------------|-------|
| Q   | Radar / wifi signal symbol | Ping |
| I   | Bag / backpack symbol | Inventory |

Icons should be simple `TextureRect` nodes. Use placeholder solid-color squares or a built-in Godot icon if no art asset exists yet — do not block on custom icon art. Leave the layout and node structure clean so icons can be swapped in later.

### Visual Design
- Container: `VBoxContainer`, anchored to bottom-right with consistent margin (e.g., 16px from edges).
- Each row: `HBoxContainer` with `Label` (key), `TextureRect` (icon), `Label` (action name).
- Panel background: a semi-transparent `StyleBoxFlat` to keep it readable against the 3D scene.

---

## Scene Structure

```
interaction_prompt_hud.tscn (CanvasLayer root)
├── ContextualPrompt (CenterContainer, anchored bottom-center)
│   └── PromptBox (HBoxContainer)
│       ├── KeyBadge (Panel)
│       │   └── KeyLabel (Label)
│       └── ActionLabel (Label)
└── PersistentControls (VBoxContainer, anchored bottom-right)
    ├── PingRow (HBoxContainer)
    │   ├── KeyLabel (Label — "Q")
    │   ├── PingIcon (TextureRect)
    │   └── ActionLabel (Label — "Ping")
    └── InventoryRow (HBoxContainer)
        ├── KeyLabel (Label — "I")
        ├── InventoryIcon (TextureRect)
        └── ActionLabel (Label — "Inventory")
```

Script: `scripts/ui/interaction_prompt_hud.gd` attached to the `CanvasLayer` root.

The scene is instanced as a child of `game_hud.tscn` (per the structure established in TICKET-0117).

---

## Existing Interactables — Add `get_interaction_prompt()`

The following objects are known interactables and must be updated to implement the prompt contract so they surface correctly in the new HUD:

| Object / Script | Prompt Key | Label | Hold |
|-----------------|-----------|-------|------|
| Resource node (unscanned) | `E` | `Scan` | `true` |
| Resource node (scanned, minable) | `E` | `Mine` | `false` |
| Ship entry area | `E` | `Enter Ship` | `false` |

Add `get_interaction_prompt()` to the relevant scripts. Do not change any existing interaction logic — only add the method.

---

## Acceptance Criteria

- [ ] `game/scenes/ui/interaction_prompt_hud.tscn` exists with the structure above
- [ ] `game/scripts/ui/interaction_prompt_hud.gd` is attached to the scene root
- [ ] `interaction_prompt_hud.tscn` is instanced as a child of `game_hud.tscn`
- [ ] Contextual prompt appears when aiming at an interactable with `get_interaction_prompt()` within range
- [ ] Contextual prompt hides when not aiming at an interactable or out of range
- [ ] Hold actions render with a visually thicker key badge border than tap actions
- [ ] Persistent controls panel is always visible in the bottom-right with Q (Ping) and I (Inventory) rows
- [ ] Resource node (unscanned), resource node (scanned/minable), and ship entry area all implement `get_interaction_prompt()` and display correctly
- [ ] Prompt appearance/disappearance is animated (fade or slide)
- [ ] Scene is independently openable in the Godot editor without errors
- [ ] All code follows `docs/engineering/coding-standards.md`

---

## Implementation Notes

- Check `player_first_person.gd` for an existing interaction raycast. If one exists, hook into it rather than creating a second one. The HUD should read state from the player or a shared signal, not run its own physics query if avoidable.
- Keep the interaction range check consistent with whatever constant the player uses for "can interact."
- The `CanvasLayer` root ensures the HUD renders above 3D geometry without needing a camera.
- Placeholder icons (white squares, built-in Godot icons) are acceptable for this ticket. A follow-up ticket can swap in final art.

---

## Handoff Notes
(Leave blank until handoff occurs.)

---

## Activity Log
- 2026-02-25 [producer] Created ticket — contextual interaction prompt + persistent controls HUD
- 2026-02-26 [producer] Scheduled into M7 — Ship Interior milestone
