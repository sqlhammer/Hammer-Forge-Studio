# Milestone Roadmap

**Owner:** producer
**Status:** Draft
**Last Updated:** 2026-03-01 (M9 kicked off — Active)

> Tracks all project milestones, their completion status, and phase structure. Studio Head sets milestone goals and approves phase definitions; Producer maintains this document.

---

## Milestone Schema

| Field | Description |
|-------|-------------|
| Milestone | Name and short description |
| Target Date | Planned completion |
| Status | Planning / Active / QA / Complete |
| Phases | Named phases within this milestone (e.g., Foundation, Gameplay, QA) |
| Tickets | Count of total / open / done tickets in scope |
| QA Sign-off | Date QA Engineer signed off (required to close) |

---

## Milestones

| # | Milestone | Target Date | Status | Total | Open | Done | QA Sign-off |
|---|-----------|-------------|--------|-------|------|------|-------------|
| M0 | Studio Setup — Team infrastructure, ticket system, docs | 2026-02-20 | Complete | — | — | — | — |
| M1 | Core Game Architecture — Player controller, input system, view modes | 2026-02-21 | Complete | 7 | 0 | 7 | 2026-02-21 |
| M2 | 3D Asset Pipeline — PoC evaluation, pipeline SOP, M3-ready assets | 2026-02-22 | Complete | 10 | 0 | 10 | 2026-02-22 |
| M3 | First Playable — Minimal ship in world, scan/mine loop | — | Complete | 13 | 0 | 13 | 2026-02-23 |
| M4 | Ship Infrastructure — Ship globals, module system, Recycler, greybox interior | — | Complete | 21 | 0 | 21 | 2026-02-24 |
| M5 | Processing & Crafting — Smelting, components, tech tree, build/upgrade | — | Complete | 38 | 0 | 38 | 2026-02-25 |
| M6 | Icon Generation Pipeline — Icon PoC evaluation, style guides, full icon set | — | Complete | 23 | 0 | 23 | 2026-02-26 |
| M7 | Ship Interior — Cockpit, machine room, scene architecture overhaul | — | Complete | 39 | 0 | 39 | 2026-02-26 |
| M8 | Ship Navigation — Biome-to-biome travel, fuel system | — | Complete | 56 | 0 | 56 | 2026-03-01 |
| M9 | Foundation & Hardening — Canonical game launch architecture, orchestrator hardening, gamepad fixes, and M8 playtest polish | — | Active | 29 | 29 | 0 | — |
| M10 | Visual Asset Refinement — Polished art pass on existing assets | — | Planning | — | — | — | — |
| M11 | Movement & Usability Refinement — Game feel, controls, HUD/UX tuning | — | Planning | — | — | — | — |
| M12 | Content Expansion — Material resources, crafting recipes, tech tree depth | — | Planning | — | — | — | — |
| M13 | Biome Progression — Tier 1–3 biomes, escalating threats | — | Planning | — | — | — | — |
| M14 | Mega-Project Arc — Full tech tree, endgame sequence | — | Planning | — | — | — | — |
| M15 | Alpha — Full playthrough possible | — | Planning | — | — | — | — |
| M16 | Beta — External testing | — | Planning | — | — | — | — |

### Tooling Milestones

*Parallel-eligible infrastructure milestones. These do not block or depend on game milestones and use a separate T-series numbering convention.*

| # | Milestone | Target Date | Status | Total | Open | Done | QA Sign-off |
|---|-----------|-------------|--------|-------|------|------|-------------|
| T1 | Project Reporting Dashboard — GitHub Pages status site, auto-built on push | — | Planning | 10 | 10 | 0 | — |
| T2 | Usage & Cost Attribution — Orchestrator usage tracking, JSONL ledger, reporting | — | Active | 7 | 7 | 0 | — |
| T3 | Parallel Godot MCP — Per-agent headless Godot instances, remove file-based lock | — | Planning | — | — | — | — |
| T4 | Multi-Milestone Orchestrator — Instance directories, parallel conductor support | — | Complete | 9 | 0 | 9 | 2026-03-01 |

---

## Milestone Notes

### M0 — Studio Setup

**Goal:** Establish all team infrastructure so the studio can begin game development.

**Scope:**
- Agent CLAUDE.md files for all 14 agents
- Ticket system operational
- Docs directory structure in place
- Root README updated

**Phases:** N/A — M0 predates the Phase Gate model.

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

**Phases:** N/A — M1 predates the Phase Gate model.

**Tickets:** TICKET-0001 through TICKET-0007 (archived)

**Dependencies:** M0 (infrastructure must be in place)

**Closed:** 2026-02-21 — QA sign-off by qa-engineer

---

### M2 — 3D Asset Pipeline ✅

**Goal:** Establish the authoritative, repeatable 3D asset production pipeline through competitive PoC evaluation. Close with a documented SOP, completed art tech specs, and 4 game-ready assets for M3.

**Scope:**
- Asset briefs and PoC evaluation criteria (4 target assets: hand drill, player character, ship exterior, resource node)
- Blender Python PoC — produce all 4 assets using the existing programmatic pipeline
- AI generation PoC — tool selection and produce all 4 assets
- Evaluate results and produce a pipeline recommendation for Studio Head decision
- 3D pipeline SOP and completed art tech specs
- Final M3-ready production assets using the chosen pipeline
- QA import validation and pipeline reproducibility check

**Phases:** N/A — M2 predates the Phase Gate model.

**Tickets:** TICKET-0008 through TICKET-0014

**Dependencies:** M1 (player controller exists for scale reference and in-engine testing)

**Risks:**
- AI generation tools may produce poor topology requiring significant manual cleanup, undermining their speed advantage
- Blender Python pipeline may struggle with organic/character shapes (hand drill, player) versus mechanical geometry
- Pipeline decision may reveal a hybrid approach is needed, adding complexity to the SOP
- Art tech specs (poly budgets, texture budgets) are currently TBD — PoC results will inform them, but early M3 work may need to be revised

---

### M3 — First Playable ✅

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

