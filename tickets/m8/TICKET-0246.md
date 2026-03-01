---
id: TICKET-0246
title: "BUG — Navigation console panel too tall; CONFIRM TRAVEL button cut off below viewport"
type: BUG
status: OPEN
priority: P2
owner: gameplay-programmer
created_by: producer
created_at: 2026-03-01
updated_at: 2026-03-01
milestone: "M8"
phase: "Bug Fix"
depends_on: []
blocks: []
tags: [navigation-console, ui, layout, bug]
---

## Summary

The navigation console modal panel is taller than the visible viewport. The CONFIRM TRAVEL button (and the bottom of the SHIP FUEL / DESTINATION sections) is clipped or pushed below the bottom edge of the screen. The player cannot interact with the full console UI.

## Root Cause

In `game/scripts/ui/navigation_console.gd`, the panel is built with:

```gdscript
const PANEL_HEIGHT: float = 600.0
_main_panel.custom_minimum_size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)
```

`custom_minimum_size` sets a floor — it does not cap the panel height. The `VBoxContainer` and its children expand beyond `PANEL_HEIGHT` when content (SHIP FUEL section, DESTINATION section, labels, buttons) requires more vertical space than 600 px.

The right-side detail column contains: fuel header, tank level label, inventory count label, load fuel button, fuel status label, separator, destination header, prompt label, name label, tier label, distance header + value, fuel cost header + value, ship tank header + value + warning label, and finally CONFIRM TRAVEL button. At current font sizes and margins this exceeds 600 px total.

## Acceptance Criteria

- [ ] The entire navigation console panel, including the CONFIRM TRAVEL button and all content below, is visible on screen at 1920×1080 (reference resolution).
- [ ] The panel does not overflow or clip at any content state (e.g., with or without a destination selected, with or without a fuel warning).
- [ ] If the panel must scroll, it scrolls only the content area — the title bar and close button remain fixed.
- [ ] No interactive element is inaccessible due to clipping.
- [ ] Existing unit tests pass.

## Implementation Notes

**File:** `game/scripts/ui/navigation_console.gd`

### Preferred fix: cap panel height and make detail column scrollable

The detail column on the right is the overflow source. Wrap it in a `ScrollContainer` with a fixed max height:

```gdscript
func _build_detail_column() -> ScrollContainer:
    var scroll := ScrollContainer.new()
    scroll.custom_minimum_size = Vector2(DETAIL_WIDTH, 0)
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

    var col := VBoxContainer.new()
    col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(col)
    # ... build detail content into col as before
    return scroll
```

This allows the right column to scroll independently if content is taller than the panel, while the biome map on the left remains static.

### Alternative: tighten spacing and increase PANEL_HEIGHT

If the scroll approach introduces UX friction, reduce internal margins and increase the constant:

```gdscript
const PANEL_HEIGHT: float = 700.0
```

And reduce font sizes or vertical padding in the detail column. This is a quick fix but may re-break at smaller resolutions.

### Also ensure the panel does not exceed viewport height

Regardless of which fix is chosen, add a viewport-height clamp after the panel is built:

```gdscript
func _clamp_panel_to_viewport() -> void:
    var max_height: float = get_viewport().get_visible_rect().size.y * 0.92
    _main_panel.custom_minimum_size.y = min(PANEL_HEIGHT, max_height)
```

Call this in `open_panel()` before making the panel visible.

## Activity Log

- 2026-03-01 [producer] Created ticket — player-reported: CONFIRM TRAVEL button cut off; cannot interact with lower half of navigation console
