# Deferred Work Items

**Owner:** producer
**Last Updated:** 2026-02-25 (D-017–D-023 added)

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
| D-002 | Mining minigame (trace lit lines on deposit for +50% yield bonus) | `docs/design/systems/meaningful-mining.md` | Adds interaction depth but is not required for core loop validation; hold-to-extract proves the loop | M4 (Ship Systems) or M5 | Scheduled | TICKET-0070 |
| D-003 | Ship global variables (Power, Integrity, Heat, Oxygen) | `docs/design/systems/mobile-base.md` | Ship is a static landmark in M3 — systems require full module architecture | M4 (Ship Infrastructure) | Scheduled | TICKET-0039 |
| D-004 | Ship navigation between biomes | `docs/design/systems/mobile-base.md` | M3 is a single bounded test area — navigation requires biome generation and fuel systems | M7 (Ship Navigation) | Open | — |
| D-005 | Resource processing (smelting, refining, crafting components) | `docs/design/gdd.md` | Core loop in M3 ends at collection — processing requires the ship's Extraction Bay module | M5 (Processing & Crafting) | Open | — |
| D-006 | Build/upgrade from tech tree | `docs/design/gdd.md` | No tech tree in M3 — requires processing pipeline and module system first | M5 (Processing & Crafting) | Open | — |
| D-007 | Resource node respawning | `docs/design/systems/meaningful-mining.md` | Depleted deposits stay depleted in M3 — respawn mechanics tied to biome balancing | M5 (Biome Progression) | Open | — |
| D-008 | Multiple resource types beyond Scrap Metal | `docs/design/systems/biomes.md` | M3 tutorial zone uses only Scrap Metal — additional resources arrive with new biomes and tool tiers | M5 (Biome Progression) | Open | — |
| D-009 | Mining drones (mid-game automation) | `docs/design/systems/meaningful-mining.md` | Automation is a mid-game reward — requires drone programming UI, ship Power draw, defense modules | M5 or M6 | Scheduled | TICKET-0072 |
| D-010 | Tool tiers beyond Hand Drill (Pneumatic, Thermal, Plasma Cutter, Resonance Bore) | `docs/design/systems/meaningful-mining.md` | M3 only has Tier 1 deposits — higher tiers arrive with biome progression | M5 (Biome Progression) | Open | — |
| D-011 | Spare batteries (craftable/findable, occupy inventory slots) | `docs/design/systems/player-suit.md` | M3 battery recharges at ship only — spare batteries add field-time extension as a mid-game reward | M4 or M5 | Scheduled | TICKET-0073 |
| D-012 | Suit upgrades (battery capacity, movement speed, scanner range, armor) | `docs/design/systems/player-suit.md` | No upgrade path in M3 — requires crafting/tech tree systems | M4 (Ship Systems) | Open | — |
| D-013 | Scanner tier upgrades via Scanner Array ship module | `docs/design/systems/meaningful-mining.md` | M3 scanner has a single fixed range — tiered detection requires ship module system | M4 (Ship Systems) | Open | — |
| D-014 | Third-person camera scan/mine gameplay | N/A (planning decision) | M3 uses first-person only for scan/mine loop — third-person integration deferred to keep scope tight | M4 or M5 | Scheduled | TICKET-0071 |
| D-015 | Animated scanner ping propagation — ping front expands outward at a fixed speed with a 1000 m hard range limit; compass markers appear only as the ping front reaches each deposit (not all at once); a visual expanding ring originates at the player and grows at the same rate as the ping, giving the player a spatial reference for why markers appear progressively over several seconds | `docs/design/systems/meaningful-mining.md` | M3 ping is instantaneous — animated propagation requires a ring VFX, a ping-front timer/radius system, and deferred marker reveal logic; adds significant feel to the scanner but is not required for loop validation | M9 (Movement & Usability Refinement) | Open | — |
| D-016 | Interaction prompt HUD — contextual action hints centered at screen bottom (key badge + descriptor, thicker border for hold actions) and persistent controls panel in bottom-right (Q ping, I inventory) with device-aware input glyphs | N/A (Studio Head request) | Not yet assigned to a milestone; backlogged pending M5 planning | M5 or M6 | Scheduled | TICKET-0120 |

### From M5 — Processing & Crafting

| ID | Description | Design Ref | Reason Deferred | Suggested Milestone | Status | Scheduled In |
|----|-------------|------------|-----------------|---------------------|--------|--------------|
| D-017 | Ship exterior refactor — extract as a standalone instanced scene | N/A (scene architecture standards) | Scene was embedded during M4/M5 greybox; instancing deferred to keep scope on gameplay features | M6 or later | Open | — |
| D-018 | Resource deposit refactor — extract as a standalone instanced scene with per-type subscenes | N/A (scene architecture standards) | Deposit was embedded during M3 greybox; instancing deferred to keep M3/M5 scope tight | M6 or later | Open | — |
| D-019 | Ship machines refactor — extract Recycler, Fabricator, and Automation Hub as standalone instanced scenes | N/A (scene architecture standards) | Machines were embedded during M4/M5 implementation; instancing deferred to avoid mid-milestone churn | M6 or later | Open | — |
| D-020 | Tools refactor — extract Hand Drill and Scanner as standalone instanced scenes | N/A (scene architecture standards) | Tools were embedded during M3; instancing deferred to keep M3 scope tight | M6 or later | Open | — |
| D-021 | Carriable items refactor — extract Spare Battery and Head Lamp as standalone instanced scenes | N/A (scene architecture standards) | Items were implemented inline during M5; instancing deferred to avoid scope creep | M6 or later | Open | — |
| D-022 | Mining drone refactor — extract as a standalone instanced scene | N/A (scene architecture standards) | Drone was implemented inline during M5; instancing deferred to avoid scope creep | M6 or later | Open | — |
| D-023 | UI panels and HUD refactor — extract all panels and HUD elements as standalone instanced subscenes | N/A (scene architecture standards) | UI was built inline during M4/M5; instancing deferred to keep gameplay features prioritised | M6 or later | Open | — |

---

## Review Cadence

The producer reviews this document at the start of every milestone planning session. Items with `Suggested Milestone` matching the current planning target MUST be evaluated for inclusion. If an item is scheduled, update its `Status` to `Scheduled` and fill in `Scheduled In` with the ticket ID.
