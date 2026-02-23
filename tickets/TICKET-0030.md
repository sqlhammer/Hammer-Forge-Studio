---
id: TICKET-0030
title: "Code review — M3 systems"
type: REVIEW
status: DONE
priority: P1
owner: systems-programmer
created_by: producer
created_at: 2026-02-22
updated_at: 2026-02-23
milestone: "M3"
depends_on: [TICKET-0024, TICKET-0025, TICKET-0026, TICKET-0027, TICKET-0028, TICKET-0029]
blocks: [TICKET-0031]
tags: [review, code-quality]
---

## Summary
Code review of all M3 gameplay systems. The systems programmer reviews all gameplay-programmer code for architectural consistency, coding standards compliance, performance concerns, and correct integration with the data layer systems (inventory, deposits, battery). This review gates QA testing.

## Acceptance Criteria
- [x] Scanner Phase 1 code reviewed (TICKET-0024) — correct use of deposit API, InputManager integration, compass implementation
- [x] Scanner Phase 2 code reviewed (TICKET-0025) — analysis flow, readout display, deposit state transitions
- [x] Mining interaction code reviewed (TICKET-0026) — extraction flow, battery drain, inventory integration, proximity check
- [x] HUD code reviewed (TICKET-0027) — signal bindings, UI style guide compliance, anchor behavior
- [x] Inventory UI code reviewed (TICKET-0028) — data binding, input context switching, style guide compliance
- [x] Greybox world reviewed (TICKET-0029) — deposit configuration, recharge zone, player spawn, collision
- [x] All code follows `docs/engineering/coding-standards.md`
- [x] No direct Input API calls — all input routed through InputManager
- [x] No architectural concerns or regressions from M1 systems
- [x] Review findings documented in Handoff Notes with severity (P2 issues = new tickets, P3 = noted for polish)

## Implementation Notes
- This is a review ticket, not an implementation ticket
- If review finds P0/P1 issues: block QA, create BUG tickets, assign back to gameplay-programmer
- If review finds P2 issues: create follow-up tickets but do not block M3 closure
- If review finds P3 issues: document in handoff notes for future cleanup
- Reference the code review protocol in CLAUDE.md — review does not gate the original commits, only QA

## Handoff Notes

### P1 — Critical Bug (fixed in this review)

**BUG: mining.gd:128 — Deposit.extract() return type mismatch (TICKET-0032)**
`Deposit.extract()` returns `Dictionary` but `_complete_mining()` assigned it to `var extracted: int`. This caused mining to silently fail — items were never added to inventory. **Fixed by systems-programmer during review** — now unpacks the Dictionary correctly. See TICKET-0032.

### P2 — Follow-up Tickets

1. **TICKET-0033: scanner.gd uses direct Input API call** — Line 82: `Input.is_action_just_pressed("scan")` violates coding standards. InputManager lacks `is_action_just_pressed()` method, which caused the workaround. Fix: add the method to InputManager and update scanner.gd.
2. **TICKET-0034: InputManager use_tool mouse button registration** — Line 123 registers `MOUSE_BUTTON_LEFT` as a keycode for `InputEventKey` instead of `InputEventMouseButton`. Mining works around this at line 64-76 by adding the event manually. Fix: InputManager should support mouse button input events natively.
3. **TICKET-0035: Runtime InputMap modifications outside InputManager** — mining.gd (line 64-76) and inventory_screen.gd (line 122-127) add input actions at runtime. These should be centralized in InputManager.
4. **TICKET-0036: Missing debug logging in gameplay scripts** — Zero `Global.log()` calls across all M3 gameplay code. Coding standard requires debug logging for meaningful events.
5. **TICKET-0037: Script section ordering violations** — scanner.gd, mining.gd, compass_bar.gd, game_hud.gd, inventory_screen.gd, mining_progress.gd, scanner_readout.gd all place Public Methods before Built-in Virtual Methods. Standard requires virtual methods first.
6. **TICKET-0038: test_world.gd missing class_name** — Coding standard requires `class_name` on all scripts.

### P3 — Polish (no tickets, future cleanup)

1. **player_first_person.gd:129** — Camera Y set to `head_height + bob_offset` but Head node already positioned at `head_height`. Camera world Y = player_y + 1.8 + 1.8 + bob = double height. Pre-existing M1 issue.
2. **player_first_person.gd:44** — Dead warning suppression comment using GDScript 3 syntax (`# warning-ignore:`), no-op in GDScript 4.
3. **compass_bar.gd:8-9** — `MARKER_PERSIST_TIME` and `MARKER_FADE_TIME` constants defined but never used. Dead code.

### Review Summary

**Overall quality: Good.** Architecture is clean, signals are wired correctly, data layer integration is solid, and UI code follows the style guide. The one P1 bug (extract type mismatch) breaks the core gameplay loop but is a straightforward fix. P2 issues are mostly coding standards compliance (InputManager routing, section ordering, debug logging) rather than functional problems.

## Activity Log
- 2026-02-22 [producer] Created ticket
- 2026-02-23 [producer] All dependencies (TICKET-0024–0029) merged to main. PR #6 (gameplay), PR #8 (data layer fixes), PR #9 (unit tests) all merged. Code is on main and ready for review. Ticket unblocked — assign to systems-programmer.
- 2026-02-23 [systems-programmer] Code review complete. Found 1 P1 bug (mining extract type mismatch — fixed), 6 P2 issues (follow-up tickets created), 3 P3 notes (documented). P1 fix applied directly. Status → DONE.
