---
id: TICKET-0068
title: "Tech tree UI"
type: FEATURE
status: OPEN
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-24
updated_at: 2026-02-24
milestone: "M5"
milestone_gate: "M4"
phase: "Gameplay"
depends_on: [TICKET-0060, TICKET-0065]
blocks: [TICKET-0075]
tags: [tech-tree, ui, gameplay]
---

## Summary
Implement the tech tree UI — the screen through which players spend processed resources to unlock new ship modules and capabilities. In M5, the tree contains two nodes: Fabricator and Automation Hub. The UI must communicate locked/unlockable/unlocked states clearly and allow the player to execute an unlock with gamepad or keyboard/mouse.

## Acceptance Criteria
- [ ] Tech tree screen accessible from ship interior (interaction trigger TBD — coordinate with TICKET-0069 or as a dedicated terminal)
- [ ] Node graph rendered with M5 nodes: Fabricator (root), Automation Hub (child, requires Fabricator)
- [ ] Each node displays: name, unlock cost, prerequisite state, current locked/unlockable/unlocked status
- [ ] Unlockable node (prerequisites met + resources available) is highlighted and selectable
- [ ] Selecting an unlockable node shows a confirmation prompt with cost breakdown before committing
- [ ] On confirm: resources deducted, node marked unlocked, visual state updates immediately
- [ ] Locked node (prerequisites not met) is dimmed with a tooltip showing what is required
- [ ] Already-unlocked nodes shown in filled/completed visual state
- [ ] Fully navigable with gamepad (analog stick + confirm button); mouse/keyboard also supported
- [ ] References `TechTree` autoload from TICKET-0060 for all state reads and unlock calls
- [ ] All code follows `docs/engineering/coding-standards.md`

## Implementation Notes
- Reference wireframes from TICKET-0065
- The tech tree screen is a new UI scene — follow existing UI scene conventions from M3/M4
- M5 only has 2 nodes; the layout should be designed to accommodate future node growth without rework
- Consider whether the tech tree is accessed from a dedicated terminal in the ship interior, a menu, or the HUD — align with UI/UX design from TICKET-0065

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-24 [producer] Created ticket
