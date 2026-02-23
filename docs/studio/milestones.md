# Milestone Roadmap

**Owner:** producer
**Status:** Draft
**Last Updated:** —

> Tracks all project milestones, their target dates, and completion status. Studio Head sets milestone goals; Producer maintains this document.

---

## Format

| Field | Description |
|-------|-------------|
| Milestone | Name and short description |
| Target Date | Planned completion |
| Status | Planning / Active / QA / Complete |
| Tickets | Count of total / open / done tickets in scope |
| QA Sign-off | Date QA Engineer signed off (required to close) |

---

## Milestones

| # | Milestone | Target Date | Status | Total | Open | Done | QA Sign-off |
|---|-----------|-------------|--------|-------|------|------|-------------|
| M0 | Studio Setup — Team infrastructure, ticket system, docs | 2026-02-20 | Complete | — | — | — | — |
| M1 | Core Game Architecture — Player controller, input system, view modes | 2026-02-21 | Complete | 7 | 0 | 7 | 2026-02-21 |
| M2 | 3D Asset Pipeline — PoC evaluation, pipeline SOP, M3-ready assets | 2026-02-22 | Complete | 10 | 0 | 10 | 2026-02-22 |
| M3 | First Playable — Minimal ship in world, scan/mine loop | — | Active | 13 | 8 | 5 | — |
| M4 | Ship Infrastructure — Ship globals, module system, Recycler, greybox interior | — | Planning | 11 | 11 | 0 | — |
| M5 | Processing & Crafting — Smelting, components, tech tree, build/upgrade | — | Planning | — | — | — | — |
| M6 | Ship Interior — Cockpit and machine room buildout | — | Planning | — | — | — | — |
| M7 | Ship Navigation — Biome-to-biome travel, fuel system | — | Planning | — | — | — | — |
| M8 | Visual Asset Refinement — Polished art pass on existing assets | — | Planning | — | — | — | — |
| M9 | Movement & Usability Refinement — Game feel, controls, HUD/UX tuning | — | Planning | — | — | — | — |
| M10 | Content Expansion — Material resources, crafting recipes, tech tree depth | — | Planning | — | — | — | — |
| M11 | Biome Progression — Tier 1–3 biomes, escalating threats | — | Planning | — | — | — | — |
| M12 | Mega-Project Arc — Full tech tree, endgame sequence | — | Planning | — | — | — | — |
| M13 | Alpha — Full playthrough possible | — | Planning | — | — | — | — |
| M14 | Beta — External testing | — | Planning | — | — | — | — |

---

## Milestone Notes

### M0 — Studio Setup

**Goal:** Establish all team infrastructure so the studio can begin game development.

**Scope:**
- Agent CLAUDE.md files for all 14 agents
- Ticket system operational
- Docs directory structure in place
- Root README updated

**Dependencies:** None

**Risks:** None identified

---

### M1 — Core Game Architecture ✅

**Goal:** Build testable first-person and third-person player control systems with a unified input architecture.

**Scope:**
- Input system design and architecture specification
- InputManager autoload for keyboard and gamepad input normalization
- First-person player controller (movement, camera control)
- Third-person orbital camera system (ship/base view)
- Integrated player scene with view-switching
- Code review and QA testing

**Tickets:** TICKET-0001 through TICKET-0007 (archived)

**Dependencies:** M0 (infrastructure must be in place)

**Closed:** 2026-02-21 — QA sign-off by qa-engineer

---

### M2 — 3D Asset Pipeline

**Goal:** Establish the authoritative, repeatable 3D asset production pipeline through competitive PoC evaluation. Close with a documented SOP, completed art tech specs, and 4 game-ready assets for M3.

**Scope:**
- Asset briefs and PoC evaluation criteria (4 target assets: hand drill, player character, ship exterior, resource node)
- Blender Python PoC — produce all 4 assets using the existing programmatic pipeline
- AI generation PoC — tool selection and produce all 4 assets
- Evaluate results and produce a pipeline recommendation for Studio Head decision
- 3D pipeline SOP and completed art tech specs
- Final M3-ready production assets using the chosen pipeline
- QA import validation and pipeline reproducibility check

