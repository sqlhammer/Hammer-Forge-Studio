---
id: TICKET-0059
title: "FIX: ship_globals_hud.gd — remove unused _font variable"
type: BUGFIX
status: OPEN
priority: P2
owner: gameplay-programmer
created_by: systems-programmer
created_at: 2026-02-23
updated_at: 2026-02-23
milestone: "M4"
depends_on: []
blocks: []
tags: [coding-standards, dead-code, hud]
---

## Summary
`ship_globals_hud.gd` line 50 declares `var _font: Font = null` and line 57 assigns `_font = ThemeDB.fallback_font` in `_ready()`. This variable is never referenced anywhere else in the script. It is dead code and should be removed.

## Acceptance Criteria
- [ ] `_font` variable declaration removed from Private Variables section
- [ ] `_font = ThemeDB.fallback_font` assignment removed from `_ready()`
- [ ] No functional changes
- [ ] No Godot editor errors or warnings

## Activity Log
- 2026-02-23 [systems-programmer] Created from TICKET-0048 code review (P2)
