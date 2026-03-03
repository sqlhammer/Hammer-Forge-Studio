---
id: TICKET-0290
title: "M11 Producer — build Phase 2 remediation tickets from audit report"
type: TASK
status: OPEN
priority: P1
owner: producer
created_by: producer
created_at: 2026-03-03
updated_at: 2026-03-03
milestone: "M11"
phase: "Audit"
depends_on: [TICKET-0289]
blocks: []
tags: [standards, planning, remediation, compliance]
---

## Summary

Read the audit report produced by TICKET-0289 and translate its findings into an executable
set of Phase 2 remediation tickets — one ticket per violating component (grouped by logical
system or scene, not by individual violation line). Then create the Phase 3 QA sign-off
ticket with the correct dependencies.

This ticket is the bridge between the audit and the fix work. Once it is `DONE`, the
orchestrator will have a fully wired dependency tree and can dispatch Phase 2 work
immediately.

---

## Acceptance Criteria

### Phase 2 Remediation Tickets

- [ ] Read `docs/studio/reports/YYYY-MM-DD-m11-gdscript-audit.md` in full
- [ ] Create one TASK ticket per violating **component** in `tickets/m11/`
      - "Component" = a single `.gd` / `.tscn` pair, or a logical system if multiple
        violations are tightly related (e.g., all HUD files, all ship systems)
      - Scene-First Rule violations get their own ticket per component (do not bundle
        them with other violation types)
      - Use the Systems Programmer's recommended remediation priority ordering from
        Section 5 of the audit report as the assignment priority
- [ ] Each Phase 2 ticket must include:
      - `owner`: `gameplay-programmer` for scene/UI work; `systems-programmer` for
        autoload or cross-system architecture fixes
      - `depends_on: []` (Phase 2 tickets are independent; parallelize them all)
      - `milestone: "M11"`, `phase: "Remediation"`
      - Clear acceptance criteria listing each specific violation to fix (copy the
        relevant rows from the audit report into the ticket)
      - A note in Implementation Notes pointing to the audit report section for context

### Phase 3 QA Ticket

- [ ] Create one QA sign-off ticket: `TICKET-XXXX: M11 QA — regression suite + editor
      compliance verification` (use the next available ticket ID after all Phase 2 tickets)
      - `owner: qa-engineer`
      - `depends_on`: list every Phase 2 remediation ticket ID
      - `milestone: "M11"`, `phase: "QA"`
      - Acceptance criteria: all tests pass, zero new Godot editor errors, phase gate
        summary report posted to `docs/studio/reports/`

### Milestone Doc Update

- [ ] Update `docs/studio/milestones.md` — set M11 Total and Open ticket counts to reflect
      the full Phase 1 + Phase 2 + Phase 3 ticket set

---

## Implementation Notes

Group tickets by the following heuristic:
- One ticket per top-level scene (e.g., `game_world.tscn`, `hud.tscn`, `nav_console.tscn`)
  if that scene's root script has violations
- One ticket per autoload script if it has violations
- One ticket per subsystem directory if violations are minor and numerous
  (e.g., "Fix naming and typing violations across `game/scripts/systems/`")

Do not create a ticket for files with zero violations — only violating components get tickets.

The Phase 3 QA ticket should include these acceptance criteria:
- Full test suite run via `res://addons/hammer_forge_tests/test_runner.tscn`; zero failures
- All M11 remediation scripts open in the Godot editor without errors or warnings
- Phase Gate Summary report posted to `docs/studio/reports/YYYY-MM-DD-m11-phase-gate-qa.md`
- QA Engineer marks ticket DONE and notifies Producer

---

## Handoff Notes

(Leave blank until handoff occurs.)

---

## Activity Log

- 2026-03-03 [producer] Created ticket — build Phase 2 remediation tickets from audit report
