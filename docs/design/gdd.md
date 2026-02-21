# Game Design Document

**Owner:** game-designer
**Status:** Draft
**Last Updated:** 2026-02-21

> This document is the canonical reference for all gameplay systems. No feature ticket should be created without a corresponding section here being approved by the Studio Head.

---

## Game Overview

**Title:** The Inheritance
**Genre:** Single-player open-world sci-fi survival (crafting, mining, base building)
**Platform:** PC (Windows/Steam primary; Linux/Mac via Godot export). Console post-launch (PS5 / Xbox Series X). Gamepad is a first-class citizen from day one — all systems must be designed for controller. See `docs/studio/prd.md`.
**Engine:** Godot 4.5
**Visual Format:** 3D
**Target Audience:** "The Efficient Architect" — tech-savvy players (late 20s–40s) who demand purposeful progression and reward automation over busywork. Solo players who value deep immersion over social gameplay.

**Setting:** The dying planet Aur. The Serev rose here, built a planetary-scale machine — the Naer-Reth — to save themselves, and were consumed by it. The player — a human researcher who arrived in cryo-sleep to study the Serev — wakes up to find them already gone. Only Rel remains. Only the Naer-Reth waits to be finished. See `docs/narrative/narrative-bible.md` for the full world overview.

**Core Fantasy:** You are alone on Aur. A voice — Rel — speaks to you through a recovered artifact. The Serev's ruins stretch in every direction. Something enormous was being built here — and it was never turned on. You will turn it on. You will not know, until the end, what that means.

**Elevator Pitch:** A high-fidelity, single-player sci-fi survival game where your base is a living atmospheric ship navigating the dying alien world of Aur. You mine, build, and automate your way toward reactivating the Naer-Reth — a planetary machine that promises to restore the world. It will. The player will not survive to see it.

---

## Core Pillars

### 1. Nomadic Survival
The ship moves. Every destination is purposeful, not arbitrary. Players are always navigating *toward* something — a resource deposit, a threat zone, the next Mega-Project milestone. Settling in place is never the goal.

### 2. Scanner-First Exploration
You discover before you act. Sub-surface deposits are identified with a scanner, then extracted with the correct tool. Knowledge is the first resource. Blind harvesting is inefficient by design.

### 3. Automation as Reward
The early game is manual and hands-on. The mid-game rewards players with mining drones and auto-smelters. By late game, the ship runs complex systems autonomously while the player focuses on high-level decisions. Automation is never given — it is earned through the tech tree.

### 4. Living Ship
The atmospheric ship is not a static base — it is a character with its own survival needs. Power, Integrity, Heat, and Oxygen are global variables that must be managed. Every module added has a cost (weight, power draw). Every journey consumes fuel. The ship can die.

### 5. Tactical Solitude
This is a single-player-only experience by design. No forced co-op, no PvP, no social drift. This allows for higher graphical fidelity, more complex AI enemy behaviors, and a deeper narrative investment than multiplayer formats permit. "Deep Immersion" and "Tactical Solitude" are the marketing differentiators.

---

## Core Game Loop

```
SCAN
  └─ Identify sub-surface deposit type and purity with scanner
     └─ MINE
          └─ Extract with correct tool (purity tier determines which tool)
               └─ PROCESS
                    └─ Smelt / refine / craft components
                         └─ BUILD / UPGRADE
                              └─ Expand ship modules or unlock tech tree nodes
                                   └─ NAVIGATE
                                        └─ Pilot ship to next biome or objective zone
                                             └─ Back to SCAN (at escalating scale)
                                                  └─ [Late game] → MEGA-PROJECT MILESTONE
```

**What does the player do?** Explore, scan, extract, craft, build, navigate.
**What do they get?** Resources, ship upgrades, automation tools, new biome access, Mega-Project progress.
**What do they spend?** Time, fuel, ship integrity, power budget, and risk exposure in high-threat zones.

---

## Systems Index

Detailed system specifications live in `docs/design/systems/`. Each spec defines variables, rules, edge cases, and agent implementation guidance.

| System | Spec File | Status |
|---|---|---|
| Input System | [`docs/design/systems/input-system.md`](systems/input-system.md) | In Review |
| Mobile Base (Atmospheric Ship) | [`docs/design/systems/mobile-base.md`](systems/mobile-base.md) | Draft |
| Meaningful Mining | [`docs/design/systems/meaningful-mining.md`](systems/meaningful-mining.md) | Draft |
| Biomes | [`docs/design/systems/biomes.md`](systems/biomes.md) | Draft |
| Player Suit | [`docs/design/systems/player-suit.md`](systems/player-suit.md) | Draft |
| Endgame Arc (The Moses Factor) | [`docs/design/systems/endgame-arc.md`](systems/endgame-arc.md) | Draft |

---

## Win / Loss Conditions

### Win (First Cycle — "The Tragedy")
The player "wins" by completing **the Naer-Reth activation** — a civilization-scale Mega-Project distributed as a node network across the world's biomes.

Activating the Naer-Reth restores the planet's ecology. It also drains all available energy from the planet — including the player, the ship, and the AI companion. The player does not escape. The credit sequence shows the planet, restored and alive, centuries later. Another vessel approaches.

This is the only outcome of the First Cycle. The player cannot avoid it. They can only understand it before or after it happens.

### Win (Second Cycle — "The True Ending")
A player who completes the First Cycle and begins a New Game Plus run carries **the knowledge of what the Naer-Reth actually does**. With this meta-knowledge, a previously hidden path becomes available in the late game: modifying the Naer-Reth to prevent the destruction cycle.

This Second Cycle true ending requires **2× the total resources** of the standard activation and is significantly harder to achieve. It is the game's actual resolution — the cycle broken. Details in `docs/design/systems/endgame-arc.md`.

### Loss (Ship Destruction)
The player loses if **ship Integrity reaches zero**. The ship is destroyed.

**Partial persistence:** Tech tree progress and all schematics (the player's knowledge) survive. Resources, ship modules, cargo, and fuel are lost. The player is a researcher — their knowledge is their character. They rebuild from a stripped ship with everything they know intact. See `docs/design/systems/mobile-base.md` for the full fail state spec.

### No Loss by Attrition
Starvation or "survival busywork" is not a loss condition. The game does not punish players for pausing exploration. Scarcity is tied to *progress gates*, not *survival timers*.

---

## Progression

### Early Game — "The Foundation"
- Manual resource extraction (hand tools, basic scanner)
- Ship starts small: minimal modules, low fuel capacity, restricted to low-threat biomes
- Focus: learn the scanner-mining loop, build first automation components
- Gate: first automation component (mining drone or auto-smelter) unlocks mid-game

### Mid Game — "The Expansion"
- Automation tools eliminate manual busywork for basic resources
- Player focuses on higher-tier deposits in medium-threat biomes
- Ship grows: new module types, better power management, faster navigation
- Focus: optimize the ship, explore, stockpile for the late game
- Gate: tech tree node that unlocks the Mega-Project branch

### Late Game — "The Reckoning"
- Final 20% of the tech tree: Mega-Project nodes only
- High-threat biomes become required — rare materials gated behind hostile zones
- Ship must be fully optimized to survive these zones
- Focus: execute the Mega-Project sequence; no new exploration goals remain
- Gate: Mega-Project completion = win

### Tech Tree Structure
- Broad and flexible in early/mid game (player chooses their path)
- Converges toward a single Mega-Project "spine" in the late game
- No dead-end nodes — every node either enables automation, improves survivability, or contributes to the Mega-Project

---

## Open Questions

See `docs/design/open-questions.md` for unresolved design decisions.
