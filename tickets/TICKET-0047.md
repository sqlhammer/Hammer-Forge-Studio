---
id: TICKET-0047
title: "Inventory UI — ship stats sidebar"
type: FEATURE
status: OPEN
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-23
updated_at: 2026-02-23
milestone: "M4"
depends_on: [TICKET-0039, TICKET-0042]
blocks: [TICKET-0048]
tags: [inventory, ship, ui]
---

## Summary
Add a ship stats sidebar to the existing inventory screen. Displays Power, Integrity, Heat, and Oxygen at a glance when the player opens their inventory outside the ship, allowing remote status review without returning to the ship.

## Acceptance Criteria
- [ ] Ship stats panel visible on the inventory screen per the TICKET-0042 wireframe
- [ ] All four global variables (Power, Integrity, Heat, Oxygen) displayed
- [ ] Values update reactively via signals from ShipState (TICKET-0039)
- [ ] No layout conflicts with the existing inventory grid (TICKET-0028)
- [ ] Follows M3 UI style guide
- [ ] No Godot editor errors or warnings

## Implementation Notes
- This is an additive change to the existing inventory screen — do not redesign the existing layout
- Bind to ShipState signals from TICKET-0039 — do not poll values
- The sidebar should display the same four variables as the in-ship HUD but in a compact format suitable for the inventory screen

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-23 [producer] Created ticket