**Phases:**
- **Foundation** (TICKET-0019–TICKET-0023): UI style guide, resource definitions, inventory/deposit/battery data layers
- **Gameplay** (TICKET-0024–TICKET-0028): Scanner, mining, HUD, inventory UI
- **Integration** (TICKET-0029): Greybox test world
- **QA** (TICKET-0030–TICKET-0031): Code review and full loop QA

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

**Closed:** 2026-02-23 — QA sign-off by qa-engineer (193/193 tests passing)

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

**Phases:**
- **Foundation** (TICKET-0039–TICKET-0042): Ship globals data layer, module system, Recycler data layer, UI/UX designs
- **Gameplay** (TICKET-0043–TICKET-0047): Greybox ship interior, module placement mechanic, Recycler UI, HUD, inventory sidebar
- **QA** (TICKET-0048–TICKET-0049): Code review and full loop QA

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

**Closed:** 2026-02-24 — QA sign-off by qa-engineer (284/284 tests passing). Studio Head approved.

---

### M5 — Processing & Crafting

**Goal:** Close the full core loop. Player can smelt raw materials, craft components, and build/upgrade ship systems from the tech tree.

**Scope:**
- Tech tree (minimal): Fabricator node (100 Metal to unlock), Automation Hub node (requires Fabricator)
- Fabricator ship module: new installable machine; produces Spare Battery and Head Lamp
- Fabricator 3D mesh: physical asset placed in greybox ship interior
- Mining minigame: trace lit lines on deposit for +50% yield bonus (D-002)
- Mining drones: Automation Hub module, drone programming UI, physical drones in world (D-009)
- Spare Battery: carriable consumable, restores suit battery in field (D-011)
- Head Lamp: permanent suit equipment, toggleable directional light, drains suit battery (new)
- Third-person scan/mine: full scan/mine loop parity in third-person camera mode (D-014)
- Ship machine SOP: reusable process doc for adding future ship machines

**Phases:**
- **Foundation** (TICKET-0060–TICKET-0067, TICKET-0081, TICKET-0083): Data layers, UI/UX designs, Fabricator 3D mesh, SOP, ship exterior rescale, phase gate regression test
- **Gameplay** (TICKET-0068–TICKET-0074, TICKET-0082, TICKET-0084): Tech tree UI, Fabricator panel, minigame, third-person scan/mine, drones, Spare Battery, Head Lamp, ship entry bugfix, phase gate regression test
- **Compliance** (TICKET-0077–TICKET-0080): DEC-0001 non-pause model remediation
- **QA** (TICKET-0075–TICKET-0076): Code review and full loop QA

**Tickets:** TICKET-0060 through TICKET-0082 (excluding archived gaps)

| Phase | Ticket | Title | Type | Owner |
|-------|--------|-------|------|-------|
| Foundation | TICKET-0060 | Tech tree — data layer | FEATURE | systems-programmer |
| Foundation | TICKET-0061 | Fabricator module — data layer and recipes | FEATURE | systems-programmer |
| Foundation | TICKET-0062 | Spare Battery — item data layer | FEATURE | systems-programmer |
| Foundation | TICKET-0063 | Head Lamp — item data layer | FEATURE | systems-programmer |
| Foundation | TICKET-0064 | Mining drone system — data layer and Automation Hub | FEATURE | systems-programmer |
| Foundation | TICKET-0065 | UI/UX — tech tree, Fabricator panel, minigame overlay, drone UI, third-person HUD | DESIGN | ui-ux-designer |
| Foundation | TICKET-0066 | Ship machine process flow — SOP | TASK | producer |
| Foundation | TICKET-0067 | Fabricator — 3D mesh and ship interior placement | TASK | technical-artist |
| Foundation | TICKET-0081 | Ship exterior — scale mesh to 3× current size | TASK | technical-artist |
| Foundation | TICKET-0083 | Foundation phase gate — regression test suite | TASK | qa-engineer |
| Gameplay | TICKET-0068 | Tech tree UI | FEATURE | gameplay-programmer |
| Gameplay | TICKET-0069 | Fabricator interaction panel UI | FEATURE | gameplay-programmer |
| Gameplay | TICKET-0070 | Mining minigame — line tracing for yield bonus | FEATURE | gameplay-programmer |
| Gameplay | TICKET-0071 | Third-person scan/mine gameplay | FEATURE | gameplay-programmer |
| Gameplay | TICKET-0072 | Automation Hub + drone system | FEATURE | gameplay-programmer |
| Gameplay | TICKET-0073 | Spare Battery — field carry and use mechanic | FEATURE | gameplay-programmer |
| Gameplay | TICKET-0074 | Head Lamp — toggle mechanic and visual | FEATURE | gameplay-programmer |
| Gameplay | TICKET-0082 | Bugfix — player blocked from entering ship when standing close to hull | BUGFIX | gameplay-programmer |
| Gameplay | TICKET-0084 | Gameplay phase gate — regression test suite | TASK | qa-engineer |
| Compliance | TICKET-0077 | Compliance — remove game pause from in-world UI panels | TASK | gameplay-programmer |
| Compliance | TICKET-0078 | Compliance — update UI wireframes and style guide for non-pause model | TASK | ui-ux-designer |
| Compliance | TICKET-0079 | Compliance — update input system design doc | TASK | systems-programmer |
| Compliance | TICKET-0080 | Compliance — update ship machine SOP | TASK | producer |
| QA | TICKET-0075 | Code review — M5 systems | REVIEW | systems-programmer |
| QA | TICKET-0076 | QA testing — M5 full loop | TASK | qa-engineer |

**Dependencies:** M4 (module system and Recycler establish the processing foundation)

---

### M6 — Icon Generation Pipeline

**Goal:** Establish the authoritative icon production pipeline through competitive PoC evaluation. Close with two approved icon style guides (item icons and HUD/functional icons), a documented production SOP, and a complete set of game-ready icons integrated into every applicable UI location.

