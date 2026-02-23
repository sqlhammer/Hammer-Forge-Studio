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
| M4 | Ship Systems — Navigation, global variables, module system | — | Planning | — | — | — | — |
| M5 | Biome Progression — Tier 1–3 biomes, escalating threats | — | Planning | — | — | — | — |
| M6 | Mega-Project Arc — Full tech tree, endgame sequence | — | Planning | — | — | — | — |
| M7 | Alpha — Full playthrough possible | — | Planning | — | — | — | — |
| M8 | Beta — External testing | — | Planning | — | — | — | — |

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

### M4 — Ship Systems

**Goal:** The ship is a living entity. Player can navigate the ship across the world map, manage global variables (Power, Integrity, Heat, Oxygen), and install at least one module type.

**Scope:** TBD — to be defined after M3 closes.

**Dependencies:** M3 (first playable world required as the environment ship navigates)

---

### M5 — Biome Progression

**Goal:** Full Tier 1–3 biome progression with escalating threats and resource gates.

**Scope:** TBD

**Dependencies:** M4

---

### M6 — Mega-Project Arc

**Goal:** Complete tech tree and endgame sequence playable end-to-end.

**Scope:** TBD

**Dependencies:** M5

---

### M7 — Alpha

**Goal:** Full playthrough from ship start to Naer-Reth activation is possible.

**Scope:** TBD

**Dependencies:** M6

---

### M8 — Beta / External Testing

**Goal:** External testers can complete the game. Polish and bug-fix pass.

**Scope:** TBD

**Dependencies:** M7
