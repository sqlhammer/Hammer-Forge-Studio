# Product Requirements Document

**Owner:** producer
**Status:** Draft
**Last Updated:** 2026-02-25

> This document defines the product — what we are building, who we are building it for, and what success looks like. It is distinct from the GDD (which defines *how* the game plays). Agents should reference the GDD for gameplay specifications; this document provides the business and product context.

---

## Product Vision

A single-sentence statement of what this product is:

> **The Inheritance** — A high-fidelity, single-player sci-fi survival game for PC where the player pilots a living atmospheric ship across the dying alien world of Aur, building toward activating the Naer-Reth — a planetary restoration machine that will save the world and consume the player — as the sole narrative and mechanical goal.

---

## Market Context

### The 2026 Survival Landscape

The survival genre is undergoing a "Great Refinement." Players are rejecting "survival slop" — tedious loops without purpose — in favor of **high-context survival**, where every action feeds a narrative or a persistent greater goal.

**The identified market gap:** No major title offers a *nomadic, single-player, high-fidelity, sci-fi survival experience* where the base itself moves and every destination is purposeful. The closest competitors all fail in specific ways:

| Competitor | What They Do Well | Where They Fail |
|---|---|---|
| The Last Caretaker | High narrative stakes; energy-based survival | Narrow base modularity; rigid progression |
| Dune: Awakening | World-class oppressive atmosphere; visual fidelity | Forced PvP/social drift in late-game; alienates solo players |
| RuneScape: Dragonwilds | "Craft from storage" QoL; impactful skill trees | High-fantasy aesthetic; lacks sci-fi grit |
| Icarus / Raft | Strong session-based progression loops | Static base boredom; no "why" once the base is built |
| Green Hell / Survival: FoY | High-stakes environmental immersion; diegetic UI | Tedious busywork; lack of mid-to-late game automation |

### Our Position

We occupy the **"Blue Ocean"** intersection of:
- Single-player only (not forced co-op or PvP)
- Mobile base (atmospheric ship — not static base building)
- Sci-fi setting (not fantasy, not pure survival horror)
- Scanner-first meaningful mechanics (not "click on rock" loops)
- Automation as progression reward (not gated forever)

---

## Target Platform

**Primary:** PC (Windows) via Steam
**Secondary:** [TBD — console ports, Mac/Linux support — see open-questions.md]

**Launch:** PC (Windows/Steam primary; Linux/Mac via Godot export)
**Post-launch:** Console (PS5 / Xbox Series X) — planned port, not speculative

**Critical constraint: Gamepad is a first-class citizen from day one.** The scanner mechanic, ship navigation, module building, and all UI must be designed to work fully with a controller. Gamepad support is not a post-launch addition — it is a launch requirement that shapes system design from the start.

**Visual style:** Stylized sci-fi (distinct visual identity — reference: Outer Wilds, Hades). Low-to-mid PC hardware target.

**Minimum Spec Target:** GTX 970 / RX 480 or equivalent (TBD — pending rendering pipeline decisions)
**Recommended Spec Target:** GTX 1070 / RX 5700 or equivalent (TBD)

---

## Target Audience

### Primary Persona: "The Efficient Architect"

| Attribute | Description |
|---|---|
| **Age range** | Late 20s to early 40s |
| **Gaming background** | Experienced; likely plays 10–20 hours/week across multiple genres |
| **Preferred play session** | 2–4 hour focused sessions; not casual mobile-style play |
| **Primary frustration** | "Inventory Tetris" and walking back and forth between chests; busywork without reward |
| **Primary desire** | Automation as progression. Wants to mine manually early, but expects drone/auto-smelter by mid-game |
| **Relationship to narrative** | Wants a "why." Story purpose amplifies mechanical engagement. |
| **Relationship to multiplayer** | Does not want forced co-op or PvP. Plays solo by choice, not by limitation. |
| **AI Influence** | Expects in-game AI/drone units to handle menial tasks so they can focus on high-level decisions |

### Secondary Audience

- **Lapsed survival game players** who quit previous titles due to late-game aimlessness
- **Sci-fi fans** underserved by the survival genre's fantasy/horror dominance
- **Strategy-adjacent players** who appreciate meaningful resource management and build optimization

### Audience We Are NOT Targeting

- Multiplayer/co-op survival players (Valheim, Rust, Ark)
- Battle Royale survival audiences
- Mobile/casual survival audiences
- Players seeking permadeath roguelite survival (separate genre)

---

## Competitive Differentiation

### Why Players Will Choose Us Over Alternatives

1. **Tactical Solitude** — The only high-fidelity sci-fi survival title that is *proudly* single-player only. No social features, no lobbies, no asymmetric co-op bolted on. This is a deliberate design choice marketed as a feature.

2. **The Ship Lives** — The atmospheric ship is not a house you build and forget. It has Power, Integrity, Heat, and Oxygen. It can die. It demands care while it enables ambition.