**Scope:**
- Icon needs audit: catalog every UI location and icon slot in the game
- Asset folder structure: define permanent (`game/assets/icons/`), temp-test (`game/assets/icons/temp/`), and archive (`docs/art/icon-experiments/`) paths
- Generation method research: identify and select 3+ candidate tools/approaches with cost and human-effort analysis
- Icon evaluation criteria: adapted from M2 POC scoring framework; adds human effort and financial cost as weighted dimensions
- Item icon style guide: aesthetic brief, format, size constraints, mood for inventory/tech tree/machine panel icons (48×48px primary)
- HUD/functional icon style guide: aesthetic brief, format, size constraints for status/notification/compass icons (16–32px primary)
- Experiments A, B, C: each produces the **full icon set** (all items + all HUD icons, per both style guides) using one generation method; includes iteration logs and cost records
- Evaluation report: scores all methods against criteria; produces ranked recommendation
- Studio Head method approval (mid-milestone gate): Studio Head selects winning method before production begins
- Promote winning icons to permanent location; archive non-winning sets to `docs/art/icon-experiments/`
- Update UI style guide icon section: approved direction replaces current single-standard entry
- Integrate item icons into all game UI (inventory, tech tree, all machine panels, module catalog)
- Integrate HUD/functional icons into all HUD areas (battery, compass, ship globals, notifications, mining progress, tech tree status indicators)
- QA integration testing and Studio Head final sign-off

**Phases:**
- **Foundation** (TICKET-0086–TICKET-0091): Audit, folder structure, method research, eval criteria, two style guides
- **Experiments** (TICKET-0092–TICKET-0094): 3 full-set icon generation experiments
- **Evaluation & Selection** (TICKET-0095–TICKET-0096): Scoring, recommendation report, Studio Head method approval
- **Integration & QA** (TICKET-0097–TICKET-0102): Promote/archive, style guide update, game integration, code review, QA sign-off

**Tickets:** TICKET-0086 through TICKET-0102

| Phase | Ticket | Title | Type | Owner |
|-------|--------|-------|------|-------|
| Foundation | TICKET-0086 | Icon needs audit — catalog every icon location in the game | TASK | ui-ux-designer |
| Foundation | TICKET-0087 | Asset folder structure — define permanent, temp, and archive paths | TASK | producer |
| Foundation | TICKET-0088 | Generation method research — evaluate 3+ tools, select experiment finalists | RESEARCH | technical-artist |
| Foundation | TICKET-0089 | Icon evaluation criteria — adapt M2 POC framework for 2D icons | TASK | producer |
| Foundation | TICKET-0090 | Item icon style guide — aesthetic brief, format, size, mood | DESIGN | ui-ux-designer |
| Foundation | TICKET-0091 | HUD/functional icon style guide — aesthetic brief, format, size, mood | DESIGN | ui-ux-designer |
| Experiments | TICKET-0092 | Experiment A — [Method TBD]: full icon set, both style guides | TASK | technical-artist |
| Experiments | TICKET-0093 | Experiment B — [Method TBD]: full icon set, both style guides | TASK | technical-artist |
| Experiments | TICKET-0094 | Experiment C — [Method TBD]: full icon set, both style guides | TASK | technical-artist |
| Evaluation & Selection | TICKET-0095 | Evaluate experiments — score all methods, produce recommendation report | TASK | technical-artist |
| Evaluation & Selection | TICKET-0096 | Studio Head method approval — present recommendation, receive method selection | TASK | producer |
| Integration & QA | TICKET-0097 | Promote winning icons and archive experiments | TASK | technical-artist |
| Integration & QA | TICKET-0098 | Update UI style guide — replace icon section with approved direction | TASK | ui-ux-designer |
| Integration & QA | TICKET-0099 | Integrate item icons — inventory, tech tree, all machine panels | FEATURE | gameplay-programmer |
| Integration & QA | TICKET-0100 | Integrate HUD/functional icons — HUD, ship globals, notifications | FEATURE | gameplay-programmer |
| Integration & QA | TICKET-0101 | Code review — icon integration | REVIEW | systems-programmer |
| Integration & QA | TICKET-0102 | QA — icon integration and Studio Head final sign-off | TASK | qa-engineer |

**Studio Head touchpoints (milestone-specific, approved at kickoff):**
1. **Milestone Kickoff** — approves scope and phase definitions before agents begin work
2. **Method Approval** (Phase 3 gate) — reviews evaluation report and selects winning method; Phase 4 does not open without explicit approval
3. **Milestone QA Close** — grants final sign-off on TICKET-0102 icon integration test

**Dependencies:** M5 (provides the complete set of in-game systems, UI panels, and HUD elements whose icons are required)

**Closed:** 2026-02-26 — QA sign-off by qa-engineer (467/467 tests passing). Studio Head approved. 29 production icons integrated across all UI locations.

---

### M7 — Ship Interior + Scene Architecture Overhaul

**Goal:** The ship interior is fully realized with a distinct cockpit (console placeholder, diegetic ship status displays, exterior viewport) and a machine room with 4 module placement zones. All major game objects are refactored into standalone instanced scenes per coding standards.

**Scope:**
- Expanded ship interior (~24m × 12m): cockpit, machine room, connecting corridor, entry vestibule
- Cockpit: navigation console placeholder (for M8), wall-mounted diegetic ship status displays (Power, Integrity, Heat, O2), exterior viewport/window
- Machine room: 4 module placement zones (3 occupied by Recycler/Fabricator/Automation Hub, 1 spare)
- Scene architecture overhaul: 7 refactors extracting embedded game objects into standalone instanced scenes (ship exterior, resource deposits, ship machines, tools, carriable items, mining drone, UI panels/HUD)
- Interaction prompt HUD: contextual action hints and persistent controls panel
- Battery bar amber warning tier
- Still greybox (art pass is M9)

**Phases:**
- **Foundation** (TICKET-0123–TICKET-0124): Ship interior wireframes, cockpit console mesh
- **Refactoring** (TICKET-0111–TICKET-0117, TICKET-0125): 7 scene architecture refactors + regression test
- **Build & Features** (TICKET-0126–TICKET-0128, TICKET-0120, TICKET-0122): Ship interior scene, cockpit features, interaction prompt HUD, battery amber warning
- **QA** (TICKET-0129–TICKET-0130): Code review and full loop QA

**Tickets:** TICKET-0111 through TICKET-0117, TICKET-0120, TICKET-0122 through TICKET-0130

