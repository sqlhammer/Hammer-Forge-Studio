---
id: TICKET-0036
title: "FIX: missing debug logging across all M3 gameplay scripts"
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
tags: [coding-standards, logging, gameplay]
---

## Summary
Zero `Global.log()` calls exist across all M3 gameplay code. The coding standard requires debug logging for all meaningful events and state transitions. All M3 gameplay scripts need a debug logging pass.

## Affected Scripts
- `scanner.gd`
- `mining.gd`
- `compass_bar.gd`
- `game_hud.gd`
- `inventory_screen.gd`
- `mining_progress.gd`
- `scanner_readout.gd`

## Acceptance Criteria
- [ ] `Global.log()` calls added for all meaningful events in each affected script (e.g., scan triggered, deposit found, mining started/completed, battery drained, item collected, inventory full)
- [ ] Log messages are descriptive and include relevant state values where useful
- [ ] No bare `print()` statements — all output goes through `Global.log()`
- [ ] Logging does not fire in production builds (`Global.log()` already gates on `OS.is_debug_build()`)
- [ ] All code follows `docs/engineering/coding-standards.md`

## Implementation Notes
- Found during TICKET-0030 code review (P2)
- Reference `docs/engineering/coding-standards.md` — Debugging section for the logging standard
- Focus on state transitions and meaningful gameplay events, not per-frame noise

## Activity Log
- 2026-02-23 [systems-programmer] Created from TICKET-0030 P2 findings
- 2026-02-23 [gameplay-programmer] Added Global.log() calls to all 8 M3 gameplay scripts: scanner.gd, mining.gd, compass_bar.gd, game_hud.gd, inventory_screen.gd, mining_progress.gd, scanner_readout.gd, test_world.gd — commit 08e8909, PR #15
