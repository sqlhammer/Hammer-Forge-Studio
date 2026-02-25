---
id: TICKET-0100
title: "Integrate HUD/functional icons — HUD, ship globals, notifications"
type: FEATURE
status: OPEN
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-25
updated_at: 2026-02-25
milestone: "M6"
milestone_gate: "M5"
phase: "Integration & QA"
depends_on: [TICKET-0097]
blocks: [TICKET-0101, TICKET-0102]
tags: [icons, integration, hud, notifications, ship-globals]
---

## Summary

Wire all HUD/functional icons from `game/assets/icons/hud/` into every HUD element, status panel, and notification system where functional icons appear. This replaces any placeholder states with the approved production icons.

## Acceptance Criteria

- [ ] **Suit battery bar:** Battery icon (`icon_hud_battery.svg`) displayed at the appropriate size inline with the battery bar; state-based color tinting applied (teal = normal, amber = warning, coral = critical) using `modulate` on the icon's TextureRect
- [ ] **Scanner HUD:** Scan ping icon displayed in the scanner readout panel at correct size
- [ ] **Compass:** Compass direction markers use the approved compass icon(s) at 16–24px
- [ ] **Mining progress:** Mining drill activity icon displayed during active mining at correct size
- [ ] **Ship globals HUD (interior):** Power, Integrity, Heat, Oxygen each have their respective icon displayed at 24px inline with their value readout
- [ ] **Ship stats sidebar (exterior/inventory):** Same four ship global icons used at the same or smaller size in the sidebar
- [ ] **Notification toasts:** Info, warning, and critical notification types use their respective badge icon (16–24px) in the left border area of the toast — satisfying the color-blind safety requirement (icon type, not color alone, differentiates notification severity)
- [ ] **Tech tree state indicators:** Lock icon, unlock/checkmark icon, and unlockable indicator icon are displayed at 16px in the bottom-right of tech tree node cards per the wireframe spec
- [ ] **Drone UI / Automation Hub panel:** Drone icon used appropriately in the drone programming interface
- [ ] No `[Missing Texture]` errors in any HUD icon slot after integration
- [ ] All icons inherit parent text color by default via `modulate` where the HUD icon style guide specifies dynamic tinting; fixed-color icons are set appropriately
- [ ] All code follows `docs/engineering/coding-standards.md`

## Implementation Notes

- Icons are committed to `game/assets/icons/hud/` by TICKET-0097. Reference them at their committed paths.
- Dynamic color tinting: in Godot, set `TextureRect.modulate` to the appropriate color constant from the UI theme. Do not hardcode hex values in scripts — use the theme color tokens.
- Refer to `docs/design/wireframes/` for exact icon size and placement for each HUD element:
  - Battery bar: `m3/battery-bar.md`
  - Compass: `m3/compass.md`
  - Mining progress: `m3/mining-progress.md`
  - Pickup notifications: `m3/pickup-notification.md`
  - Ship globals HUD: `m4/ship-globals-hud.md`
  - Tech tree node cards: `m5/tech-tree.md`
  - Third-person HUD: `m5/third-person-hud.md`
  - Drone UI: `m5/drone-programming.md`
- For any HUD element that currently uses a text character or emoji as an icon placeholder, replace it with the TextureRect-based icon

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-25 [producer] Created ticket for M6 Integration & QA phase