| Phase | Ticket | Title | Type | Owner |
|-------|--------|-------|------|-------|
| Foundation | TICKET-0123 | Ship interior wireframes — cockpit, machine room, corridors, vestibule, viewport | DESIGN | ui-ux-designer |
| Foundation | TICKET-0124 | Cockpit console — greybox 3D mesh placeholder | TASK | technical-artist |
| Refactoring | TICKET-0111 | Ship exterior → standalone instanced scene | REFACTOR | technical-artist |
| Refactoring | TICKET-0112 | Resource deposits → standalone instanced scenes | REFACTOR | gameplay-programmer |
| Refactoring | TICKET-0113 | Ship machines → standalone instanced scenes | REFACTOR | gameplay-programmer |
| Refactoring | TICKET-0114 | Tools (Hand Drill, Scanner) → standalone scenes | REFACTOR | gameplay-programmer |
| Refactoring | TICKET-0115 | Carriable items (Spare Battery, Head Lamp) → standalone scenes | REFACTOR | gameplay-programmer |
| Refactoring | TICKET-0116 | Mining drone → standalone instanced scene | REFACTOR | gameplay-programmer |
| Refactoring | TICKET-0117 | UI panels/HUD → standalone instanced subscenes | REFACTOR | gameplay-programmer |
| Refactoring | TICKET-0125 | Refactoring phase gate — regression test suite | TASK | qa-engineer |
| Build & Features | TICKET-0126 | Ship interior scene — 24m×12m layout, cockpit, machine room, 4 zones | FEATURE | gameplay-programmer |
| Build & Features | TICKET-0127 | Cockpit diegetic status displays — ship globals on wall | FEATURE | gameplay-programmer |
| Build & Features | TICKET-0128 | Cockpit exterior viewport/window | FEATURE | gameplay-programmer |
| Build & Features | TICKET-0120 | Interaction prompt HUD — contextual action hints | FEATURE | gameplay-programmer |
| Build & Features | TICKET-0122 | Battery bar amber warning tier | FEATURE | gameplay-programmer |
| QA | TICKET-0129 | Code review — M7 systems | REVIEW | systems-programmer |
| QA | TICKET-0130 | QA testing — M7 full loop | TASK | qa-engineer |

**Deferred items resolved by M7:** D-016, D-017, D-018, D-019, D-020, D-021, D-022, D-023, D-024

**Dependencies:** M6 (icon pipeline provides the complete icon set needed for refactored UI scenes)

**Notes:**
- M7 serves as a live proof-of-concept for the automated agent orchestration system. By this milestone, the full multi-agent pipeline (producer, gameplay-programmer, systems-programmer, ui-ux-designer, technical-artist, qa-engineer) has been operating across several milestones. M7 is an opportunity to evaluate whether the orchestration system is functioning as intended — ticket throughput, phase gate enforcement, agent handoffs, and cross-agent dependency management — and to identify any gaps before scaling further.

---

### M8 — Ship Navigation

**Goal:** Player can navigate the ship between biomes using an expanded navigation console (M7 placeholder). Travel consumes fuel based on distance and ship weight. All work follows a Red/Green Test-Driven Development pattern to ensure code quality and edge-case coverage across the navigation and fuel systems.

**Scope:**
- **Red/Green TDD Foundation (prerequisite to all other phases):** Establish TDD process guidelines, test infrastructure, and regression suite templates for M8
- Navigation system: biome map, waypoint selection, navigation console interface, travel initiation
- Fuel system: consumption tracking, fuel tank mechanics, distance/weight-based calculations, low-fuel warnings
- Travel sequence: transition animations, biome loading, player respawn at destination
- Greybox biome templates: 3 procedurally-laid out tier 1 biomes with distinct characteristics
- Cross-milestone stability: ensure all M7 tests continue passing

**Phases (Sequential):**
- **TDD Foundation** (TICKET-0131–TICKET-0132): Establish Red/Green TDD process, test infrastructure, regression suite template. **This phase must complete before any other M8 phase begins.**
- **Navigation & Fuel** (TBD): Navigation system, fuel consumption logic, travel mechanics
- **Integration** (TBD): Biome templates, travel sequences, console UI
- **QA** (TBD): Code review and full loop QA
- **Bug Fix** (TICKET-0245–TICKET-0246): Post-QA player-reported bugs — navigation console interaction prompt distance mismatch and panel overflow. Parallel-eligible with QA if QA has already passed; otherwise runs after QA gate.

**Tickets:** TICKET-0131–0132, TICKET-0149, TICKET-0153, TICKET-0157–0180, TICKET-0245–0246 (30 total)

