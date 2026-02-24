---
id: TICKET-0058
title: "FIX: missing debug logging in ShipGlobalsHUD and ShipStatsSidebar"
type: BUGFIX
status: DONE
priority: P2
owner: gameplay-programmer
created_by: systems-programmer
created_at: 2026-02-23
updated_at: 2026-02-23
milestone: "M4"
depends_on: []
blocks: []
tags: [coding-standards, logging, hud, inventory]
---

## Summary
`ShipGlobalsHUD` and `ShipStatsSidebar` contain zero `Global.log()` calls. The coding standard requires debug logging for all meaningful events and state transitions.

### Missing Logging Points

**ShipGlobalsHUD (`ship_globals_hud.gd`):**
- `set_ship_visible()` — show/hide transitions
- Critical state entry/exit for any variable (e.g., power dropping below critical threshold)

**ShipStatsSidebar (`ship_stats_sidebar.gd`):**
- Alert generation (when alerts appear/disappear)
- Signal handler updates (optional, but useful for debugging value propagation)

## Acceptance Criteria
- [ ] `Global.log()` calls added to `ShipGlobalsHUD.set_ship_visible()` for show/hide
- [ ] `Global.log()` calls added for critical state transitions in ShipGlobalsHUD
- [ ] `Global.log()` calls added to `ShipStatsSidebar._update_alerts()` when alerts change
- [ ] Log messages are descriptive and include relevant values
- [ ] No bare `print()` statements
- [ ] All code follows `docs/engineering/coding-standards.md`

## Activity Log
- 2026-02-23 [systems-programmer] Created from TICKET-0048 code review (P2)
- 2026-02-23 [gameplay-programmer] Added Global.log() to HUD set_ship_visible show/hide, HUD signal handlers for critical state transitions, sidebar _update_alerts with change detection. DONE
- 2026-02-25 [producer] Archived
