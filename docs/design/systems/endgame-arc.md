# System Spec: Endgame Arc ("The Moses Factor")

**Owner:** game-designer
**Status:** Draft
**Last Updated:** 2026-02-21

> This spec defines the Mega-Project and the Second Cycle — the two-layered endgame structure that gives the game its long-term purpose, its dark twist, and its true resolution. Any agent implementing endgame systems must read this document in full.

---

## Design Intent

**The Problem with Survival Games:** Players build a base, automate resources, and then ask: *"Now what?"* The mid-to-late game collapses because there is no compelling answer.

**Our Answer — The Moses Factor:** From the very beginning of the game, the player knows what they are building toward. The Mega-Project is not a twist or a late-game reveal — it is the *premise*. Every tech tree node, every high-threat zone, every 5-star purity vein exists in service of this singular, civilization-scale objective.

Named internally as "The Moses Factor" — after the archetype of a leader who works their entire life toward a promised destination they are driven to reach.

**The Second Layer:** The game has two endings. The first is a tragedy the player cannot prevent on their first run. The second is the true ending — earned only by players who carry the knowledge of their death into a harder second attempt. This is not a hidden ending in the traditional sense. It is a *sequel to understanding*.

---

## The Mega-Project: The Naer-Reth

**Objective:** Activate **the Naer-Reth** ("The Chrysalis") — a planetary-scale machine built by the Serev, distributed as an activation node network across Aur's biomes. The Naer-Reth was designed to restore Aur's dying ecological systems.

**What the player believes it does:** Ecological revival. Restore Aur. Make it livable again.

**What it actually does:** The Naer-Reth is an energy drain of civilization-scale magnitude. It draws from every available power source on Aur during and after activation — geological, technological, and biological. The Serev were consumed as fuel during its first partial activation. That is what destroyed them. The player will be consumed too. So will Rel.

**Aur does revive.** The ecology restores. The Naer-Reth succeeds at its stated purpose. What it costs is everything on the surface. The player's "win" is real — and it is also their death.

---

## First Cycle: The Tragedy

### Tech Tree Architecture

The tech tree is structured with two distinct phases:

```
Phase 1 — Breadth (Early/Mid Game)
  ├─ Mining tools (Tier 1 → Tier 4)
  ├─ Ship modules (Power, Propulsion, Thermal, Life Support, etc.)
  ├─ Automation (Drones, Auto-Smelters)
  ├─ Survival systems (Integrity repair, Oxygen management)
  └─ Multiple valid paths — player chooses their playstyle

Phase 2 — Convergence (Late Game: Final 20% of nodes)
  └─ World-Engine Branch
       ├─ WE Node Component 1 (Tier 3 rare material)
       ├─ WE Node Component 2 (Tier 3 rare material)
       ├─ WE Node Component 3 (Tier 4 Extreme rare material)
       ├─ WE Node Component 4 (Tier 4 Extreme rare material)
       ├─ WE Assembly Step 1
       ├─ WE Assembly Step 2
       └─ WORLD-ENGINE ACTIVATION → First Cycle End
```

### The Convergence Trigger

When the player unlocks the Naer-Reth Branch:
- A narrative event triggers — the AI companion locates the Naer-Reth's central node coordinates
- The objective log updates: World-Engine activation is now the sole goal
- The world map highlights Tier 3 and Tier 4 zones with World-Engine component indicators
- New threat types are introduced in those zones

### Rare Materials (World-Engine Components)

All World-Engine node components require rare materials found **only** in high-threat biomes.

| WE Component | Required Rare Material | Source Biome Tier |
|---|---|---|
| Node Component 1 | [TBD — Serev rare material name] | Tier 3 |
| Node Component 2 | [TBD — Serev rare material name] | Tier 3 |
| Node Component 3 | [TBD — Serev rare material name] | Tier 4 (Extreme) |
| Node Component 4 | [TBD — Serev rare material name] | Tier 4 (Extreme) |

### Rare Material Design Principles
1. **One unique material per component** — no substitutions
2. **Abundant within their zone** — the challenge is reaching the zone, not finding the material once there
3. **Purity applies** — 5-star rare material reduces Naer-Reth crafting cost significantly
4. **Non-fungible** — cannot be synthesized or worked around

### Progress Visibility

Naer-Reth progress is visible as **physical construction changes at the central node site** — a fixed-location structure on Aur's surface that the player visits between activation phases. Seeing it grow is the reward.

Each assembly step triggers a narrative event: a log entry, a change in Rel's behavior, a visual transformation at the node site.

### First Cycle Win State

When the Naer-Reth activates:
- A final narrative sequence plays (not skippable on first completion)
- The sequence shows: Aur's atmosphere changing, the ecology responding, the ship's systems failing as the drain begins, Rel's final words
- The player's stats (playtime, ship configuration, nodes activated) are shown
- The credit sequence: centuries later, Aur from orbit, alive and green. Another vessel approaches.
- The Second Cycle prompt appears.