3. **Purposeful Destination** — The Mega-Project gives the game a defined, visible end. Players know what they're building toward from day one. No mid-game aimlessness.

4. **Scanner Discipline** — Mining is a skill, not a chore. The scanner-first mechanic rewards geological knowledge. Players feel smart, not tired.

5. **Automation as Arc** — Drones and auto-smelters are not cheats. They are the reward for mastering the early game. The player graduates from manual labor to systemic architect.

---

## Monetization Model

**Premium one-time purchase. No DLC. No live service.**

The game is complete on release. Single purchase price [TBD — $40–$50 range]. No expansions, no cosmetic store, no battle pass, no seasonal content.

This is a deliberate brand decision aligned with the "Tactical Solitude" positioning. The Efficient Architect persona distrusts ongoing monetization and is more likely to purchase a product they perceive as complete and respectful of their time.

---

## Success Metrics

**TBD — targets to be set by Studio Head**

Placeholder framework (values TBD):

| Metric | Target | Notes |
|---|---|---|
| Steam Wishlist (pre-launch) | [TBD] | Key signal for organic interest |
| First-week units sold | [TBD] | Primary commercial milestone |
| Steam Review Score (90 days post-launch) | ≥ 80% Positive | "Mostly Positive" or better |
| Average playtime (Steam, 2 weeks post-launch) | ≥ [TBD] hours | Signals mid-game retention |
| Completion rate (players who finish Mega-Project) | ≥ [TBD]% | Signals endgame arc health |
| Refund rate | ≤ 5% | Core satisfaction indicator |

---

## Out of Scope

The following are explicitly **not** being built and should not be scoped into any ticket:

| Feature | Reason Excluded |
|---|---|
| Multiplayer / Co-op | Conflicts with "Tactical Solitude" brand; adds sync complexity; reduces graphical ceiling |
| PvP of any kind | Alienates the core solo audience; see Dune: Awakening's failure point |
| Mobile platform | Mechanic complexity (scanner, build system) not viable on mobile |
| Live service / seasonal content | Not aligned with premium solo-first model |
| Procedurally generated story | Narrative requires authorial control for emotional impact |
| User-generated content / modding tools | Deferred; not in initial scope |

---

## Release Goals

*Last updated: 2026-03-01. See `docs/studio/milestones.md` for the authoritative milestone roadmap; this table is a product-level summary kept in sync at each milestone close.*

| Milestone | Status | QA Sign-off | Description |
|---|---|---|---|
| M0 | **Complete** | — | Studio setup, documentation, agent configuration |
| M1 | **Complete** | 2026-02-21 | Core game architecture: player controller, input system, view modes |
| M2 | **Complete** | 2026-02-22 | 3D asset pipeline: PoC evaluation, pipeline SOP, M3-ready assets |
| M3 | **Complete** | 2026-02-23 | First playable: minimal ship in world, scan/mine loop |
| M4 | **Complete** | 2026-02-24 | Ship infrastructure: ship globals, module system, Recycler, greybox interior |
| M5 | **Complete** | 2026-02-25 | Processing & Crafting: smelting, components, tech tree, build/upgrade |
| M6 | **Complete** | 2026-02-26 | Icon Generation Pipeline: icon PoC evaluation, style guides, full icon set |
| M7 | **Complete** | 2026-02-26 | Ship Interior: cockpit, machine room, scene architecture overhaul |
| M8 | **Complete** | 2026-03-01 | Ship Navigation: biome-to-biome travel, fuel system |
| M9 | Planning | — | Foundation & Hardening: canonical game launch architecture, orchestrator hardening, gamepad fixes, and M8 playtest polish |
| M10 | Planning | — | Visual Asset Refinement: polished art pass on existing assets |
| M11 | Planning | — | Movement & Usability Refinement: game feel, controls, HUD/UX tuning |
| M12 | Planning | — | Content Expansion: material resources, crafting recipes, tech tree depth |
| M13 | Planning | — | Biome Progression: Tier 1–3 biomes, escalating threats |
| M14 | Planning | — | Mega-Project Arc: full tech tree, endgame sequence |
| M15 | Planning | — | Alpha: full playthrough possible |
| M16 | Planning | — | Beta: external testing |
| Launch | TBD | — | Steam release |

### Tooling Milestones

*Parallel-eligible infrastructure milestones. These do not block or depend on game milestones.*

| Milestone | Status | QA Sign-off | Description |
|---|---|---|---|
| T1 | Planning | — | Project Reporting Dashboard: GitHub Pages status site, auto-built on push |
| T2 | **Complete** | 2026-03-01 | Usage & Cost Attribution: orchestrator usage tracking, JSONL ledger, capacity reporting |
| T3 | Planning | — | Parallel Godot MCP: per-agent headless Godot instances, remove file-based lock |
| T4 | **Complete** | 2026-03-01 | Multi-Milestone Orchestrator: instance directories, parallel conductor support |

---

## Open Items

See `docs/design/open-questions.md` for all unresolved product decisions.
