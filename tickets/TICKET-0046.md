---
id: TICKET-0046
title: "HUD — ship globals display"
type: FEATURE
status: OPEN
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-23
updated_at: 2026-02-23
milestone: "M4"
milestone_gate: "M3"
depends_on: [TICKET-0039, TICKET-0042]
blocks: [TICKET-0048]
tags: [hud, ship, ui]
---

## Summary
Add ship global variable indicators to the HUD. Power, Integrity, Heat, and Oxygen are displayed when the player is inside the ship and hidden when outside.

## Acceptance Criteria
- [ ] Power, Integrity, Heat, and Oxygen displayed per the TICKET-0042 wireframe
- [ ] Indicators activate automatically when player enters the ship interior
- [ ] Indicators hide automatically when player exits the ship interior
- [ ] All four bars/readouts update reactively via signals from ShipState (TICKET-0039)
- [ ] No layout conflicts with existing HUD elements (battery bar top-left, compass top-center)
- [ ] Follows M3 UI style guide
- [ ] No Godot editor errors or warnings

## Implementation Notes
- Bind to ShipState signals from TICKET-0039 — do not poll values in `_process()`
- Visibility toggling should use the ship interior enter/exit events from TICKET-0043
- Reference the existing battery bar (TICKET-0027) as a pattern for signal-driven bar updates

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-23 [producer] Created ticket
