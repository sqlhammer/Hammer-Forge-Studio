# Deferred Work Items

**Owner:** producer
**Last Updated:** 2026-03-03 (M10 kickoff — D-001, D-015, D-033, D-034, D-035 scheduled; D-005, D-006, D-008, D-025 closed; D-007 requirements confirmed, TICKET-0286 created; D-036 added — Ping Wheel UX refinement from Studio Head playtest)

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
| D-001 | Scanner radial wheel (resource type selection for Phase 1 ping) | `docs/design/systems/meaningful-mining.md` | M3 has only one resource type (Scrap Metal) — radial wheel adds UI complexity with no gameplay value until multiple resources exist | M5 (Biome Progression) | Scheduled | TICKET-0281 |
| D-002 | Mining minigame (trace lit lines on deposit for +50% yield bonus) | `docs/design/systems/meaningful-mining.md` | Adds interaction depth but is not required for core loop validation; hold-to-extract proves the loop | M4 (Ship Systems) or M5 | Scheduled | TICKET-0070 |
| D-003 | Ship global variables (Power, Integrity, Heat, Oxygen) | `docs/design/systems/mobile-base.md` | Ship is a static landmark in M3 — systems require full module architecture | M4 (Ship Infrastructure) | Scheduled | TICKET-0039 |
| D-004 | Ship navigation between biomes | `docs/design/systems/mobile-base.md` | M3 is a single bounded test area — navigation requires biome generation and fuel systems | M8 (Ship Navigation) | Scheduled | TICKET-0159 |
| D-005 | Resource processing (smelting, refining, crafting components) | `docs/design/gdd.md` | Core loop in M3 ends at collection — processing requires the ship's Extraction Bay module | M5 (Processing & Crafting) | Done | — |
| D-006 | Build/upgrade from tech tree | `docs/design/gdd.md` | No tech tree in M3 — requires processing pipeline and module system first | M5 (Processing & Crafting) | Done | — |
| D-007 | Resource node respawning — in-biome timed respawn per node; per-resource-type config (default 300 s); depleted nodes hidden/disabled but not freed; deep (infinite) nodes excluded | `docs/design/systems/meaningful-mining.md` | Depleted deposits stay depleted in M3 — respawn mechanics tied to biome balancing | M10 | Scheduled | TICKET-0286 |
| D-008 | Multiple resource types beyond Scrap Metal | `docs/design/systems/biomes.md` | M3 tutorial zone uses only Scrap Metal — additional resources arrive with new biomes and tool tiers | M5 (Biome Progression) | Done | — |
| D-009 | Mining drones (mid-game automation) | `docs/design/systems/meaningful-mining.md` | Automation is a mid-game reward — requires drone programming UI, ship Power draw, defense modules | M5 or M6 | Scheduled | TICKET-0072 |
| D-010 | Tool tiers beyond Hand Drill (Pneumatic, Thermal, Plasma Cutter, Resonance Bore) | `docs/design/systems/meaningful-mining.md` | M3 only has Tier 1 deposits — higher tiers arrive with biome progression | M5 (Biome Progression) | Open | — |
| D-011 | Spare batteries (craftable/findable, occupy inventory slots) | `docs/design/systems/player-suit.md` | M3 battery recharges at ship only — spare batteries add field-time extension as a mid-game reward | M4 or M5 | Scheduled | TICKET-0073 |
| D-012 | Suit upgrades (battery capacity, movement speed, scanner range, armor) | `docs/design/systems/player-suit.md` | No upgrade path in M3 — requires crafting/tech tree systems | M4 (Ship Systems) | Open | — |
| D-013 | Scanner tier upgrades via Scanner Array ship module | `docs/design/systems/meaningful-mining.md` | M3 scanner has a single fixed range — tiered detection requires ship module system | M4 (Ship Systems) | Open | — |
| D-014 | Third-person camera scan/mine gameplay | N/A (planning decision) | M3 uses first-person only for scan/mine loop — third-person integration deferred to keep scope tight | M4 or M5 | Scheduled | TICKET-0071 |
| D-015 | Animated scanner ping propagation — ping front expands outward at a fixed speed with a 1000 m hard range limit; compass markers appear only as the ping front reaches each deposit (not all at once); a visual expanding ring originates at the player and grows at the same rate as the ping, giving the player a spatial reference for why markers appear progressively over several seconds | `docs/design/systems/meaningful-mining.md` | M3 ping is instantaneous — animated propagation requires a ring VFX, a ping-front timer/radius system, and deferred marker reveal logic; adds significant feel to the scanner but is not required for loop validation | M10 | Scheduled | TICKET-0282 |
| D-016 | Interaction prompt HUD — contextual action hints centered at screen bottom (key badge + descriptor, thicker border for hold actions) and persistent controls panel in bottom-right (Q ping, I inventory) with device-aware input glyphs | N/A (Studio Head request) | Not yet assigned to a milestone; backlogged pending M5 planning | M7 (Ship Interior) | Scheduled | TICKET-0120 |