**Tickets:** TICKET-0008 through TICKET-0014

**Dependencies:** M1 (player controller exists for scale reference and in-engine testing)

**Risks:**
- AI generation tools may produce poor topology requiring significant manual cleanup, undermining their speed advantage
- Blender Python pipeline may struggle with organic/character shapes (hand drill, player) versus mechanical geometry
- Pipeline decision may reveal a hybrid approach is needed, adding complexity to the SOP
- Art tech specs (poly budgets, texture budgets) are currently TBD — PoC results will inform them, but early M3 work may need to be revised

---

### M3 — First Playable

**Goal:** Player can exist in a minimal game world, spawn at the ship, scan for resource deposits, navigate via compass, analyze a deposit, mine it with the hand drill, collect resources into inventory, manage suit battery, and return to the ship to recharge. First end-to-end pass of the core loop.

**Scope:**
- First-person perspective only (third-person deferred)
- Scanner Phase 1: ping reveals deposits, compass markers with distance readout
- Scanner Phase 2: hold-to-analyze, readout shows purity/density/energy cost
- Mining: hold-to-extract with hand drill, battery drain, inventory collection, deposit depletion
- Suit battery: drains during mining, recharges at ship, 25% movement penalty at 0%
- Inventory: 15 slots, 100 per stack, slot-based grid UI
- HUD: compass, battery bar, mining progress, pickup notifications
- Greybox test world: bounded area, ship as static landmark with recharge zone, 8–12 deposits
- Ship is a static mesh — no systems, no navigation, no interior
- One resource type: Scrap Metal (Tier 1)
- No respawning deposits
- UI style guide and wireframes from UI/UX designer, implemented by programmers

**Tickets:** TICKET-0019 through TICKET-0031

| Phase | Ticket | Title | Type | Owner |
|-------|--------|-------|------|-------|
| Foundation | TICKET-0019 | UI style guide and M3 wireframes | DESIGN | ui-ux-designer |
| Foundation | TICKET-0020 | Resource data definitions | DESIGN | systems-programmer |
| Foundation | TICKET-0021 | Inventory system — data layer | FEATURE | systems-programmer |
| Foundation | TICKET-0022 | Deposit system — data layer | FEATURE | systems-programmer |
| Foundation | TICKET-0023 | Suit battery system | FEATURE | systems-programmer |
| Gameplay | TICKET-0024 | Scanner Phase 1 — ping and compass | FEATURE | gameplay-programmer |
| Gameplay | TICKET-0025 | Scanner Phase 2 — analyze deposit | FEATURE | gameplay-programmer |
| Gameplay | TICKET-0026 | Mining interaction | FEATURE | gameplay-programmer |
| Gameplay | TICKET-0027 | HUD — battery bar and pickup notifications | FEATURE | gameplay-programmer |
| Gameplay | TICKET-0028 | Inventory UI | FEATURE | gameplay-programmer |
| Integration | TICKET-0029 | Greybox test world | TASK | gameplay-programmer |
| QA | TICKET-0030 | Code review — M3 systems | REVIEW | systems-programmer |
| QA | TICKET-0031 | QA testing — M3 full loop | TASK | qa-engineer |

**Deferred Items:** 14 items tracked in `docs/studio/deferred-items.md` — includes mining minigame, radial wheel, ship systems, navigation, processing, tech tree, tool tiers, drones, and more.

**Dependencies:** M2 (assets and pipeline required before world-building begins)

**Risks:**
- UI/UX wireframes (TICKET-0019) are on the critical path — gameplay tickets cannot start HUD work without them
- Compass and scanner integration may require iteration to feel right in first-person — budget for playtest tuning
- Inventory UI is the first significant Control node work in the project — may surface Godot UI patterns that need establishing

---

### M4 — Ship Infrastructure

**Goal:** The ship becomes a living entity. Player can enter a greybox ship interior, review ship global variables (Power, Integrity, Heat, Oxygen), install the Recycler module, and convert Scrap Metal into Metal — establishing the module system and the first step of the processing pipeline.

