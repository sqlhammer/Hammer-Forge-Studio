---
id: TICKET-0353
title: "BUG — InventoryScreen._connect_signals crashes on null slot panels when instantiated without .tscn"
type: BUG
status: OPEN
priority: P2
owner: gameplay-programmer
created_by: play-tester
created_at: 2026-03-07
updated_at: 2026-03-07
milestone: "M11"
phase: "QA"
depends_on: []
blocks: [TICKET-0336]
tags: [inventory, test-compat, regression, m11]
---

## Summary

`InventoryScreen._connect_signals()` crashes with "Invalid access to property or key
'mouse_entered' on a base object of type 'null instance'" when the screen is instantiated
programmatically (without `.tscn`) in the test suite. This causes `test_inventory_screen_popup_unit`
to crash the test runner and was exposed by the TICKET-0308 fix.

---

## Severity

**P2 — Defect in expected behavior, workaround exists**: All `test_inventory_screen_popup_unit`
tests cannot run. The test runner freezes/crashes on the first `before_each` call. This
blocks TICKET-0336 VERIFY from achieving zero test failures.

---

## Regression Source

**TICKET-0308** fixed popup visibility and `%InventoryActionPopup` wiring. The fix added
null guards for `_action_popup`, `_destroy_confirm_button`, and `_cancel_confirm_button`
signal connections. However, the `_slot_panels` iteration in `_connect_signals()` at line
335 was not guarded:

```gdscript
for i: int in range(_slot_panels.size()):
    _slot_panels[i].mouse_entered.connect(_on_slot_mouse_entered.bind(i))
    _slot_panels[i].gui_input.connect(_on_slot_gui_input.bind(i))
```

When `InventoryScreen` is instantiated without the `.tscn`, `_populate_slot_arrays()` runs
a loop appending `null` values to `_slot_panels` (because `get_node("%" + slot_name)` returns
null). `_connect_signals()` then crashes on `_slot_panels[0].mouse_entered` because the entry
is null.

---

## Reproduction Steps

1. Launch test runner: `res://addons/hammer_forge_tests/test_runner.tscn`
2. Observe tests completing up through `test_inventory_action_popup_unit` (23/23 passed)
3. When `test_inventory_screen_popup_unit` begins, `before_each` instantiates
   `InventoryScreen.new()` and calls `add_child(_screen)`
4. `_ready()` → `_build_ui()` → `_populate_slot_arrays()` fills `_slot_panels` with 15 null
   entries (slots not found)
5. `_connect_signals()` → line 335 → crash: "Invalid access to property 'mouse_entered' on
   null instance"
6. Godot debugger pauses execution — test runner freezes

---

## Expected Behavior

`_connect_signals()` skips null entries in `_slot_panels`, allowing tests to run:

```gdscript
for i: int in range(_slot_panels.size()):
    if _slot_panels[i]:
        _slot_panels[i].mouse_entered.connect(_on_slot_mouse_entered.bind(i))
        _slot_panels[i].gui_input.connect(_on_slot_gui_input.bind(i))
```

## Actual Behavior

- `_slot_panels[i]` is null (i=0) → crash at line 335
- Godot debugger pauses the game at the crash
- Test runner hangs — no test results produced for `test_inventory_screen_popup_unit`

---

## Files Involved

- `game/scripts/ui/inventory_screen.gd` — line 334–336: `_connect_signals()` null guard missing

---

## Evidence

Editor screenshot showing Godot debugger paused at `inventory_screen.gd:335` with error:
"Invalid access to property or key 'mouse_entered' on a base object of type 'null instance'."
Locals: `i = 0`, `@range_to = 15`. Stack trace confirms crash in `before_each` of
`test_inventory_screen_popup_unit`.

Confirmed test results before crash:
- `test_inventory_action_popup_unit`: 23/23 PASSED
- `test_inventory_screen_popup_unit`: CRASHED (0 tests ran)

---

## Activity Log

- 2026-03-07 [play-tester] Filed — P2 crash in test_inventory_screen_popup_unit exposed by TICKET-0308 fix. Blocks TICKET-0336 VERIFY.
