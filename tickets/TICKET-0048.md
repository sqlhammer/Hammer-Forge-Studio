---
id: TICKET-0048
title: "Code review — M4 systems"
type: REVIEW
status: OPEN
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
- [ ] Ship interior scene reviewed (TICKET-0043) — scene structure, collision, enter/exit triggers
- [ ] Module placement mechanic reviewed (TICKET-0044) — module catalog integration, resource deduction, install persistence
- [ ] Recycler panel UI reviewed (TICKET-0045) — job queue integration, inventory API usage, input context switching
- [ ] HUD ship globals display reviewed (TICKET-0046) — signal bindings, visibility toggling, style guide compliance
- [ ] Inventory UI ship stats sidebar reviewed (TICKET-0047) — signal bindings, layout, style guide compliance
- [ ] All code follows `docs/engineering/coding-standards.md`
- [ ] No direct Input API calls — all input routed through InputManager
- [ ] No architectural concerns or regressions from M1–M3 systems
- [ ] Review findings documented in Handoff Notes with severity (P1/P2 issues → new tickets, P3 → noted)

## Implementation Notes
- This is a review ticket, not an implementation ticket
- If review finds P0/P1 issues: block QA, create BUG tickets, assign back to gameplay-programmer
- If review finds P2 issues: create follow-up tickets but do not block M4 closure
- If review finds P3 issues: document in handoff notes for future cleanup
- Reference the code review protocol in CLAUDE.md

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-23 [producer] Created ticket
