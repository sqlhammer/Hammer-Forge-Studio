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
| M2 | 3D Asset Pipeline — PoC evaluation, pipeline SOP, M3-ready assets | — | Active | 7 | 7 | 0 | — |
| M3 | First Playable — Minimal ship in world, scan/mine loop | — | Planning | — | — | — | — |
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

**Goal:** Player can exist in a minimal game world, exit the ship onto alien terrain, scan for a resource deposit, mine it, and return to the ship. First end-to-end pass of the core loop.

**Scope:** TBD — to be defined after M2 closes.

**Dependencies:** M2 (assets and pipeline required before world-building begins)

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