| Phase | Ticket | Title | Type | Owner |
|-------|--------|-------|------|-------|
| TDD Foundation | TICKET-0131 | Establish Red/Green TDD process — guidelines and conventions for M8 | TASK | producer |
| TDD Foundation | TICKET-0132 | M8 test infrastructure — unified test suite and cross-milestone regression validation | TASK | qa-engineer |
| TDD Foundation | TICKET-0149 | Conductor — Godot MCP mutex: gate Godot editor access to one agent at a time | TASK | tools-devops-engineer |
| Foundation | TICKET-0157 | Cryonite — resource data layer and Fabricator Fuel Cell recipe | FEATURE | systems-programmer |
| Foundation | TICKET-0158 | Fuel system — tank data layer, consumption formula, low-fuel signal | FEATURE | systems-programmer |
| Foundation | TICKET-0159 | Navigation system — biome registry, travel state machine, fuel cost calculation | FEATURE | systems-programmer |
| Foundation | TICKET-0160 | Deep resource node — data layer, infinite-yield flag, slow drill rate | FEATURE | systems-programmer |
| Foundation | TICKET-0161 | Resource respawn system — biome-change trigger, surface node respawn logic | FEATURE | systems-programmer |
| Foundation | TICKET-0162 | Procedural terrain system — seed-based noise heightmap, biome archetype templates | FEATURE | gameplay-programmer |
| Foundation | TICKET-0163 | World boundary system — hard bounds, edge detection, boundary enforcement | FEATURE | gameplay-programmer |
| Foundation | TICKET-0164 | World boundary test harness — unit tests verifying boundary enforcement | TASK | qa-engineer |
| Foundation | TICKET-0165 | UI/UX — navigation console modal, biome map, fuel gauge HUD designs | DESIGN | ui-ux-designer |
| Foundation | TICKET-0166 | Foundation phase gate — regression test suite | TASK | qa-engineer |
| Foundation | TICKET-0179 | Cryonite deposit — greybox 3D mesh (pressurized rock formation) | TASK | technical-artist |
| Gameplay | TICKET-0153 | Mouse interaction support for inventory, machine builder, and tech tree menus | FEATURE | gameplay-programmer |
| Gameplay | TICKET-0167 | Navigation console UI — modal screen, biome selection, fuel cost, confirm travel | FEATURE | gameplay-programmer |
| Gameplay | TICKET-0168 | Travel sequence — transition animation, biome load, player respawn at destination | FEATURE | gameplay-programmer |
| Gameplay | TICKET-0169 | Fuel consumption HUD — low-fuel warning, tank gauge display | FEATURE | gameplay-programmer |
| Gameplay | TICKET-0170 | Shattered Flats biome — terrain, alien ruins, collapsed spire, resource placement | FEATURE | gameplay-programmer |
| Gameplay | TICKET-0171 | Rock Warrens biome — terrain, dense rock formations, corridors, resource placement | FEATURE | gameplay-programmer |
| Gameplay | TICKET-0172 | Debris Field biome — terrain, wreckage clusters, resource placement | FEATURE | gameplay-programmer |
| Gameplay | TICKET-0173 | Deep resource nodes — scene implementation, slow-yield behaviour, drone integration | FEATURE | gameplay-programmer |
| Gameplay | TICKET-0174 | Player jump — 50% player height, first-person and third-person | FEATURE | gameplay-programmer |
| Gameplay | TICKET-0175 | Headlamp — surface toggle action in interaction prompt HUD controls panel | FEATURE | gameplay-programmer |
| Gameplay | TICKET-0176 | Gameplay phase gate — regression test suite | TASK | qa-engineer |
| Gameplay | TICKET-0180 | Debug scene — biome spawn selector and begin-wealthy toggle | FEATURE | gameplay-programmer |
| QA | TICKET-0177 | Code review — M8 systems | REVIEW | systems-programmer |
| QA | TICKET-0178 | QA testing — M8 full loop | TASK | qa-engineer |
| Bug Fix | TICKET-0245 | BUG — Navigation console interaction prompt appears before player can interact | BUG | gameplay-programmer |
| Bug Fix | TICKET-0246 | BUG — Navigation console panel too tall; CONFIRM TRAVEL button cut off below viewport | BUG | gameplay-programmer |

**Dependencies:** M7 (must complete before M8 kickoff)

**Phase Gate Note:**
- **TDD Foundation Gate:** Must pass before any Navigation & Fuel phase work begins. Producer confirms: (1) TDD process guidelines approved by systems-programmer and qa-engineer, (2) test infrastructure operational and all M7/M6 tests still passing, (3) regression test templates created and runnable.
- All subsequent phase gates are **Red/Green validated:** every ticket in the phase must be test-first (RED tests written before code), passing code (GREEN), and refactored as needed.

**Notes:**
- M8 is the first milestone where TDD Foundation is established **before agent work begins**. M7 introduces TDD mid-milestone; M8 starts with TDD as day-one process.
- Cross-milestone test stability is critical — M8 expands the game world significantly (navigation, fuel, biomes). Test suite must ensure no regression in prior systems.
- Switch game window mode to **fullscreen windowed** (borderless window) — the game currently runs in a small windowed mode and should default to fullscreen windowed at startup.

---

### M9 — Foundation & Hardening

**Goal:** Establish the canonical game launch architecture, harden the orchestrator against usage-limit edge cases, resolve player-reported gamepad bugs, and incorporate M8 playtest polish. This milestone closes all deferred and backlogged work from M8 before the project enters visual and content expansion phases.

**Scope:** Fully scoped. 29 tickets across 5 phases.

**Phases:**
- **Root Game** (TICKET-0229–TICKET-0235, TICKET-0237): Game entry point architecture — root `game` scene, main menu, GameWorld, DebugLauncher refactor, TestWorld deprecation. **Must complete before Gameplay Polish and Orchestrator Resilience phases begin.** Introduces the canonical game launch flow: `game.tscn` routes to debug_launcher (debug builds) or main_menu (release); Play loads GameWorld using `Global.starting_biome` and `Global.starting_inventory`.
- **Orchestrator Resilience** (TICKET-0182–TICKET-0191): Conductor hardening for usage-limit edge cases — checkpoint system, LIMIT_WAIT cooldown, resume dispatch, structured logging, documentation. Parallel-eligible within this phase; depends on Root Game completing first. Touches only `orchestrator/` code and `docs/engineering/` — no game code changes.
- **Gamepad Bugs** (TICKET-0241–TICKET-0244): Player-reported gamepad issues — left stick Y-axis inversion, turn sensitivity, no interact button mapped, interaction prompt not switching to gamepad hints. Parallel-eligible with Root Game (touches only `InputManager.gd`, `player_first_person.gd`, and `interaction_prompt_hud.gd`; no dependency on Root Game architecture).
- **Code Quality** (TICKET-0258–TICKET-0261): M8 code review findings — section header mislabeling in biome data classes, DeepResourceNode adoption in biome scenes, move_and_slide() migration to `_physics_process()`, NavigationConsole null spy teardown. Parallel-eligible with Root Game; no dependency on Root Game architecture changes.
- **Gameplay Polish** (TICKET-0218–TICKET-0220): Inventory management features and debug tooling from M8 playtest feedback — drop items to ground, destroy items from inventory, debug 3× speed toggle. Depends on Root Game completing first (TICKET-0220 specifically depends on the DebugLauncher refactor in TICKET-0233).

**Tickets:** TICKET-0229–TICKET-0235, TICKET-0237 (Root Game); TICKET-0182–TICKET-0191 (Orchestrator Resilience); TICKET-0241–TICKET-0244 (Gamepad Bugs); TICKET-0258–TICKET-0261 (Code Quality); TICKET-0218–TICKET-0220 (Gameplay Polish).

