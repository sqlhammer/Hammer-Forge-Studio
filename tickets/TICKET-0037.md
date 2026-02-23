---
id: TICKET-0037
title: "FIX: script section ordering violations across M3 gameplay scripts"
type: BUGFIX
status: DONE
priority: P2
owner: gameplay-programmer
created_by: systems-programmer
created_at: 2026-02-23
updated_at: 2026-02-23
milestone: "M3"
depends_on: []
blocks: []
tags: [coding-standards, formatting, gameplay]
---

## Summary
Multiple M3 gameplay scripts place Public Methods before Built-in Virtual Methods, violating the required script section order defined in `docs/engineering/coding-standards.md`. The correct order requires virtual methods (`_ready`, `_process`, etc.) before public methods.

## Affected Scripts
- `scanner.gd`
- `mining.gd`
- `compass_bar.gd`
- `game_hud.gd`
- `inventory_screen.gd`
- `mining_progress.gd`
- `scanner_readout.gd`

## Acceptance Criteria
- [ ] All affected scripts reordered to match the required section order:
  1. Docstring comment + `class_name` + `extends`
  2. Signals
  3. Constants
  4. Exported variables
  5. Private variables
  6. Onready variables
  7. Built-in virtual methods (`_ready`, `_process`, etc.)
  8. Public methods
  9. Private methods
- [ ] No functional changes — reorder only
- [ ] All code follows `docs/engineering/coding-standards.md`
- [ ] No Godot editor errors or warnings after reorder

## Implementation Notes
- Found during TICKET-0030 code review (P2)
- Pure structural change — no logic should be altered
- Reference the Script Structure Order section in `docs/engineering/coding-standards.md`

## Activity Log
- 2026-02-23 [systems-programmer] Created from TICKET-0030 P2 findings
- 2026-02-23 [gameplay-programmer] Reordered all 7 affected scripts to place Built-in Virtual Methods before Public Methods per coding standards