**Scope:**
- Ship global variables (Power, Integrity, Heat, Oxygen) — data layer, signals, baseline power
- Baseline ship power: always-on, sufficient to recharge player suit and run one Tier 1 machine
- Module system framework: install/remove API, power draw tracking, extensible catalog
- Recycler module: Scrap Metal → Metal, runs on baseline power, costs Scrap Metal to install
- Greybox ship interior scene: walkable, enter/exit from exterior, module placement zone
- Module placement mechanic: interact with placement zone to install Recycler from catalog
- Recycler interaction panel UI: queue jobs, monitor progress, collect output
- HUD: ship globals displayed when inside ship
- Inventory UI: ship stats sidebar showing all four globals when outside ship

**Tickets:** TICKET-0039 through TICKET-0049

| Phase | Ticket | Title | Type | Owner |
|-------|--------|-------|------|-------|
| Foundation | TICKET-0039 | Ship global variables — data layer | FEATURE | systems-programmer |
| Foundation | TICKET-0040 | Module system — data layer and framework | FEATURE | systems-programmer |
| Foundation | TICKET-0041 | Recycler module — data layer and logic | FEATURE | systems-programmer |
| Foundation | TICKET-0042 | UI/UX — ship globals HUD, ship stats sidebar, Recycler panel, interior wireframes | DESIGN | ui-ux-designer |
| Gameplay | TICKET-0043 | Greybox ship interior scene | TASK | gameplay-programmer |
| Gameplay | TICKET-0044 | Module placement mechanic | FEATURE | gameplay-programmer |
| Gameplay | TICKET-0045 | Recycler interaction panel UI | FEATURE | gameplay-programmer |
| Gameplay | TICKET-0046 | HUD — ship globals display | FEATURE | gameplay-programmer |
| Gameplay | TICKET-0047 | Inventory UI — ship stats sidebar | FEATURE | gameplay-programmer |
| QA | TICKET-0048 | Code review — M4 systems | REVIEW | systems-programmer |
| QA | TICKET-0049 | QA testing — M4 full loop | TASK | qa-engineer |

**Deferred Items scheduled in M4:** D-003 (ship global variables → TICKET-0039)

**Dependencies:** M3 (first playable world and inventory system required)

---

### M5 — Processing & Crafting

**Goal:** Close the full core loop. Player can smelt raw materials, craft components, and build/upgrade ship systems from the tech tree.

**Scope:** TBD — to be defined after M4 closes.

**Dependencies:** M4 (module system and Recycler establish the processing foundation)

---

### M6 — Ship Interior

**Goal:** The ship interior is fully realized. Player has a defined cockpit and a large machine room for placing modules.

**Scope:** TBD — to be defined after M5 closes.

**Dependencies:** M5

---

### M7 — Ship Navigation

**Goal:** Player can navigate the ship between biomes. Travel consumes fuel based on distance and ship weight.

**Scope:** TBD — to be defined after M6 closes.

**Dependencies:** M6

---

### M8 — Visual Asset Refinement

**Goal:** Polished art pass on all existing game assets.

**Scope:** TBD — to be defined after M7 closes.

**Dependencies:** M7

---

### M9 — Movement & Usability Refinement

**Goal:** Game feel, first-person controls, and HUD/UX tuning pass.

**Scope:** TBD — to be defined after M8 closes.

**Dependencies:** M8

---

### M10 — Content Expansion

**Goal:** Additional material resources, crafting recipes, and tech tree depth.

**Scope:** TBD — to be defined after M9 closes.

**Dependencies:** M9

---

### M11 — Biome Progression

**Goal:** Full Tier 1–3 biome progression with escalating threats and resource gates.

**Scope:** TBD — to be defined after M10 closes.

**Dependencies:** M10

---

### M12 — Mega-Project Arc

**Goal:** Complete tech tree and endgame sequence playable end-to-end.

**Scope:** TBD

**Dependencies:** M11

---

### M13 — Alpha

**Goal:** Full playthrough from ship start to Naer-Reth activation is possible.

**Scope:** TBD

**Dependencies:** M12

---

### M14 — Beta / External Testing

**Goal:** External testers can complete the game. Polish and bug-fix pass.

**Scope:** TBD

**Dependencies:** M13
