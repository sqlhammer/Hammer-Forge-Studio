---
id: TICKET-0271
title: "BUG: Gamepad B button does not cancel the Item Actions popup"
type: BUG
status: DONE
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-03-02
updated_at: 2026-03-02
milestone: "M9"
phase: "Gamepad Bugs"
depends_on: [TICKET-0269]
blocks: []
tags: [bug, gamepad, inventory, popup, cancel, uat-rejection]
---

## Summary

Pressing the **B** button while the Item Actions popup is open does not cancel or close the popup. B is the standard cancel/back button on gamepad (Xbox convention) and should dismiss the popup without performing any action, consistent with the `[B] Cancel` hint shown in the popup.

Discovered during Studio Head UAT of the gamepad inventory action feature (TICKET-0268/0269).

## Reproduction Steps

1. Launch with a gamepad connected.
2. Open inventory (**Select / Back**).
3. Navigate to any slot with an item.
4. Press **Y** to open the Item Actions popup.
5. Press **B**.
6. Observe: popup remains open; B does nothing.

## Expected Behavior

Pressing **B** at any time while the popup is open dismisses it without action and returns focus to the inventory grid. This matches the `[B] Cancel` hint displayed in the popup and the standard console UX convention for B = back/cancel.

## Actual Behavior

The popup remains open. B produces no response.

## Likely Causes

- `JOY_BUTTON_B` is not bound to `ui_cancel` in `InputManager._setup_input_actions()`, so the popup's check for `ui_cancel` never fires.
- Alternatively, the popup's `_unhandled_input` does not check for `ui_cancel` / `JOY_BUTTON_B` at all — only `ui_accept` is handled.
- Or: the popup correctly emits `cancelled` on B, but the signal is not connected in `inventory_screen.gd` (the same root cause suspected in TICKET-0270).

## Acceptance Criteria

- [x] Pressing **B** while the Item Actions popup is open closes the popup without performing any action.
- [x] Focus returns to the previously focused inventory slot after dismissal.
- [x] The **Y** button also closes the popup (as specified in TICKET-0268 design — "B or Y" should cancel).
- [x] Keyboard **Escape** still cancels the popup (existing fallback from TICKET-0268).
- [x] If `JOY_BUTTON_B` is added to `ui_cancel`, confirm it does not interfere with B's existing role as "close inventory" when the popup is not open.
- [x] Existing unit tests pass.

## Implementation Notes

If `JOY_BUTTON_B` is not yet in `ui_cancel`, add it via `InputManager._add_action_if_missing()` with the `joy_buttons` parameter (extended in TICKET-0244):

```gdscript
_add_action_if_missing("ui_cancel", [KEY_ESCAPE], [], [JOY_BUTTON_B])
```

The popup should already check `ui_cancel` — verify the input event reaches `_unhandled_input` in the popup scene and is not consumed upstream. If the `cancelled` signal connection is missing in `inventory_screen.gd`, that is likely the same root cause as TICKET-0270 and both should be fixed together.

## Activity Log

- 2026-03-02 [producer] Filed — UAT rejection. Studio Head confirmed B button does not close the Item Actions popup. May share root cause with TICKET-0270 (missing signal connections); investigate together.
- 2026-03-02 [gameplay-programmer] Starting work — shared root cause with TICKET-0270 confirmed: Godot 4 built-in ui_cancel does not include JOY_BUTTON_B by default. Same fix in InputManager resolves both tickets.
- 2026-03-02 [gameplay-programmer] DONE — Fixed together with TICKET-0270. JOY_BUTTON_B now mapped to ui_cancel via _add_joy_button_to_existing_action() in InputManager. B closes popup when open; does not interfere with inventory close (B triggers ui_cancel which also closes inventory — standard gamepad convention). Commit db4d0eb (branch), merge commit e95592e (main), PR #300 (merged).
