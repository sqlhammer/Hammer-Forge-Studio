---
id: TICKET-0129
title: "Code review — M7 systems"
type: REVIEW
status: TODO
priority: P2
owner: systems-programmer
created_by: producer
created_at: 2026-02-26
updated_at: 2026-02-26
milestone: "M7"
phase: "QA"
depends_on: [TICKET-0126, TICKET-0127, TICKET-0128, TICKET-0120, TICKET-0122]
blocks: [TICKET-0130]
tags: [code-review, qa, review]
---

## Summary

Code review of all M7 implementation work: the scene-architecture refactors (TICKET-0111 through TICKET-0117), the ship interior rebuild (TICKET-0126), cockpit features (TICKET-0127, TICKET-0128), interaction prompt HUD (TICKET-0120), and battery amber warning (TICKET-0122).

## Review Focus Areas

1. **Scene architecture compliance:** All refactored scenes follow the coding standards for self-contained `.tscn` scenes — correct root node types, no dangling references, clean instancing
2. **Ship interior structure:** Scene hierarchy is clean, node naming conventions followed, no orphaned nodes
3. **Signal connections:** All diegetic displays and HUD elements connect to the correct autoload signals
4. **Performance:** No unnecessary SubViewports, no duplicate resource loading, instancing used correctly (not duplicating)
5. **Coding standards:** All scripts follow `docs/engineering/coding-standards.md`

## Acceptance Criteria

- [ ] All M7 scripts and scenes reviewed
- [ ] No coding standards violations found (or all violations documented and BUGFIX tickets created)
- [ ] Scene instancing verified — no duplicated meshes or resources where instancing should be used
- [ ] Signal connections verified — no orphaned connections or missing disconnections
- [ ] Review findings documented in this ticket's Activity Log

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-26 [producer] Created ticket — M7 code review