| Phase | Ticket | Title | Type | Priority | Owner |
|-------|--------|-------|------|----------|-------|
| Root Game | TICKET-0229 | Add starting_biome and starting_inventory params to Global | TASK | P1 | systems-programmer |
| Root Game | TICKET-0230 | Create GameWorld scene — world-building extracted from DebugLauncher | TASK | P1 | gameplay-programmer |
| Root Game | TICKET-0237 | Design — Main Menu wireframe and layout spec | DESIGN | P1 | ui-ux-designer |
| Root Game | TICKET-0231 | Create Main Menu scene with Play button | TASK | P1 | gameplay-programmer |
| Root Game | TICKET-0232 | Create game root scene with debug-mode routing; set as project main scene | TASK | P1 | gameplay-programmer |
| Root Game | TICKET-0233 | Refactor DebugLauncher — set startup params, hand off to Main Menu | REFACTOR | P1 | gameplay-programmer |
| Root Game | TICKET-0234 | Deprecate TestWorld — remove files and update affected tests | TASK | P1 | qa-engineer |
| Root Game | TICKET-0235 | QA — write unit tests and validate full Root Game phase | QA | P1 | qa-engineer |
| Orchestrator Resilience | TICKET-0182 | Fix dead-lock on IN_PROGRESS pre-claim and add silent-success detection | BUG | P0 | tools-devops-engineer |
| Orchestrator Resilience | TICKET-0183 | Checkpoint system — write, read, and clear suspension checkpoints | FEATURE | P1 | tools-devops-engineer |
| Orchestrator Resilience | TICKET-0184 | Usage-limit detection and LIMIT_WAIT cooldown state | FEATURE | P1 | tools-devops-engineer |
| Orchestrator Resilience | TICKET-0185 | Resume dispatch with checkpoint context injection | FEATURE | P1 | tools-devops-engineer |
| Orchestrator Resilience | TICKET-0186 | UID commit idempotency — make _handle_uid_commits restartable | TASK | P2 | tools-devops-engineer |
| Orchestrator Resilience | TICKET-0187 | Structured suspension logging and gate deferral on unresolved checkpoints | FEATURE | P2 | tools-devops-engineer |
| Orchestrator Resilience | TICKET-0189 | Conductor-level gate detection fallback when Producer is unavailable | FEATURE | P2 | tools-devops-engineer |
| Orchestrator Resilience | TICKET-0190 | Auto-remediation for silently-merged PRs with IN_PROGRESS tickets | FEATURE | P3 | tools-devops-engineer |
| Orchestrator Resilience | TICKET-0191 | Log archive rotation at milestone close | TASK | P3 | tools-devops-engineer |
| Orchestrator Resilience | TICKET-0188 | Documentation — resilience runbook, CLAUDE.md updates, and config reference | TASK | P2 | producer |
| Gamepad Bugs | TICKET-0241 | BUG — Gamepad left stick Y-axis inverted (push down goes forward) | BUG | P1 | gameplay-programmer |
| Gamepad Bugs | TICKET-0242 | BUG — Gamepad right stick turn sensitivity too slow | BUG | P1 | gameplay-programmer |
| Gamepad Bugs | TICKET-0243 | BUG — Interaction prompt HUD does not switch to gamepad button hint | BUG | P2 | gameplay-programmer |
| Gamepad Bugs | TICKET-0244 | BUG — No gamepad button mapped to interact action | BUG | P0 | gameplay-programmer |
| Code Quality | TICKET-0258 | Fix section header mislabeling in M8 data classes | TASK | P3 | systems-programmer |
| Code Quality | TICKET-0259 | Use DeepResourceNode in biome scenes instead of Deposit.new(infinite=true) | TASK | P3 | systems-programmer |
| Code Quality | TICKET-0260 | Move PlayerFirstPerson move_and_slide() from _process() to _physics_process() | TASK | P3 | gameplay-programmer |
| Code Quality | TICKET-0261 | Fix NavigationConsole null spy reference in test after_each() | BUG | P3 | qa-engineer |
| Gameplay Polish | TICKET-0218 | Feature — Drop items from inventory onto the ground and pick them back up | FEATURE | P2 | gameplay-programmer |
| Gameplay Polish | TICKET-0219 | Feature — Destroy (discard) an item directly from inventory | FEATURE | P2 | gameplay-programmer |
| Gameplay Polish | TICKET-0220 | Feature — Debug launcher toggle for 3× player movement speed | FEATURE | P3 | gameplay-programmer |

**Dependency Graph (Root Game):**
```
TICKET-0229 (Global startup params)          TICKET-0237 (Main Menu design)
  ├─► TICKET-0230 (GameWorld scene)                 │
  │     └─► TICKET-0231 (Main Menu impl) ◄──────────┘ ◄── also depends on TICKET-0229, TICKET-0230
  │           └─► TICKET-0232 (game root scene + main scene)
  │                 ├─► TICKET-0233 (DebugLauncher refactor) ◄── also depends on TICKET-0229, TICKET-0231
  │                 │     └─► TICKET-0220 (Gameplay Polish — debug 3× speed toggle)
  │                 └─► TICKET-0234 (TestWorld deprecation) ◄── also depends on TICKET-0230, TICKET-0233
  │                       └─► TICKET-0235 (QA gate) ◄── depends on ALL above
```

**Dependency Graph (Code Quality):** No inter-ticket dependencies. All four tickets are independent and parallel-eligible with Root Game.

**Dependency Graph (Gameplay Polish):**
```
TICKET-0233 (DebugLauncher refactor — Root Game)
  └─► TICKET-0220 (debug 3× speed toggle)

TICKET-0218 (drop items) — no upstream dependencies
TICKET-0219 (destroy items) — no upstream dependencies
```

**Dependency Graph (Orchestrator Resilience):**
```
TICKET-0182 (P0 dead-lock fix)
  └─► TICKET-0183 (checkpoint system)
        ├─► TICKET-0185 (resume dispatch) ◄── also depends on TICKET-0182
        ├─► TICKET-0186 (UID idempotency)
        ├─► TICKET-0187 (suspension logging + gate deferral)
        │     └─► TICKET-0191 (log archive rotation)
        ├─► TICKET-0189 (conductor gate fallback)
        └─► TICKET-0190 (auto-remediation for merged PRs)

TICKET-0184 (usage-limit detection) — no dependencies, can run in parallel

TICKET-0188 (documentation) — depends on ALL of the above
```