---

## Second Cycle: The True Ending

### The Concept

A player who completes the First Cycle carries one thing into their next run: **they know what the Naer-Reth does.**

In the Second Cycle, a previously hidden branch of the late game becomes accessible. The player builds **the Regulator** — a parallel device, in parallel with the standard Naer-Reth activation — that interfaces with the Naer-Reth's node network and limits its energy draw to geological and solar sources only, excluding biological energy. The cycle is broken. Aur lives. So does the player.

The Regulator is the first truly original act in this world — something the Serev never built. The Serev knew it could exist. They left instructions. The player was always the intended recipient.

### Access Condition

The Second Cycle branch is **only accessible after completing the First Cycle**. It is gated by a persistent save flag — not by a skill check, not by a dialogue choice. The player had to die to know this was possible.

In the Second Cycle, data fragments that were flavor text in Run 1 are now legible as instructions. Rel can translate what it previously could not. The world did not hide the truth. The player simply did not know what they were looking at.

### The Second Cycle Exclusive Rare Material: "The Record"

The Regulator requires a unique rare material not found through conventional scanning. The Serev encoded its location across **data fragments distributed throughout all of Aur's biomes** — fragments that appeared as lore in Run 1 but are now readable as coordinates.

**Key narrative beat:**
> Rel: *"I can translate this now. I couldn't before. They wrote down where to find it. They wrote it down because they knew someone might need to fix what they built. Someone who had already failed once."*

**Design rule:** The material is distributed across multiple biome tiers, requiring the player to revisit zones from all three threat tiers with their now-full-game-knowledge ship. This creates a retrospective tour of the whole game — the player who has died revisiting everywhere they've been, finding what was always there.

The material's in-universe name: [TBD — to be named by narrative-designer, should evoke "what was left for you" or "the message in the ruins"]

### What "Fixing" the Naer-Reth Requires

**Total resource requirement: 2× the base Naer-Reth activation cost.**

This is not arbitrary difficulty. The Regulator is harder to build because:
- It runs **in parallel** with the Naer-Reth activation — the player must complete both tracks simultaneously
- It requires components from **all biome tiers** (not just Tier 3–4 as in Run 1)
- It requires the Second Cycle exclusive rare material (encoded in the Serev's data fragments)
- The assembly sequence is more complex — more steps, tighter tolerances

### Second Cycle Tech Tree

```
Phase 1 — Same as First Cycle (breadth)

Phase 2 — Convergence: Naer-Reth Branch (same as First Cycle)
  └─ Naer-Reth Branch
       └─ [Same 4 node components as First Cycle]

Phase 3 — The Regulator Branch (NEW — Second Cycle only, runs in parallel)
  └─ The Regulator
       ├─ Regulator Component A (Tier 1 + Tier 2 combined materials)
       ├─ Regulator Component B (Tier 2 + Tier 3 combined materials)
       ├─ Regulator Component C (Tier 3 + Tier 4 combined materials)
       ├─ Regulator Component D (Second Cycle exclusive rare material — "The Record")
       ├─ Interface Assembly (requires both Naer-Reth AND Regulator complete)
       └─ INTERFACE ACTIVATION → True Ending
```

### True Ending Win State

When the Regulator interfaces with the Naer-Reth:
- The activation sequence begins — same visual language as the First Cycle ending
- The drain begins — then stops. The Regulator is working.
- Rel experiences the suppressed memory fully. It understands, finally and completely, what it was part of, what it almost guided the player to repeat, and what has now been changed.
- Aur revives. The ship survives. The player lives.
- A final sequence: Aur from the surface. Growing things. The atmospheric ship, still intact. Rel's artifact, resting in the green that is growing. Credits.

The True Ending is earned, not given. It is harder than the tragedy. That is intentional.

---

## Threat Escalation in Late Game

When the player enters Tier 3 and Tier 4 biomes:
- **New enemy types** capable of targeting specific ship systems (not just hull damage)
- **Environmental hazards** requiring upgraded Thermal and Life Support modules
- **World-Engine proximity effects** — the closer to the central node, the more the planet's dying systems destabilize

In the Second Cycle, Tier 4 zones also include **echo events** — environmental traces of the First Cycle activation that the player may recognize. These are optional narrative content, not mechanical gates.

---

## Open Items

- Rare material names and world-specific identities [→ OQ-013 + OQ-012]
- Second Cycle exclusive rare material location and identity [→ OQ-015]
- Specific implementation of Second Cycle Regulator mechanic [→ OQ-015]
- AI companion final words in First Cycle ending [→ narrative-designer]
- AI companion "full memory" moment in True Ending [→ narrative-designer]
- Physical visualization of World-Engine node construction [→ environment-artist, technical-artist]
- Second Cycle "echo events" design [→ narrative-designer, game-designer next pass]
- NPC factions / enemy entity types in high-threat zones [→ OQ-010]
