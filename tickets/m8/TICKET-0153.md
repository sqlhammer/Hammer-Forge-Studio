---
id: TICKET-0153
title: "Mouse interaction support for inventory, machine builder, and tech tree menus"
type: FEATURE
status: PENDING
priority: P2
owner: gameplay-programmer
created_by: studio-head
created_at: 2026-02-26
updated_at: 2026-02-26
milestone: "M8"
phase: "Gameplay"
depends_on: []
blocks: []
tags: [ui, hud, inventory, machine-builder, tech-tree, mouse, input, m8]
---

## Summary

All in-game menus currently require controller/keyboard-only navigation. Mouse interaction should be supported across the three primary menu surfaces:

1. **Inventory** — click to select/highlight items, drag or click-to-move between slots
2. **Machine builder** — click to select a machine type from the build list
3. **Tech tree** — click to select and queue a research item

This is a usability baseline: mouse support is expected in any desktop game. No UI paradigm changes are needed — just ensure Control nodes have mouse filtering enabled and respond to `_gui_input` / `pressed` signals where appropriate.

## Acceptance Criteria

- [ ] **Inventory**: individual item slots respond to `mouse_entered`, `mouse_exited` (hover highlight), and `gui_input` left-click (select/move item). Behavior matches existing keyboard-select behavior.
- [ ] **Machine builder**: each buildable entry in the list responds to left-click as equivalent to navigating to it and pressing confirm. Hover state is visually indicated.
- [ ] **Tech tree**: each research node responds to left-click to select it for queuing. Hover state is visually indicated.
- [ ] Mouse and keyboard/controller input are **not mutually exclusive** — switching between input modes mid-session works without state corruption.
- [ ] `InputManager` mouse detection (if applicable) is leveraged to drive any input-mode switching.
- [ ] No existing keyboard/controller navigation paths are broken.
- [ ] Unit tests cover: click-select on inventory slot, click-select on machine entry, click-select on tech tree node, and no-op on disabled/empty slots.
- [ ] Full test suite passes after implementation.

## Implementation Notes

- In Godot 4, `Control.mouse_filter` must be set to `MOUSE_FILTER_STOP` (not `IGNORE`) on interactive nodes — verify this is set correctly on all three menu surfaces.
- Prefer connecting to existing selection logic rather than duplicating it — mouse click should call the same selection handler that keyboard navigation already uses.
- If menus use a focus-based system (e.g., `grab_focus()` on keyboard nav), ensure mouse click also calls `grab_focus()` on the clicked element so the selection state stays consistent.
- Drag-and-drop in inventory is a stretch goal; click-to-select is the minimum acceptance bar.

## Activity Log

- 2026-02-26 [studio-head] Created — mouse interaction is a baseline usability requirement for desktop
