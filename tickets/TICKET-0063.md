---
id: TICKET-0063
title: "Head Lamp — item data layer"
type: FEATURE
status: DONE
priority: P1
owner: systems-programmer
created_by: producer
created_at: 2026-02-24
updated_at: 2026-02-24
milestone: "M5"
milestone_gate: "M4"
phase: "Foundation"
depends_on: []
blocks: [TICKET-0074]
tags: [head-lamp, player-suit, equipment, data]
---

## Summary
Define the Head Lamp as a suit equipment item — a directional light that attaches to the player's helmet and can be toggled on or off. Once crafted at the Fabricator, it is permanently equipped to the suit (not an inventory consumable). When active, it drains suit battery charge. New feature — not previously in any design spec.

## Acceptance Criteria
- [ ] `HeadLamp` equipment resource defined with `is_equipped` (bool) and `active` (bool) state
- [ ] Battery drain rate defined as a constant (placeholder: 2% per second while active — confirm with Studio Head)
- [ ] `toggle()` method defined: flips `active` state, emits `head_lamp_toggled(active)` signal
- [ ] Equipment state (equipped/active) persists across scene transitions
- [ ] Fabricator recipe registered: placeholder cost of 5 Metal (confirm with Studio Head)
- [ ] All code follows `docs/engineering/coding-standards.md`

## Implementation Notes
- Head Lamp is durable equipment, not a consumable — it does not deplete or break; only suit battery is consumed while it is active
- Battery drain integrates with existing `SuitBattery` system (M3) via the same drain pathway as tools
- The toggle mechanic and visual (TICKET-0074) depend on this data layer
- Because this is permanent equipment (not an inventory item), it does not occupy inventory slots after crafting

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-24 [producer] Created ticket
- 2026-02-24 [systems-programmer] Started implementation
- 2026-02-24 [systems-programmer] Created HeadLamp autoload (scripts/systems/head_lamp.gd) with is_equipped/active state, toggle(), force_off(), battery drain via _process, and ConfigFile persistence. Registered in project.godot. Recipe constants defined for Fabricator integration.
