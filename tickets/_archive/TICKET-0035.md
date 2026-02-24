---
id: TICKET-0035
title: "FIX: runtime InputMap modifications outside InputManager"
type: BUGFIX
status: DONE
priority: P2
owner: gameplay-programmer
created_by: systems-programmer
created_at: 2026-02-23
updated_at: 2026-02-23
milestone: "M3"
depends_on: [TICKET-0034]
blocks: []
tags: [input, coding-standards, mining, inventory]
---

## Summary
`mining.gd:64-76` and `inventory_screen.gd:122-127` add input actions to the `InputMap` at runtime. All `InputMap` modifications must be centralized in `InputManager`. These workarounds were necessary because `InputManager` did not support mouse button events (fixed in TICKET-0034). Once TICKET-0034 lands, these runtime modifications can be removed.

## Acceptance Criteria
- [x] `mining.gd:64-76` runtime `InputMap` modifications removed — input actions registered in `InputManager` instead
- [x] `inventory_screen.gd:122-127` runtime `InputMap` modifications removed — input actions registered in `InputManager` instead
- [x] No gameplay scripts modify `InputMap` at runtime
- [x] Mining and inventory input behavior unchanged after refactor
- [x] All code follows `docs/engineering/coding-standards.md`
- [x] No Godot editor errors or warnings

## Implementation Notes
- Found during TICKET-0030 code review (P2)
- Blocked on TICKET-0034 — `InputManager` must support mouse button events before the workarounds in `mining.gd` can be safely removed
- Coordinate with systems-programmer on the final `InputManager` API shape before updating gameplay scripts

## Activity Log
- 2026-02-23 [systems-programmer] Created from TICKET-0030 P2 findings
- 2026-02-23 [systems-programmer] Fixed: removed `_ensure_use_tool_input()` from mining.gd (use_tool already registered in InputManager with MOUSE_BUTTON_LEFT via TICKET-0034), removed `_ensure_inventory_toggle_input()` from inventory_screen.gd and added `inventory_toggle` KEY_I registration to InputManager._setup_input_actions(). Verified zero InputMap references remain in game/scripts/.
- 2026-02-23 [systems-programmer] DONE — commit ba5e896, PR #17 merged to main
- 2026-02-25 [producer] Archived