### From M5 — Processing & Crafting

| ID | Description | Design Ref | Reason Deferred | Suggested Milestone | Status | Scheduled In |
|----|-------------|------------|-----------------|---------------------|--------|--------------|
| D-017 | Ship exterior refactor — extract as a standalone instanced scene | N/A (scene architecture standards) | Scene was embedded during M4/M5 greybox; instancing deferred to keep scope on gameplay features | M7 (Ship Interior) | Scheduled | TICKET-0111 |
| D-018 | Resource deposit refactor — extract as a standalone instanced scene with per-type subscenes | N/A (scene architecture standards) | Deposit was embedded during M3 greybox; instancing deferred to keep M3/M5 scope tight | M7 (Ship Interior) | Scheduled | TICKET-0112 |
| D-019 | Ship machines refactor — extract Recycler, Fabricator, and Automation Hub as standalone instanced scenes | N/A (scene architecture standards) | Machines were embedded during M4/M5 implementation; instancing deferred to avoid mid-milestone churn | M7 (Ship Interior) | Scheduled | TICKET-0113 |
| D-020 | Tools refactor — extract Hand Drill and Scanner as standalone instanced scenes | N/A (scene architecture standards) | Tools were embedded during M3; instancing deferred to keep M3 scope tight | M7 (Ship Interior) | Scheduled | TICKET-0114 |
| D-021 | Carriable items refactor — extract Spare Battery and Head Lamp as standalone instanced scenes | N/A (scene architecture standards) | Items were implemented inline during M5; instancing deferred to avoid scope creep | M7 (Ship Interior) | Scheduled | TICKET-0115 |
| D-022 | Mining drone refactor — extract as a standalone instanced scene | N/A (scene architecture standards) | Drone was implemented inline during M5; instancing deferred to avoid scope creep | M7 (Ship Interior) | Scheduled | TICKET-0116 |
| D-023 | UI panels and HUD refactor — extract all panels and HUD elements as standalone instanced subscenes | N/A (scene architecture standards) | UI was built inline during M4/M5; instancing deferred to keep gameplay features prioritised | M7 (Ship Interior) | Scheduled | TICKET-0117 |

### From M6 — Icon Generation Pipeline

