# Project Glossary

**Owner:** technical-writer
**Status:** Draft
**Last Updated:** 2026-02-20

> Alphabetically sorted definitions for all game terms, technical terms, and studio terminology. Any agent producing player-visible text must use terms as defined here.

---

## Format

**Term** *(domain)*
Definition. Cross-references: [related term](#term).

---

## A

**Aur** *(game / world)*
The planet where The Inheritance takes place. Named by the Serev for "light / warmth / what sustains you." A record of what the world once was. Aur is dying — the Serev's ecological crisis was never reversed before they were consumed by the Naer-Reth. See `docs/narrative/narrative-bible.md`.

**Atmospheric Ship** *(game)*
The player's mobile base. A living, pilotable vessel that traverses the open world biome-by-biome. Has four Global Variables (Power, Integrity, Heat, Oxygen) that must be actively managed. The ship is built from Modules. See `docs/design/systems/mobile-base.md`.

**Automation Tier** *(game)*
A progression phase unlocked in the mid-game when the player crafts their first automation tool (mining drone or auto-smelter). Represents the transition from manual resource extraction to systemic management. See `docs/design/systems/meaningful-mining.md`.

## B

**BLOCKER** *(studio)*
A ticket type used when an agent cannot proceed on their work due to an external dependency. See `tickets/README.md` for protocol.

**Biome** *(game)*
A distinct geographic zone of the open world with its own environmental conditions, threat level (Tier 1–4), resource palette, and hazards. The Atmospheric Ship navigates between biomes. Higher-tier biomes contain rarer resources required for the Mega-Project.

## C

## D

**Deposit** *(game)*
A sub-surface concentration of a specific resource material. Deposits are not visible to the naked eye — they must be detected using the Scanner. Each deposit has a Tier (1–4) determining the required extraction tool, and a Purity Rating (1–5 stars) affecting crafting efficiency. See `docs/design/systems/meaningful-mining.md`.

**Deposit Chain** *(game)*
A lateral extension of a single Deposit through the sub-surface. Detectable only with a Tier 4 (Spectral) Scanner. Exploiting a full chain requires repositioning the ship or deploying drones across a wider area.

## E

**The Efficient Architect** *(product)*
The primary target player persona. Tech-savvy, solo player in their late 20s–40s who demands purposeful progression and rewards automation over busywork. Primary frustration: inventory management and repetitive tasks with no payoff. Primary desire: automation as a progression milestone. See `docs/studio/prd.md`.

**EventBus** *(engineering)*
The global autoload singleton through which all cross-system signals are routed. Agents must not call methods on other autoloads directly — use EventBus signals instead.

## F

**Fuel** *(game)*
A crafted resource (not found raw; must be refined from raw materials) consumed by the Atmospheric Ship during navigation between Biomes. Fuel consumption scales with ship weight. See `docs/design/systems/mobile-base.md`.

## G

**Global Variables** *(game)*
The four survival metrics that define the Atmospheric Ship's health state: **Power** (electrical output), **Integrity** (hull structural health), **Heat** (internal temperature), and **Oxygen** (atmospheric viability). If Integrity reaches 0%, the ship is destroyed (Game Over). See `docs/design/systems/mobile-base.md`.

## H

**Hammer Forge Studio** *(studio)*
The name of the game development studio and its primary project repository.

## I

**Integrity** *(game)*
One of the four Global Variables. Represents the structural health of the Atmospheric Ship's hull, measured 0–100%. Degraded by environmental hazards, enemy attacks, and failed navigation events. Reaches 0% → Game Over. Repaired using crafted materials. Cross-reference: [Global Variables](#global-variables).

## J

## K

## L

**Living Ship** *(game / design pillar)*
The design principle that the Atmospheric Ship is not a static base but a character with survival needs (Power, Integrity, Heat, Oxygen). One of the five Core Pillars. See `docs/design/gdd.md`.

## M

**Mega-Project** *(game)*
The civilization-scale objective that serves as the game's win condition: activation of the Naer-Reth. Requires rare materials found only in Tier 3–4 Biomes and tech tree nodes in the final 20% of the tree. Internally called "The Moses Factor." See [Naer-Reth](#naer-reth) and `docs/design/systems/endgame-arc.md`.

**Milestone** *(studio)*
A named phase of development with a defined scope and target date. See `docs/studio/milestones.md`.

## N

**Naer-Reth** *(game / world)*
The Serev's name for the World-Engine — the planetary-scale ecological restoration machine distributed as a node network across Aur. Translated by Rel as "The Chrysalis." Naer: emergence (the moment a contained form is no longer contained). Reth: the lowest structural layer, the foundation everything is built on. The Naer-Reth was designed to restore Aur's dying ecology. It does. It also draws energy from all available sources on Aur — including living things. The Serev were consumed. So is the player. See `docs/design/systems/endgame-arc.md` and `docs/narrative/narrative-bible.md`.

**Nomadic Survival** *(game / design pillar)*
The design pillar that distinguishes this game from static-base survival games. The Atmospheric Ship moves; every destination is purposeful. Settling permanently in place is never the goal. One of the five Core Pillars. See `docs/design/gdd.md`.

## O

**Open Question** *(studio)*
An unresolved design decision tracked in `docs/design/open-questions.md`. Each entry includes the question, impact on blocked work, candidate options, and status. High-priority open questions block multiple downstream systems.

**Oxygen** *(game)*
One of the four Global Variables. Represents atmospheric viability inside the Atmospheric Ship, measured 0–100%. Degraded by hull breaches and certain biome hazards. Maintained by O2 Recycler modules. Cross-reference: [Global Variables](#global-variables).

## P

**Power** *(game)*
One of the four Global Variables. Represents total electrical output from Power Generation modules minus the draw from all active modules, measured 0–100%. If Power reaches 0% and remains there, critical systems fail. Cross-reference: [Global Variables](#global-variables).

**Producer** *(studio)*
The agent responsible for managing the ticket backlog, sprint planning, and blocker resolution. Entry point for all work routing.

## Q

**QA Sign-off** *(studio)*
Written confirmation from the QA Engineer that all P0 and P1 bugs are resolved and the regression checklist has been executed. Required before a milestone closes.

## R

**Rel** *(game / character)*
The player's AI companion in The Inheritance. A fragment of the Serev's distributed intelligence, housed in a recovered artifact — a physical terminal or device found in Act 1. Rel speaks in translated approximations and carries suppressed memories it cannot fully access. Its tragedy: it guides the player toward the Naer-Reth's activation without being able to know what that means. Short name; heard constantly; neither fully alien nor fully human. See `docs/narrative/narrative-bible.md`.

**Resource Purity** *(game)*
A rating (1–5 stars) assigned to each Deposit that affects crafting efficiency. Higher purity = lower crafting energy cost. 5-star deposits reduce crafting cost by 60% vs. baseline. Purity is detectable only with a Tier 3+ Scanner. See `docs/design/systems/meaningful-mining.md`.

## S

**The Serev** *(game / world)*
The extinct alien civilization whose ruins cover Aur. Built the Naer-Reth to address a planetary ecological crisis of their own making. Began activation. Were consumed by the Naer-Reth's energy draw. Are gone. Known to the player through ruins, data fragments, and Rel's fragmented recollections. Never seen. Felt. See `docs/narrative/narrative-bible.md`.

**Second Cycle** *(game)*
The New Game Plus run of The Inheritance, unlocked after completing the First Cycle. The player carries meta-knowledge of the Naer-Reth's true nature into a second playthrough and can attempt to modify it (build the Regulator) to prevent the destruction cycle. Requires 2× the total resources of the First Cycle and is significantly harder. Leads to the True Ending. See `docs/design/systems/endgame-arc.md`.

**Scanner** *(game)*
The player's primary exploration tool in first-person mode. Reads sub-surface geological data and outputs deposit type, estimated purity, depth, and required extraction tool. Must be used before mining; "click on rock without scanning" is not a valid game pattern. Upgraded via the Scanner Array ship module. See `docs/design/systems/meaningful-mining.md`.

**Scanner-First** *(game / design pillar)*
The design principle that players discover before they act. Sub-surface deposits are identified with the Scanner before extraction begins. One of the five Core Pillars. See `docs/design/gdd.md`.

**Sub-surface Deposit** *(game)*
See [Deposit](#deposit).

**Studio Head** *(studio)*
The human executive (Derik Hammer) who sets creative direction, approves milestones, and resolves escalated decisions.

## T

**Tactical Solitude** *(game / design pillar)*
The design pillar and marketing differentiator that defines this as a single-player-only experience. No multiplayer, co-op, or PvP — by deliberate design, not limitation. Enables higher graphical fidelity and more complex AI behaviors than multiplayer formats permit. One of the five Core Pillars. See `docs/design/gdd.md` and `docs/studio/prd.md`.

**The Moses Factor** *(design)*
Internal shorthand for the Mega-Project endgame arc. Named after the archetype of a leader who works their entire life toward a promised destination. Refers to the design philosophy that the game's end goal is visible from the start, giving every action a sense of purpose. See [Mega-Project](#mega-project).

**Ticket** *(studio)*
A markdown file in `tickets/` representing a unit of work. See `tickets/README.md` for schema and types.

## U

## V

## W

## X

## Y

## Z
