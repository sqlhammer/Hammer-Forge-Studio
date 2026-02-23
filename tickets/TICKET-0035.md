---
id: TICKET-0035
title: "FIX: runtime InputMap modifications outside InputManager"
type: BUGFIX
status: OPEN
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
- [ ] `mining.gd:64-76` runtime `InputMap` modifications removed — input actions registered in `InputManager` instead
- [ ] `inventory_screen.gd:122-127` runtime `InputMap` modifications removed — input actions registered in `InputManager` instead
- [ ] No gameplay scripts modify `InputMap` at runtime
- [ ] Mining and inventory input behavior unchanged after refactor
- [ ] All code follows `docs/engineering/coding-standards.md`
- [ ] No Godot editor errors or warnings

## Implementation Notes
- Found during TICKET-0030 code review (P2)
- Blocked on TICKET-0034 — `InputManager` must support mouse button events before the workarounds in `mining.gd` can be safely removed
- Coordinate with systems-programmer on the final `InputManager` API shape before updating gameplay scripts

## Activity Log
- 2026-02-23 [systems-programmer] Created from TICKET-0030 P2 findings
