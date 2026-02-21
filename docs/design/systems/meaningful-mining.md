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

## Scanner UX: Two-Phase Scanning

The scanner operates in two distinct phases. Each phase is a separate player action with a different input, range, and information output. The two phases are sequential — locate first, then analyze.

### Phase 1: Locate

**Goal:** Find where a specific resource type exists within scanner range.

**Input:** Hold [Locate key] to open a radial selection wheel. Move joystick or mouse to a resource type. Release the key to confirm selection and fire the ping.

**Behavior:**
- A ping expands outward rapidly from the player in all directions
- The ping detects all deposits of the selected resource type within the scanner's current range
- Each detected deposit registers a **direction + distance marker on the compass** (Satisfactory-style: directional arrow + proximity indicator)
- Multiple deposits produce multiple compass markers; the nearest is highlighted
- The player navigates toward a marker to close range for Phase 2

**Scanner tier interaction:**
- Low-tier scanner: shorter ping range; higher-tier deposits appear as noise (invisible, not detected)
- High-tier scanner: longer range; detects deeper and rarer deposit tiers

**Energy cost:** None. Phase 1 scanning does not consume suit battery.

**Gamepad note:** The radial wheel is designed for analog stick input first. Mouse support is equally valid. The wheel must be legible at TV viewing distance.

---

### Phase 2: Analyze

**Goal:** Assess a specific deposit before committing to extraction.

**Input:** Hold [Analyze button] while within close range of a deposit. Release when scan completes.

**Range:** Very short — requires the player to physically walk up to the deposit. This is intentional: analysis is a deliberate, committed action, not passive proximity data.

**Energy cost:** None. Phase 2 scanning does not consume suit battery.

**Scan duration:** [TBD — game-designer next pass; target feel: 2–3 seconds of held input]

**Output on scan completion:**
- **Purity rating:** 1–5 stars (see Resource Purity System below)
- **Quantity density:** Low / Medium / High — intentionally generalized, not an exact number
- **Energy cost:** Total energy required to fully mine this deposit
- **Mining pattern lines:** 1–4 curved or straight lines illuminate on the resource geometry
  - Fewer lines = lower-tier deposit (simpler pattern; tutorial-appropriate)
  - More lines = higher-tier deposit (harder pattern; higher potential bonus)

---

### Mining Minigame: Line Tracing

After Phase 2 analysis reveals the mining pattern, the player may begin standard extraction immediately — or attempt the minigame for a bonus.

**Mechanic:** Trace the lit lines on the resource with the mining laser before the extraction operation completes.

**Reward:** Successfully tracing all lines yields a bonus resource quantity:
- Baseline bonus: **+50%** of base yield
- Actual bonus varies by resource type (different materials have different multipliers) and pattern difficulty (more complex patterns have higher ceilings)

**Failure:** Missing lines or running out of time yields the base quantity only. No penalty beyond forgoing the bonus. The player is never blocked.

**Automation interaction:** Mining drones do not perform the minigame. Drone extraction always yields base quantity. This preserves the value of manual play even when automation is available — skilled manual miners always outperform their drones on a per-deposit basis.

---

## Resource Purity System

### Core Rule

Every deposit has a **Purity Rating** (1–5 stars). Purity is not just a quality label — it has direct mechanical consequences:

```
Crafting Energy Cost = Base Cost × (1 / Purity Modifier)

Purity Modifier:
  ★☆☆☆☆  (1-star)  → 0.60  (67% more expensive to craft from)
  ★★☆☆☆  (2-star)  → 0.80  (25% more expensive to craft from)
  ★★★☆☆  (3-star)  → 1.00  (baseline)
  ★★★★☆  (4-star)  → 1.25  (20% cheaper to craft from)
  ★★★★★  (5-star)  → 1.60  (37.5% cheaper to craft from — significant advantage)
```

High-purity deposits are rarer, found deeper, and require better tools to reach. Finding a 5-star vein is a meaningful event — worth navigating to, worth defending.

### Purity Distribution

- **Tier 1 biomes (low-threat):** Mostly 1–3 star deposits; rare 4-star
- **Tier 2 biomes (medium-threat):** Mostly 2–4 star; 5-star possible but uncommon
- **Tier 3 biomes (high-threat):** 3–5 star; 5-star deposits are the incentive to risk this zone
- **Tier 4 biomes (Mega-Project zones):** Unique rare materials only found here; purity is fixed (always 5-star, by design)

