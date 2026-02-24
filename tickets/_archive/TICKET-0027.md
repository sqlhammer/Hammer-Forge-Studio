---
id: TICKET-0027
title: "HUD — battery bar and pickup notifications"
type: FEATURE
status: DONE
priority: P2
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-22
updated_at: 2026-02-22
milestone: "M3"
depends_on: [TICKET-0019, TICKET-0021, TICKET-0023]
blocks: []
tags: [hud, ui, battery, notifications]
---

## Summary
Implement the standalone HUD elements that are not part of another gameplay system ticket: the always-visible suit battery bar and the resource pickup notification popup. The compass is implemented in TICKET-0024, the analysis readout in TICKET-0025, and the mining progress indicator in TICKET-0026.

## Acceptance Criteria
- [ ] Battery bar displayed per wireframe spec (TICKET-0019) — always visible in first-person view
- [ ] Battery bar reflects real-time suit battery state via signals from TICKET-0023
- [ ] Battery bar shows visual states: full, draining, critical (low threshold), empty
- [ ] Resource pickup notification displayed when items are added to inventory (signal from TICKET-0021)
- [ ] Notification shows resource name and quantity (e.g., "+12 Scrap Metal")
- [ ] Notification appears briefly then fades out (1–2 seconds visible)
- [ ] Multiple rapid pickups stack or refresh the notification (no overlapping spam)
- [ ] All HUD elements follow the UI style guide (TICKET-0019)
- [ ] HUD elements are anchored correctly and scale appropriately

## Implementation Notes
- Reference wireframe specs from TICKET-0019 for exact layout, positioning, and styling
- Battery bar binds to `battery_changed` signal from the suit battery system
- Pickup notification binds to `item_added` signal from the inventory system
- Use Godot Control nodes with appropriate anchor presets
- Consider a shared HUD scene (`game/scenes/ui/hud.tscn`) that aggregates all HUD elements — the compass (TICKET-0024) would also be a child of this scene
- Reference `docs/engineering/coding-standards.md` for naming conventions

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-22 [producer] Created ticket
- 2026-02-22 [gameplay-programmer] Status → IN_PROGRESS
- 2026-02-22 [gameplay-programmer] Implementation complete. Commit f71b964. Status → DONE
- 2026-02-25 [producer] Archived
