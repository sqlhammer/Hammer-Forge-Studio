---
id: TICKET-0109
title: "Bugfix — Player camera moves when mousing over recycler panel"
type: BUGFIX
status: TODO
priority: P2
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-25
updated_at: 2026-02-25
milestone: "M5"
phase: "QA"
depends_on: []
blocks: []
tags: [bugfix, recycler, ui, camera, input]
---

## Summary
When the recycler panel is open and the player moves the mouse, the first-person camera rotates as if the player is looking around. Mouse input is not being captured/consumed by the UI, so it falls through to the camera controller.

## Reproduction
1. Interact with the recycler to open the recycler panel
2. Move the mouse around within the panel
3. Observe — the player's camera rotates behind the UI

## Expected Behavior
While any UI panel is open, mouse movement must be captured by the UI layer and must **not** rotate the player camera. The cursor should be visible and freely movable within the panel.

## Root Cause (Suspected)
The recycler panel likely does not set `Input.mouse_mode = Input.MOUSE_MODE_VISIBLE` or equivalent when opened, allowing the camera controller to continue consuming mouse delta. Alternatively, the panel is not correctly intercepting mouse events.

## Fix
- When the recycler panel opens, set `Input.mouse_mode = Input.MOUSE_MODE_VISIBLE` and ensure the camera controller ignores mouse input while a UI panel is active (check `InputManager` or the camera script for an existing "ui open" guard)
- When the recycler panel closes, restore `Input.MOUSE_MODE_CAPTURED` so camera control resumes
- Verify that the same pattern is applied consistently for all other panels (module install, automation hub, etc.) — if they have this bug too, fix them in this ticket or file follow-ups

## Acceptance Criteria
- [ ] Opening the recycler panel stops camera rotation; cursor is visible and free
- [ ] Closing the recycler panel restores camera mouse-look
- [ ] No mouse input leaks to the camera while any panel is open

## Activity Log
- 2026-02-25 [producer] Created from UAT feedback. Mouse not locked when recycler panel is open, causing camera to move.
