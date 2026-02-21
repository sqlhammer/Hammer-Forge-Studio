# System Spec: Meaningful Mining

**Owner:** game-designer
**Status:** Draft
**Last Updated:** 2026-02-21

> This spec defines the scanner-first resource extraction system. The core design law: *players discover before they act.* "Clicking on a rock" is not a valid game action. Every extraction decision is informed by scanner data.

---

## Design Intent

The 2026 survival market is saturated with mindless "click on rock, get iron" loops. This system replaces that pattern with a **geology discipline**: scan the environment, interpret the data, select the correct tool, and then extract. Skill comes from reading the world, not from clicking faster.

Automation in the mid-game does not eliminate this skill — it delegates it. The player designs drone programs that embody their scanner knowledge. A good player's drones are smarter than a bad player's manual mining.

---

## The Scanner

### How It Works

The scanner is the player's primary exploration tool in first-person mode. It reads sub-surface geological data and surfaces it as a visual overlay in the player's HUD.

- **Default range:** [TBD — tied to Scanner Array module tier]
- **Output:** Deposit type, estimated purity, depth, required extraction tool
- **Scan time:** 2–3 seconds of active scanning before results display (prevents spam-scanning)
- **False negatives:** Low-tier scanners cannot detect Tier 3+ deposits — they appear as noise. Upgrading the Scanner Array reveals deeper deposits.

### Scanner Upgrades (via Scanner Array module)

| Scanner Tier | Max Deposit Tier Detectable | Range | Notes |
|---|---|---|---|
| 1 (Basic) | Tier 1 | Short | Surface and near-surface only |
| 2 (Enhanced) | Tier 2 | Medium | Reveals depth and orientation data |
| 3 (Deep-Array) | Tier 3 | Long | Reveals purity rating |
| 4 (Spectral) | Tier 4 (rare) | Long | Reveals purity + adjacent deposit chains |

---

## Resource Purity System

### Core Rule

Every deposit has a **Purity Rating** (1–5 stars). Purity is not just a quality label — it has direct mechanical consequences:

```
Crafting Energy Cost = Base Cost × (1 / Purity Modifier)

Purity Modifier:
  ★☆☆☆☆  (1-star)  → 0.60  (40% more expensive to craft from)
  ★★☆☆☆  (2-star)  → 0.80
  ★★★☆☆  (3-star)  → 1.00  (baseline)
  ★★★★☆  (4-star)  → 1.25  (25% cheaper to craft from)
  ★★★★★  (5-star)  → 1.60  (60% cheaper to craft from — significant advantage)
```

High-purity deposits are rarer, found deeper, and require better tools to reach. Finding a 5-star vein is a meaningful event — worth navigating to, worth defending.

### Purity Distribution

- **Tier 1 biomes (low-threat):** Mostly 1–3 star deposits; rare 4-star
- **Tier 2 biomes (medium-threat):** Mostly 2–4 star; 5-star possible but uncommon
- **Tier 3 biomes (high-threat):** 3–5 star; 5-star deposits are the incentive to risk this zone
- **Tier 4 biomes (Mega-Project zones):** Unique rare materials only found here; purity is fixed (always 5-star, by design)

---

## Deposit Tiers and Required Tools

Deposits are tiered by **depth and density**. Each tier requires a specific extraction tool. Using the wrong tool either does nothing or wastes durability.

| Deposit Tier | Description | Required Tool | Notes |
|---|---|---|---|
| **Tier 1** | Surface or near-surface; soft rock | Hand Drill | Available from game start |
| **Tier 2** | Medium depth; harder composite rock | Pneumatic Drill | Crafted in early game |
| **Tier 3** | Deep sub-surface; dense mineral veins | Thermal Drill | Mid-game craft; requires refined alloys |
| **Tier 4** | Extreme depth or exotic material | Plasma Cutter / Resonance Bore | Late-game craft; rare components |

### Tool Durability

- Tools degrade with use and must be repaired or replaced
- Higher-tier tools degrade faster when used on lower-tier deposits (wrong tool is wasteful)
- Auto-smelter and mining drones use the same tool-tier rules — drone programs must specify which tool tier to deploy

---

## Procedural Deposit Distribution

### Generation Rules

- Deposits are procedurally placed at world generation, not hand-crafted
- Biome type determines the **resource type palette** (what minerals appear)
- Biome threat tier determines the **purity and depth distribution**
- No two worlds are identical, but the meta-rules ensure strategic balance

### Resource Type Palette (biome examples — world-specific types TBD)

| Biome Type | Primary Resource | Secondary Resource | Rare Resource |
|---|---|---|---|
| [Biome A — TBD] | [TBD] | [TBD] | [TBD] |
| [Biome B — TBD] | [TBD] | [TBD] | [TBD] |
| [Mega-Project Zone] | Unique rare material (Mega-Project component) | — | — |

> Note: Specific biome names, types, and resource palettes are TBD pending world/setting decisions. See `docs/design/open-questions.md`.

### Deposit Chains

- High-tier scanners can detect **adjacent deposit chains** — veins that extend laterally through the sub-surface
- Exploiting a full chain requires repositioning the ship (or deploying drones)
- Chains incentivize staying in one zone longer vs. always moving on

---

## Automation: Mining Drones

### Mid-Game Unlock

Mining drones are unlocked via the tech tree (Automation Hub module required). They execute scanner-informed extraction autonomously.

### Drone Programming

Players do not "set and forget." They **configure drone programs**:
- Target deposit type (e.g., "only Tier 2 iron, minimum 3-star purity")
- Tool assignment (drone carries the specified tool tier)
- Extraction radius (how far from the ship the drone will travel)
- Priority order (if multiple valid deposits, which to hit first)

A well-configured drone program reflects the player's knowledge of the local geology. A poorly configured program wastes tool durability or misses high-purity veins.

### Drone Limits

- Number of simultaneous active drones: [TBD — tied to Automation Hub tier]
- Drones do not replace the scanner — the player still scans to *inform* drone programs
- Drones cannot enter Tier 3+ threat zones unprotected (defense modules required)

---

## Open Items

- Specific biome types, names, and resource palettes [→ pending world/setting — open-questions.md]
- Scanner UI design and HUD overlay spec [→ ui-ux-designer]
- Tool durability values and repair costs [→ game-designer, next pass]
- Drone count per Automation Hub tier [→ game-designer, next pass]
- Whether purity affects material quantity yielded (in addition to crafting cost) [→ open-questions.md]
