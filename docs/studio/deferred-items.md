# Deferred Work Items

**Owner:** producer
**Last Updated:** 2026-02-22

> Tracks gameplay features and systems that were intentionally descoped from a milestone during planning. Each item references the design spec it originates from and the milestone where it was deferred. These items MUST be revisited and scheduled into a future milestone — they are not optional cuts, they are postponed work.

---

## Format

| Field | Description |
|-------|-------------|
| ID | Sequential identifier (D-NNN) |
| Deferred From | Milestone where the item was originally in scope |
| Design Ref | Path to the design document specifying this feature |
| Description | What was deferred and why |
| Suggested Milestone | Earliest milestone where this item makes sense |
| Status | Open / Scheduled / Done |
| Scheduled In | Ticket ID when the item is picked up (blank until scheduled) |

---

## Deferred Items

### From M3 — First Playable

| ID | Description | Design Ref | Reason Deferred | Suggested Milestone | Status | Scheduled In |
|----|-------------|------------|-----------------|---------------------|--------|--------------|
| D-001 | Scanner radial wheel (resource type selection for Phase 1 ping) | `docs/design/systems/meaningful-mining.md` | M3 has only one resource type (Scrap Metal) — radial wheel adds UI complexity with no gameplay value until multiple resources exist | M5 (Biome Progression) | Open | — |
| D-002 | Mining minigame (trace lit lines on deposit for +50% yield bonus) | `docs/design/systems/meaningful-mining.md` | Adds interaction depth but is not required for core loop validation; hold-to-extract proves the loop | M4 (Ship Systems) or M5 | Open | — |
| D-003 | Ship global variables (Power, Integrity, Heat, Oxygen) | `docs/design/systems/mobile-base.md` | Ship is a static landmark in M3 — systems require full module architecture | M4 (Ship Systems) | Open | — |
| D-004 | Ship navigation between biomes | `docs/design/systems/mobile-base.md` | M3 is a single bounded test area — navigation requires biome generation and fuel systems | M4 (Ship Systems) | Open | — |
| D-005 | Resource processing (smelting, refining, crafting components) | `docs/design/gdd.md` | Core loop in M3 ends at collection — processing requires the ship's Extraction Bay module | M4 (Ship Systems) | Open | — |
| D-006 | Build/upgrade from tech tree | `docs/design/gdd.md` | No tech tree in M3 — requires processing pipeline and module system first | M4 (Ship Systems) | Open | — |
| D-007 | Resource node respawning | `docs/design/systems/meaningful-mining.md` | Depleted deposits stay depleted in M3 — respawn mechanics tied to biome balancing | M5 (Biome Progression) | Open | — |
| D-008 | Multiple resource types beyond Scrap Metal | `docs/design/systems/biomes.md` | M3 tutorial zone uses only Scrap Metal — additional resources arrive with new biomes and tool tiers | M5 (Biome Progression) | Open | — |
| D-009 | Mining drones (mid-game automation) | `docs/design/systems/meaningful-mining.md` | Automation is a mid-game reward — requires drone programming UI, ship Power draw, defense modules | M5 or M6 | Open | — |
| D-010 | Tool tiers beyond Hand Drill (Pneumatic, Thermal, Plasma Cutter, Resonance Bore) | `docs/design/systems/meaningful-mining.md` | M3 only has Tier 1 deposits — higher tiers arrive with biome progression | M5 (Biome Progression) | Open | — |
| D-011 | Spare batteries (craftable/findable, occupy inventory slots) | `docs/design/systems/player-suit.md` | M3 battery recharges at ship only — spare batteries add field-time extension as a mid-game reward | M4 or M5 | Open | — |
| D-012 | Suit upgrades (battery capacity, movement speed, scanner range, armor) | `docs/design/systems/player-suit.md` | No upgrade path in M3 — requires crafting/tech tree systems | M4 (Ship Systems) | Open | — |
| D-013 | Scanner tier upgrades via Scanner Array ship module | `docs/design/systems/meaningful-mining.md` | M3 scanner has a single fixed range — tiered detection requires ship module system | M4 (Ship Systems) | Open | — |
| D-014 | Third-person camera scan/mine gameplay | N/A (planning decision) | M3 uses first-person only for scan/mine loop — third-person integration deferred to keep scope tight | M4 or M5 | Open | — |

---

## Review Cadence

The producer reviews this document at the start of every milestone planning session. Items with `Suggested Milestone` matching the current planning target MUST be evaluated for inclusion. If an item is scheduled, update its `Status` to `Scheduled` and fill in `Scheduled In` with the ticket ID.