**Design Reference:** `docs/engineering/orchestrator-resilience-plan.md` — full risk analysis, checkpoint schema, handling protocols, logging specification.

**Dependencies:** M8

---

### M10 — Visual Asset Refinement

**Goal:** Polished art pass on all existing game assets — terrain, ship interior, player character, resource nodes, and UI surfaces.

**Scope:** TBD — to be defined at M10 kickoff following M9 close.

**Phases:** To be defined at M10 kickoff — requires Studio Head approval before agents begin work.

**Dependencies:** M9

---

### M11 — Movement & Usability Refinement

**Goal:** Game feel, first-person controls, and HUD/UX tuning pass.

**Scope:** TBD — to be defined after M10 closes.

**Phases:** To be defined at M11 kickoff — requires Studio Head approval before agents begin work.

**Dependencies:** M10

---

### M12 — Content Expansion

**Goal:** Additional material resources, crafting recipes, and tech tree depth.

**Scope:** TBD — to be defined after M11 closes.

**Phases:** To be defined at M12 kickoff — requires Studio Head approval before agents begin work.

**Dependencies:** M11

---

### M13 — Biome Progression

**Goal:** Full Tier 1–3 biome progression with escalating threats and resource gates.

**Scope:** TBD — to be defined after M12 closes.

**Phases:** To be defined at M13 kickoff — requires Studio Head approval before agents begin work.

**Dependencies:** M12

---

### M14 — Mega-Project Arc

**Goal:** Complete tech tree and endgame sequence playable end-to-end.

**Scope:** TBD

**Phases:** To be defined at M14 kickoff — requires Studio Head approval before agents begin work.

**Dependencies:** M13

---

### M15 — Alpha

**Goal:** Full playthrough from ship start to Naer-Reth activation is possible.

**Scope:** TBD

**Phases:** To be defined at M15 kickoff — requires Studio Head approval before agents begin work.

**Dependencies:** M14

---

### M16 — Beta / External Testing

**Goal:** External testers can complete the game. Polish and bug-fix pass.

**Scope:** TBD

**Phases:** To be defined at M16 kickoff — requires Studio Head approval before agents begin work.

**Dependencies:** M15

---

## Tooling Milestone Notes

### T1 — Project Reporting Dashboard

**Goal:** A self-updating static dashboard deployed on GitHub Pages that visualizes milestone progress, ticket status, dependency graphs, and game system architecture — auto-rebuilt on every push to `main`.

**Scope:**
- Establish T-series milestone convention for tooling projects (parallel to M-series game milestones)
- Python build script: parses ticket YAML frontmatter and `milestones.md`, emits pre-baked JSON data files
- GitHub Actions workflow: triggers on push to `main`, runs build, deploys to GitHub Pages
- Static dashboard site: HTML/CSS/JS with Mermaid.js for automated diagram rendering
- Dashboard views: milestone overview (counts, completion %), per-milestone ticket tables, dependency graphs, phase gate status
- Auto-generated Mermaid diagrams from ticket dependency data and phase structure
- Hand-curated architecture and game loop diagrams maintained as Mermaid source files

**Phases:**
- **Foundation** (TICKET-0189–TICKET-0192): T-series convention support, data parser, CI/CD pipeline, site scaffold
- **Dashboard** (TICKET-0193–TICKET-0196): Milestone overview, ticket details, dependency graphs, architecture diagrams
- **QA** (TICKET-0197–TICKET-0198): Code review and testing

**Tickets:** TICKET-0189 through TICKET-0198 (10 total)

| Phase | Ticket | Title | Type | Owner |
|-------|--------|-------|------|-------|
| Foundation | TICKET-0189 | T-series milestone convention — orchestrator, docs, and process updates | TASK | tools-devops-engineer |
| Foundation | TICKET-0190 | Dashboard data parser — Python script to read tickets and milestones into JSON | FEATURE | systems-programmer |
| Foundation | TICKET-0191 | GitHub Actions workflow — build pipeline and GitHub Pages deployment | TASK | tools-devops-engineer |
| Foundation | TICKET-0192 | Dashboard site scaffold — HTML/CSS/JS structure with Mermaid.js | TASK | systems-programmer |
| Dashboard | TICKET-0193 | Milestone overview page — progress bars, ticket counts, phase gate status | FEATURE | systems-programmer |
| Dashboard | TICKET-0194 | Ticket detail views — per-milestone tables with status, owner, dependencies | FEATURE | systems-programmer |
| Dashboard | TICKET-0195 | Dependency graph diagrams — auto-generated Mermaid from ticket frontmatter | FEATURE | systems-programmer |
| Dashboard | TICKET-0196 | Architecture and game loop diagrams — curated Mermaid source files | TASK | producer |
| QA | TICKET-0197 | Code review — T1 systems | REVIEW | systems-programmer |
| QA | TICKET-0198 | QA testing — dashboard validation and sign-off | TASK | qa-engineer |

**Parallel-eligible:** T1 does not block and is not blocked by any game milestone. May begin at any time.

**Dependencies:** None (reads existing project files; benefits from data but does not require specific milestones to be complete)

**Notes:**
- T1 is the first tooling milestone. T-series milestones run parallel to the M-series game development milestones and use independent ticket numbering within the shared TICKET-NNNN sequence.
- The dashboard reads project files at build time — it does not require agents to manually update a separate data store. Data freshness matches commit cadence.
- Solution selected: Static Site + GitHub Actions Build Step (Solution B from the evaluation report). See the T1 evaluation report for alternatives considered.

---

### T2 — Usage & Cost Attribution

**Goal:** Track orchestrator usage and costs per agent, ticket, and milestone. Provide capacity utilization reporting against Claude plan limits so the studio can monitor burn rate and stay within rate limits.

**Scope:**
- Extract usage metadata (tokens, model, cost) from Claude CLI `--output-format json` output in conductor.py
- JSONL ledger (`orchestrator/usage.jsonl`) — append one record per CLI call with agent, ticket, milestone, phase, tokens, cost, timing
- Fix dead `total_cost_usd` accumulation in state.json
- Plan capacity configuration in `orchestrator/config.json` (Max 20 plan limits)
- Reporting script (`tools/usage_report.py`) — milestone summary, per-agent/ticket/phase breakdowns, capacity gauges (5-hour rolling, weekly rolling, per-session) with Opus 1.7x token weighting
- Backfill script (`tools/backfill_usage.py`) — reconstruct approximate usage records from existing orchestrator logs
- Code review and QA validation

