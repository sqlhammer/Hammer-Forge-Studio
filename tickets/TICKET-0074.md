---
id: TICKET-0074
title: "Head Lamp — toggle mechanic and visual"
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
depends_on: [TICKET-0063, TICKET-0083]
blocks: [TICKET-0075]
tags: [head-lamp, gameplay, player-suit, lighting]
---

## Summary
Implement the Head Lamp toggle mechanic and its in-world visual. The Head Lamp is crafted at the Fabricator (TICKET-0069), permanently equips to the suit helmet after crafting, and can be toggled on/off by the player at any time. When active, it emits a directional light cone in the player's facing direction and drains suit battery at a steady rate.

## Acceptance Criteria
- [ ] Head Lamp is automatically equipped to the suit after being crafted (no manual equip step)
- [ ] Player can toggle the Head Lamp on/off via a dedicated input action (add to InputManager)
- [ ] When on: a directional SpotLight3D (or equivalent) is active, attached to the player camera/head node, illuminating the area ahead
- [ ] When on: suit battery drains at the rate defined in TICKET-0063 data layer (placeholder: 2% per second)
- [ ] When off: no light emitted, no battery drain from the lamp
- [ ] Toggle is available in both first-person and third-person camera modes
- [ ] Head Lamp state (on/off) persists across scene transitions
- [ ] Head Lamp cannot be toggled if it has not been crafted yet — action is silently unavailable
- [ ] No HUD indicator required for M5 — battery bar already conveys drain (revisit in future UI pass)
- [ ] All code follows `docs/engineering/coding-standards.md`

## Implementation Notes
- Reference TICKET-0063 for the data layer, toggle signal, and drain rate
- The lamp is a Godot SpotLight3D parented to the player camera or head bone — position and angle to be tuned during QA
- Battery drain uses the same drain pathway as mining tools (M3 SuitBattery system)
- Input action name: `toggle_head_lamp` — add to InputManager and default keybind (suggest: F key or equivalent gamepad button)
- This mechanic can be implemented and tested independently of the Fabricator (set `is_equipped = true` in debug setup)

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-24 [producer] Created ticket