| ID | Description | Design Ref | Reason Deferred | Suggested Milestone | Status | Scheduled In |
|----|-------------|------------|-----------------|---------------------|--------|--------------|
| D-024 | Battery bar amber warning tier — add intermediate amber (#FFB830) tint between teal (normal) and coral (critical) for a 3-tier color system | `docs/art/icon-needs.md` | Icon-needs spec called for 3-tier tinting but implementation shipped with 2 tiers; Studio Head deferred to backlog during M6 QA sign-off | M7 (Ship Interior) | Scheduled | TICKET-0122 |

### From M8 — Ship Navigation

| ID | Description | Design Ref | Reason Deferred | Suggested Milestone | Status | Scheduled In |
|----|-------------|------------|-----------------|---------------------|--------|--------------|
| D-025 | Expand ticket ID system from 4 digits to 6 digits — update ID generation, all tooling (milestone_status.sh, orchestrator, status.py), ticket filename conventions, and any references in docs/templates | N/A (producer tooling) | Current 4-digit IDs (TICKET-0001–9999) are approaching saturation as milestone count grows; 6-digit IDs (TICKET-000001–999999) provide long-term headroom without tooling breakage | Post-M8 or inter-milestone tooling sprint | Done | — |
| D-026 | Fix section header mislabeling in M8 data classes — `TerrainFeatureRequest`, `TerrainGenerationResult`, `TerrainChunk`, and `BiomeArchetypeConfig` have public member variables (no `_` prefix, accessed externally) under `# ── Private Variables ──` section headers; should be `# ── Public Variables ──` per coding standards | `docs/engineering/coding-standards.md` | P3 finding from TICKET-0177 code review — cosmetic section header inconsistency, no functional impact | M9 | Scheduled | TICKET-0258 |
| D-027 | DeepResourceNode class unused in biome scenes — biome scripts create `Deposit.new()` with `infinite = true` instead of `DeepResourceNode.new()`; class exists but is never instantiated in production code | N/A (M8 code review) | P3 finding from TICKET-0177 — behavior is correct; using DeepResourceNode would consolidate defaults | M9 | Scheduled | TICKET-0259 |
| D-028 | PlayerFirstPerson uses `_process()` for physics movement — `move_and_slide()` called from `_process()` instead of `_physics_process()`; works in Godot 4 but inconsistent with CharacterBody3D best practices | N/A (pre-M8, noted during M8 review) | P3 finding from TICKET-0177 — no observed issues; migration would improve physics consistency | M9 | Scheduled | TICKET-0260 |
| D-029 | NavigationConsole test null spy reference — `test_navigation_console_unit` `after_each()` calls `_spy.clear()` on null spy, producing SCRIPT ERRORs in log | N/A (QA finding from TICKET-0176) | P3 — tests pass but log is noisy; already noted in TICKET-0176 activity log | M9 | Scheduled | TICKET-0261 |
| D-030 | Drop items from inventory onto the ground as physical world objects and pick them back up via interaction | `docs/design/gdd.md` | Requested during M8 playtest; inventory management feature, not required for M8 navigation loop | M9 | Scheduled | TICKET-0218 |
| D-031 | Destroy (permanently discard) an item directly from inventory without spawning it in the world | `docs/design/gdd.md` | Requested during M8 playtest; inventory management feature, not required for M8 navigation loop | M9 | Scheduled | TICKET-0219 |
| D-032 | Debug launcher toggle for 3× player movement speed to accelerate QA traversal of large biomes | N/A (tooling/QA) | Requested during M8 playtest; developer convenience feature, not gameplay | M9 | Scheduled | TICKET-0220 |

| D-033 | Replace non-functional per-agent USD budget caps in orchestrator with per-agent `--max-turns` limits — the `budget_usd` values in `config.json` and `get_budget()` in `conductor.py` are passed through `run_claude()` but only used as a boolean (`if budget > 0`) to set a hardcoded `--max-turns 200`; the Claude CLI has no `--budget` flag so USD caps are never enforced; replace with configurable per-agent turn limits and remove dead budget plumbing | N/A (orchestrator tooling) | Non-blocking code smell; session ceiling is the only real cost gate and it works; per-agent USD tracking is aspirational until the CLI exposes a spend hook | M10 | Scheduled | TICKET-0283 |

### From M9 — Foundation & Hardening

| ID | Description | Design Ref | Reason Deferred | Suggested Milestone | Status | Scheduled In |
|----|-------------|------------|-----------------|---------------------|--------|--------------|
| D-034 | Enter Ship interaction should require the player to be pointing at a physical surface of the ship's external mesh — currently the interact trigger zone fires regardless of aim direction, making it possible to "enter" the ship while facing away from it or through opaque geometry | `docs/design/systems/mobile-base.md` | Gameplay feel improvement discovered during M9 UAT; not a blocker for the core loop; requires raycasting against the ship exterior mesh collision shape | M10 | Scheduled | TICKET-0280 |
| D-035 | Assign gamepad buttons to **Ping**, **Jump**, and **Headlamp** in the PersistentControls HUD — currently only Interact (A), Inventory (Select), and Item Actions (Y) are mapped; Ping (Q), Jump (Space), and Headlamp (F) have no gamepad bindings; a designer must propose a full input scheme (considering remaining available buttons: B, X, LB, RB, LT, RT, D-pad, L3, R3) and present options to the Studio Head for approval before implementation | N/A (M9 UAT finding) | Deferred from M9 to keep gamepad bug scope manageable; requires design sign-off before binding assignments are finalized | M10 | Scheduled | TICKET-0276, TICKET-0277, TICKET-0278, TICKET-0279 |

### From M10 — Visual Asset Refinement

| ID | Description | Design Ref | Reason Deferred | Suggested Milestone | Status | Scheduled In |
|----|-------------|------------|-----------------|---------------------|--------|--------------|
| D-036 | Ping Wheel UX refinement — four changes identified during Studio Head playtest: (1) selector slices are too narrow; move label text below the icon and widen each slice so icon + text fit without clipping; (2) increase the wheel's outer radius to give more room per slice and to accommodate more resource types as they are added; (3) keep the center circle area transparent so the player can see the world through the wheel's hub; (4) while the wheel is open, the right joystick / mouse must stop driving the camera and instead control ping selection — left joystick and WASD continue moving the player; (5) if the right joystick returns to center or the mouse cursor enters the center circle, deselect the current ping — releasing the ping button in that state fires nothing | `docs/design/systems/meaningful-mining.md` | Ping Wheel shipped in M10 (TICKET-0281) as a functional first pass; layout and input-mode issues identified during first Studio Head playtest; non-blocking for M10 close but must be resolved before Ping Wheel is considered shippable | M10 or M11 | Open | — |

---

## Review Cadence

The producer reviews this document at the start of every milestone planning session. Items with `Suggested Milestone` matching the current planning target MUST be evaluated for inclusion. If an item is scheduled, update its `Status` to `Scheduled` and fill in `Scheduled In` with the ticket ID.