**Phases:**
- **Foundation** (TICKET-0207–TICKET-0209): CLI output extraction, JSONL ledger, capacity config
- **Reporting** (TICKET-0210–TICKET-0211): Report script with capacity gauges, log backfill
- **QA** (TICKET-0212–TICKET-0213): Code review and end-to-end QA testing

**Tickets:** TICKET-0207 through TICKET-0213 (7 total)

| Phase | Ticket | Title | Type | Owner |
|-------|--------|-------|------|-------|
| Foundation | TICKET-0207 | Usage data extraction from Claude CLI output | FEATURE | tools-devops-engineer |
| Foundation | TICKET-0208 | Usage JSONL ledger and cost accumulation | FEATURE | tools-devops-engineer |
| Foundation | TICKET-0209 | Plan capacity configuration | FEATURE | tools-devops-engineer |
| Reporting | TICKET-0210 | Usage report script with capacity gauges | FEATURE | tools-devops-engineer |
| Reporting | TICKET-0211 | Usage data backfill from existing logs | FEATURE | tools-devops-engineer |
| QA | TICKET-0212 | Code review — T2 systems | REVIEW | systems-programmer |
| QA | TICKET-0213 | QA testing — T2 usage attribution | TASK | qa-engineer |

**Dependency Graph:**
```
TICKET-0207 (CLI extraction)
  └─► TICKET-0208 (JSONL ledger + cost accumulation)
        ├─► TICKET-0210 (report script) ◄── also depends on TICKET-0209
        └─► TICKET-0211 (backfill script)

TICKET-0209 (capacity config) — no dependencies, can run in parallel with 0207/0208
  └─► TICKET-0210 (report script)

TICKET-0212 (code review) — depends on ALL implementation tickets (0207–0211)
  └─► TICKET-0213 (QA testing)
```

**Parallel-eligible:** T2 does not block and is not blocked by any game milestone. May begin at any time.

**Dependencies:** None (operates on orchestrator internals; benefits from existing log data but does not require specific milestones)

**Notes:**
- T2 is informational/reporting only — it does not enforce rate limits or throttle the orchestrator. Capacity gauges are advisory.
- The JSONL ledger is gitignored (local data). The reporting and backfill scripts are committed.
- Opus 1.7x token weighting reflects Anthropic's rate limit accounting where Opus output tokens consume 1.7x the capacity of Sonnet/Haiku tokens.

---

### T4 — Multi-Milestone Orchestrator

**Goal:** Isolate each `conductor.py` run into its own instance directory so multiple milestone
orchestrators can run concurrently without file collisions. Add config layering so local overrides
don't require editing source-controlled files.

**Scope:**
- `orchestrator/instance_paths.py` — new shared utility module (path resolution + config loading)
- `conductor.py` — replace flat path constants with `resolve_instance()`; add `--instance` flag
- `status.py` — `--instance` / `--all` flags; auto-detect single instance
- `start_milestone.py` — write state to instance dir; print correct launch command
- `approve_gate.py` — read/write gate files from instance dir
- `resume_planning.py` — read/write state from instance dir
- `.gitignore` — add `instances/` and `config.local.json`; remove stale flat entries

**Phases:**
- **Foundation** (TICKET-0249–TICKET-0256): All implementation + QA in a single phase

**Tickets:** TICKET-0249 through TICKET-0256 (8 total)

| Phase | Ticket | Title | Type | Owner |
|-------|--------|-------|------|-------|
| Foundation | TICKET-0249 | Create instance_paths.py shared utility module | FEATURE | systems-programmer |
| Foundation | TICKET-0250 | Update conductor.py for instance-scoped paths + --instance flag | FEATURE | systems-programmer |
| Foundation | TICKET-0251 | Update status.py for --instance / --all flags | FEATURE | systems-programmer |
| Foundation | TICKET-0252 | Update start_milestone.py for instance directories | FEATURE | systems-programmer |
| Foundation | TICKET-0253 | Update approve_gate.py for --instance flag | FEATURE | systems-programmer |
| Foundation | TICKET-0254 | Update resume_planning.py for --instance flag | FEATURE | systems-programmer |
| Foundation | TICKET-0255 | Update .gitignore — add instances/, remove stale flat entries | TASK | systems-programmer |
| Foundation | TICKET-0256 | QA — integration test: two simultaneous instances + config override | TASK | qa-engineer |

**Dependency Graph:**
```
TICKET-0249 (instance_paths.py)
  ├─► TICKET-0250 (conductor.py)
  ├─► TICKET-0251 (status.py)
  ├─► TICKET-0252 (start_milestone.py)
  ├─► TICKET-0253 (approve_gate.py)
  └─► TICKET-0254 (resume_planning.py)

TICKET-0255 (.gitignore) — no code deps, can run any time

All of the above ──► TICKET-0256 (QA gate)
```

**Parallel-eligible:** T4 does not block and is not blocked by any game milestone.

**Dependencies:** None

---

## Appendix — Phase Gate Checklist

A Phase Gate fires when all tickets in a phase reach `DONE`. The Producer evaluates the following checklist. **All four conditions must be true for the gate to PASS.**

| Check | Condition |
|-------|-----------|
| ✅ Tickets | Every ticket in the phase has status `DONE` |
| ✅ Tests | Full test suite passes with zero failures |
| ✅ Cross-milestone | No parse errors or test-runner blockers affecting prior milestone test suites |
| ✅ Dependency graph | No ticket was set to `IN_PROGRESS` while any `depends_on` entry was non-DONE |

**On PASS:** Producer posts a Phase Gate Summary (`docs/studio/templates/phase-gate-summary.md`) and opens the next phase automatically. Studio Head is not notified.

**On FAIL:** Producer pages Studio Head immediately with the specific failure condition. Next phase does not open until Studio Head resolves or explicitly overrides the failure.

Phase Gate Summary reports are saved to `docs/studio/reports/` as `YYYY-MM-DD-[milestone]-[phase]-gate.md`.