---

## Deposit Tiers and Required Tools

Deposits are tiered by **depth and density**. Each tier requires a specific extraction tool. Using the wrong tool does nothing — the deposit cannot be touched until the player has the correct tool tier.

| Deposit Tier | Description | Required Tool | Notes |
|---|---|---|---|
| **Tier 1** | Surface or near-surface; soft rock | Hand Drill | Available from game start |
| **Tier 2** | Medium depth; harder composite rock | Pneumatic Drill | Crafted in early game |
| **Tier 3** | Deep sub-surface; dense mineral veins | Thermal Drill | Mid-game craft; requires refined alloys |
| **Tier 4** | Extreme depth or exotic material | Plasma Cutter / Resonance Bore | Late-game craft; rare components |

### Tool Energy

Tools consume **suit battery charge** to operate. They have no durability — a tool does not degrade or break. Once crafted, it works indefinitely as long as the player has charge available.

Higher-tier tools draw more energy per operation. The player manages field time around suit battery capacity:
- Return to ship to recharge
- Carry spare batteries for extended operations away from the ship

**Battery depletion penalty:** When suit battery reaches 0%, the player's movement speed is reduced by **25%**. The player is never immobilized — they can always walk back to the ship. Scanning remains fully functional at 0% battery; only tool use is affected (tools simply won't fire with no charge available).

The Phase 2 Analysis "Energy cost" output is the suit battery drain for a full extraction of that deposit — giving the player the information to decide if they have enough charge to commit, or need to return to the ship first. See "Suit Battery" in `docs/design/systems/player-suit.md` [→ spec TBD].

Drone programs must still specify which tool tier to deploy — the correct tool rule applies to automated extraction identically to manual play. Drone energy consumption is drawn from the ship's power supply, not the player's suit battery.

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

### Scanner-First Constraint

**A drone cannot be assigned to a deposit the player has not personally analyzed.**

Before a deposit can appear as an assignable target in a drone program, the player must have completed Phase 2 Analysis on that specific deposit. The drone executes the player's recorded data — it does not scout or scan on its own.

This means:
- A player who has analyzed 10 deposits has 10 possible drone targets
- A player who hasn't scanned cannot delegate
- Expanding the drone program's pool of targets requires the player to keep going out and scanning

The scanner remains the primary skill expression even in the automation phase.

### Drone Programming

Players do not "set and forget." They **configure drone programs** against their pool of analyzed deposits:
- Target deposit type (e.g., "only Tier 2 iron, minimum 3-star purity")
- Tool assignment (drone carries the specified tool tier)
- Extraction radius (how far from the ship the drone will travel)
- Priority order (if multiple valid analyzed deposits match, which to hit first)

A well-configured drone program reflects the player's scanning thoroughness. A player who has analyzed more deposits — and selected high-purity, high-density targets — gets meaningfully better output than one who scanned minimally.

### Drone Limits

- Number of simultaneous active drones: [TBD — tied to Automation Hub tier]
- Drones are physical entities present in the world — the player can observe them operating
- Drones cannot enter Tier 3+ threat zones unprotected (defense modules required)
- Drones do not perform the mining minigame — automated extraction always yields base quantity

---

## Open Items

- Drone count per Automation Hub tier [→ game-designer, next pass]
- Drone implementation details: physical form, deployment model, operating radius, resource logistics, destruction/replacement, lore origin [→ OQ-018, game-designer next pass]
- Phase 2 scan duration (target feel: 2–3 seconds; needs playtesting to finalize) [→ game-designer, next pass]
- Mining minigame bonus multiplier per resource type [→ game-designer, next pass; baseline +50% is confirmed]
**Resolved:**
- Specific biome types, names, and resource palettes → See `docs/design/systems/biomes.md` and OQ-016
- Scanner UI design and HUD overlay spec → Documented above; see OQ-017
- Whether purity affects material quantity yielded → Purity affects crafting cost only (OQ-009)
- Tool energy model → Tools consume suit battery; no durability; spare batteries carriable (inventory slots); recharge at ship (fast); see OQ-021 and `docs/design/systems/player-suit.md`
- Drone core architecture → Physical drones; scanner-first constraint (Phase 2 Analysis required before assignment); see OQ-018
