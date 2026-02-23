---
id: TICKET-0040
title: "Module system — data layer and framework"
type: FEATURE
status: OPEN
priority: P1
owner: systems-programmer
created_by: producer
created_at: 2026-02-23
updated_at: 2026-02-23
milestone: "M4"
depends_on: [TICKET-0039]
blocks: [TICKET-0041, TICKET-0044]
tags: [ship, modules, architecture]
---

## Summary
Define the module system architecture. Modules are discrete, installable units that attach to the ship and draw from the ship's power supply. M4 scope: one module type (Recycler). The framework must be extensible so future module types require no structural changes.

## Acceptance Criteria
- [ ] Module base class/resource defined with: ID, display name, tier, install cost (resource type + quantity), power draw, slot type
- [ ] Module catalog/registry for looking up all available module definitions
- [ ] Install API: validate resource cost against player inventory, deduct cost on success, register module as installed in ShipState
- [ ] Remove API: unregister module from ShipState (no refund in M4)
- [ ] Installed modules tracked in ShipState and persisted correctly
- [ ] Module power draw registered with ShipState on install, deregistered on remove
- [ ] Power overload defined: total module draw cannot exceed ship power capacity (baseline in M4)
- [ ] Framework extensible: adding a new module type requires only a new data definition, no framework changes
- [ ] All code follows `docs/engineering/coding-standards.md`

## Implementation Notes
- Reference `docs/design/systems/mobile-base.md` for the full module system spec and module type list
- M4 only implements Recycler — but the catalog pattern must accommodate all nine module types listed in the spec
- The install cost for the Recycler is Scrap Metal (quantity TBD — designer's discretion)
- Power overload behavior in M4: block install if draw would exceed baseline capacity

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-23 [producer] Created ticket
