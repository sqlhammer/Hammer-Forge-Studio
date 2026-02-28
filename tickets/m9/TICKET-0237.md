---
id: TICKET-0237
title: "Root Game: Design — Main Menu wireframe and layout spec"
type: DESIGN
status: OPEN
priority: P1
owner: ui-ux-designer
created_by: producer
created_at: 2026-02-28
updated_at: 2026-02-28
milestone: "M9"
phase: "Root Game"
depends_on: []
blocks: [TICKET-0231]
tags: [root-game, main-menu, design, wireframe]
---

## Summary

Design the Main Menu screen for the Root Game phase. This is a minimal first-pass: a single "Play" button that starts the game. The design should establish visual language for future menu additions (settings, credits, etc.) without over-engineering for them now.

## Deliverables

- [ ] Wireframe or annotated mockup of the Main Menu layout (ASCII, Figma export, or equivalent) committed to `docs/design/ui/main_menu_wireframe.md` (or `.png` if a raster mockup is preferred).
- [ ] Layout spec: background treatment, button size/position, font sizes, colors (aligned with the game's existing palette — dark background `#1a1a2e`, slate text `#F1F5F9`, consistent with DebugLauncher's style).
- [ ] Button state spec: default, hover, pressed states for the Play button.
- [ ] Any notes on future extensibility (e.g., where a title logo or settings button would slot in) — brief, no implementation work required.

## Acceptance Criteria

- [ ] Deliverable committed to `docs/design/ui/`.
- [ ] Layout is implementable with Godot's built-in `Control` nodes (no custom shaders or assets required for this phase).
- [ ] Design reviewed and approved (self-approve is acceptable for this phase — no separate review ticket needed).
- [ ] TICKET-0231 implementer has enough information to build the scene without further design questions.

## Implementation Notes

- The Main Menu must display correctly at 1920×1080 (reference resolution). Anchoring should degrade gracefully at other aspect ratios.
- Keep it simple — one centered Play button is the only required interactive element for M9.
- Match the visual tone of the existing DebugLauncher (dark, functional, minimal) rather than introducing a new style direction. A full art pass is out of scope for this phase.

## Activity Log

- 2026-02-28 [producer] Created ticket — Main Menu design gate before TICKET-0231 implementation
