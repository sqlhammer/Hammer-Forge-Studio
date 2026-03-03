---
id: TICKET-0308
title: "BUG — InventoryActionPopup visible by default and not found as child after TICKET-0293"
type: BUG
status: DONE
priority: P2
owner: gameplay-programmer
created_by: qa-engineer
created_at: 2026-03-03
updated_at: 2026-03-03
milestone: "M11"
phase: "QA"
depends_on: []
blocks: [TICKET-0304]
tags: [inventory, popup, scene-first, regression, m11]
---

## Summary

After TICKET-0293 (M11 Scene-First remediation — Inventory Screen and Inventory Action Popup),
the `InventoryActionPopup` is not correctly integrated with `InventoryScreen`. Two symptoms:
1. The popup is visible by default (should be hidden)
2. `InventoryScreen` cannot open the popup via Y/gamepad press or code-driven calls

13 of 23 tests across `test_inventory_action_popup_unit` and `test_inventory_screen_popup_unit`
fail, covering: default visibility, popup open/close, signal routing, controls descriptor text,
and inventory close cascading to popup close.

---

## Severity

**P2 — Defect in expected behavior, workaround exists**: Inventory popup cannot be opened
via Y press (primary action), controls descriptor is empty, and drop/destroy signals don't
route. Player can still access inventory but cannot use context actions on items.

---

## Regression Source

**TICKET-0293** moved `InventoryActionPopup` from being created in `InventoryScreen._build_ui()`
to being a standalone scene with its own `.tscn`. Post-refactor, either:
- The popup's default visibility is `true` in the scene file (should be `false`/hidden)
- `InventoryScreen` no longer has a reference path to the popup, so action calls fail
- The popup scene is not correctly re-integrated as a child of `InventoryScreen`

---

## Reproduction Steps

1. Launch the game and open inventory (Tab/Start)
2. Focus an occupied inventory slot
3. Press Y (gamepad) or configured action button
4. Observe: no popup appears; "Actions" UI is absent

Also:
- On inventory open, observe InventoryActionPopup may be visible before any action is taken

Run `test_inventory_action_popup_unit` and `test_inventory_screen_popup_unit` to see all 13
test failures.

---

## Expected Behavior

- `InventoryActionPopup` is hidden by default (`visible = false`)
- Y press on a non-empty focused slot opens the action popup
- Drop/Destroy actions route correctly from popup signals
- Controls descriptor shows the appropriate key labels
- Closing inventory closes the popup

## Actual Behavior

- `InventoryActionPopup` is visible by default
- Y press does not open the popup
- Controls descriptor is empty
- Popup state management is broken

---

## Evidence

Test output from M11 Phase Gate QA run (2026-03-03):
```
[52904]   FAIL: hidden_by_default -- Popup should be hidden by default: Expected false but got true
[57228]   FAIL: y_press_opens_popup_for_focused_slot -- Action popup should be open after Y press on non-empty slot: Expected true but got false
[57230]   FAIL: drop_signal_routes_to_drop_logic -- Popup should be open: Expected true but got false
[57232]   FAIL: destroy_signal_routes_to_destroy_logic -- Popup should be open: Expected true but got false
[57234]   FAIL: grid_navigation_blocked_while_popup_open -- Grid navigation should be blocked while popup is open: Expected '0' but got '1'
[57235]   FAIL: grid_navigation_resumes_after_popup_close -- Popup should be open: Expected true but got false
[57238]   FAIL: controls_descriptor_keyboard_text -- Expected '[G] Drop  |  [Enter/A] Destroy  |  [Right-Click] Drop' but got ''
[57240]   FAIL: controls_descriptor_gamepad_text -- Expected '[Y] Actions' but got ''
[57243]   FAIL: controls_descriptor_hidden_for_empty_slot -- Slot should be empty after removing items: Expected true but got false
[57245]   FAIL: controls_descriptor_popup_hint_text -- Expected '[A] Confirm / Hold to Destroy   [B] Cancel   D-pad ↑↓ Navigate' but got ''
[57247]   FAIL: popup_is_created_as_child -- InventoryActionPopup should be created as part of _build_ui: Expected non-null value but got null
[57249]   FAIL: is_action_popup_open_reflects_state -- is_action_popup_open should return true when popup is open: Expected true but got false
[57250]   FAIL: close_inventory_closes_popup -- Popup should be open before closing inventory: Expected true but got false
```

---

## Files Involved

- `game/scripts/ui/inventory_screen.gd` — popup wiring and open/close logic
- `game/scripts/ui/inventory_action_popup.gd` — default visibility
- `game/scenes/ui/inventory_screen.tscn` — popup scene integration
- `game/scenes/ui/inventory_action_popup.tscn` — check visible property

---

## Activity Log

- 2026-03-03 [qa-engineer] Filed — P2 regression from TICKET-0293; inventory action popup broken (13 test failures). Blocks TICKET-0304 Phase Gate QA sign-off.
- 2026-03-03 [gameplay-programmer] Starting work — fixing popup default visibility, ensuring programmatic popup creation for test compatibility, guarding null signal connections, closing popup from cancelled handler.
- 2026-03-03 [gameplay-programmer] DONE — commit 4f5faf6, PR https://github.com/sqlhammer/Hammer-Forge-Studio/pull/347 merged.
