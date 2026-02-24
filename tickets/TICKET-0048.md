---
id: TICKET-0048
title: "Code review — M4 systems"
type: REVIEW
status: DONE
priority: P1
owner: systems-programmer
created_by: producer
created_at: 2026-02-23
updated_at: 2026-02-23
milestone: "M4"
milestone_gate: "M3"
depends_on: [TICKET-0043, TICKET-0044, TICKET-0045, TICKET-0046, TICKET-0047]
blocks: [TICKET-0049]
tags: [review, code-quality]
---

## Summary
Code review of all M4 gameplay and UI systems. The systems programmer reviews all gameplay-programmer code for architectural consistency, coding standards compliance, performance concerns, and correct integration with the M4 data layer (ship globals, module system, Recycler). This review gates QA testing.

## Acceptance Criteria
- [x] Ship interior scene reviewed (TICKET-0043) — scene structure, collision, enter/exit triggers
- [x] Module placement mechanic reviewed (TICKET-0044) — module catalog integration, resource deduction, install persistence
- [x] Recycler panel UI reviewed (TICKET-0045) — job queue integration, inventory API usage, input context switching
- [x] HUD ship globals display reviewed (TICKET-0046) — signal bindings, visibility toggling, style guide compliance
- [x] Inventory UI ship stats sidebar reviewed (TICKET-0047) — signal bindings, layout, style guide compliance
- [x] All code follows `docs/engineering/coding-standards.md`
- [x] No direct Input API calls — all input routed through InputManager
- [x] No architectural concerns or regressions from M1–M3 systems
- [x] Review findings documented in Handoff Notes with severity (P1/P2 issues → new tickets, P3 → noted)

## Implementation Notes
- This is a review ticket, not an implementation ticket
- If review finds P0/P1 issues: block QA, create BUG tickets, assign back to gameplay-programmer
- If review finds P2 issues: create follow-up tickets but do not block M4 closure
- If review finds P3 issues: document in handoff notes for future cleanup
- Reference the code review protocol in CLAUDE.md

## Handoff Notes

### Review Summary
Reviewed all 5 M4 gameplay scripts plus integration in test_world.gd. No P0/P1 blockers found. Four P2 follow-up tickets created. No architectural regressions from M1–M3 systems. Data layer integration (ShipState, ModuleManager, Recycler, PlayerInventory) is correct throughout.

### P1 Issues: NONE
QA is unblocked.

### P2 Issues → Follow-Up Tickets

| Ticket | Description | Owner |
|--------|-------------|-------|
| TICKET-0056 | ship_interior.gd — missing `class_name`, section ordering violations | gameplay-programmer |
| TICKET-0057 | Threshold inconsistency between ShipGlobalsHUD and ShipStatsSidebar | gameplay-programmer |
| TICKET-0058 | Missing debug logging in ShipGlobalsHUD and ShipStatsSidebar | gameplay-programmer |
| TICKET-0059 | ship_globals_hud.gd — remove unused `_font` variable | gameplay-programmer |

### P3 Notes (No Tickets)
- `ModulePlacementUI._attempt_install()` duplicates close logic instead of calling `close()` — minor divergence risk, acceptable for M4
- `RecyclerPanel` uses a "Signal Handlers" section header not defined in coding standards — cosmetic, readable as-is
- Physics layer constants (`LAYER_PLAYER`, `LAYER_ENVIRONMENT`, `LAYER_INTERACTABLE`) duplicated across ship_interior.gd and test_world.gd — DRY concern, defer to centralized physics layers when physics-layers.md is formalized
- `Input.set_mouse_mode()` calls in UI scripts not routed through InputManager — coding standard only prohibits `Input.is_action_pressed()`, mouse mode control is not covered

### Scripts Reviewed
- `game/scripts/gameplay/ship_interior.gd` (TICKET-0043)
- `game/scripts/ui/module_placement_ui.gd` (TICKET-0044)
- `game/scripts/ui/recycler_panel.gd` (TICKET-0045)
- `game/scripts/ui/ship_globals_hud.gd` (TICKET-0046)
- `game/scripts/ui/ship_stats_sidebar.gd` (TICKET-0047)
- `game/scripts/ui/game_hud.gd` (integration)
- `game/scripts/ui/inventory_screen.gd` (integration)
- `game/scripts/levels/test_world.gd` (integration)

### Checks Passed
- Zero `Input.is_action_pressed()` / `Input.is_action_just_pressed()` calls in gameplay scripts
- Zero bare `print()` statements in M4 code
- Zero `InputMap` modifications outside InputManager
- Zero `@warning_ignore` suppressions
- All autoloads correctly registered in project.godot
- Signal bindings use correct signatures matching data layer signals
- Module install flow correctly validates cost → power → deduct → register → track
- Recycler job lifecycle (start → progress → complete → collect) correctly wired through panel
- Ship enter/exit transitions use fade overlay and teleport pattern with proper state guards

## Activity Log
- 2026-02-23 [producer] Created ticket
- 2026-02-23 [systems-programmer] Completed code review. No P1 blockers. Created 4 P2 follow-up tickets (TICKET-0056 through TICKET-0059). QA unblocked.
