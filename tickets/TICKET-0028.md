---
id: TICKET-0028
title: "Inventory UI"
type: FEATURE
status: DONE
priority: P2
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-22
updated_at: 2026-02-22
milestone: "M3"
depends_on: [TICKET-0019, TICKET-0021]
blocks: []
tags: [inventory, ui, hud]
---

## Summary
Implement the inventory UI screen — a toggleable overlay that displays the player's 15-slot inventory grid with stack counts. This is the visual frontend for the inventory data layer built in TICKET-0021.

## Acceptance Criteria
- [ ] Inventory screen opens/closes on input toggle (Tab / Select button — add to InputManager if not mapped)
- [ ] Layout matches wireframe spec from TICKET-0019 — 15-slot grid with stack count per slot
- [ ] Each slot displays: resource icon (or placeholder), resource name, quantity / max stack
- [ ] Empty slots are visually distinct from occupied slots
- [ ] Inventory screen pauses or overlays gameplay (architect's choice — document decision)
- [ ] Inventory data binds to the inventory system via signals (TICKET-0021) — updates in real-time if open during gameplay
- [ ] Mouse cursor visible when inventory is open (if gameplay hides it)
- [ ] Follows UI style guide (TICKET-0019)
- [ ] Input routed through InputManager (no direct Input API calls)

## Implementation Notes
- M3 scope: display-only inventory. No drag-and-drop, no item use, no item discard. Just view what you have.
- Reference wireframe specs from TICKET-0019 for exact layout
- Consider implementing as a CanvasLayer scene (`game/scenes/ui/inventory_screen.tscn`)
- Input context switching: when inventory is open, gameplay inputs (move, look, mine, scan) should be suppressed
- The inventory toggle input needs to be added to the Godot input map and InputManager — coordinate with the systems programmer
- Resource icons: use placeholder colored rectangles or simple shapes for M3; real icons are a future milestone
- Reference `docs/engineering/coding-standards.md` for naming conventions

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-22 [producer] Created ticket
- 2026-02-22 [gameplay-programmer] Status → IN_PROGRESS
- 2026-02-22 [gameplay-programmer] Implementation complete. Commit f71b964. Status → DONE
