# System Spec: Biomes

**Owner:** game-designer
**Status:** Draft
**Last Updated:** 2026-02-21

> This spec defines the biome system architecture and catalogs all designed biomes. The system is built for extensibility — the first biome ships at launch; additional biomes are registered without architectural changes.

---

## Design Intent

Biomes are the fundamental unit of world structure in *The Inheritance*. Each biome:

- Defines a **threat tier** (1–4) that controls enemy density, danger level, and accessible resource purity
- Provides a **resource palette** — the specific materials found here and in what proportions
- Has a **visual identity** that is immediately readable (player knows what tier they're in at a glance)
- Is **procedurally placed** at world generation using meta-rules that guarantee strategic balance

Biomes are not randomly scattered. They are zonally structured: low-threat biomes are accessible from the start; high-threat biomes require ship upgrades and better gear to enter and survive.

---

## Biome Architecture

### Threat Tiers

| Tier | Threat Level | Player Access | Detectable Deposit Tier | Purity Range |
|---|---|---|---|---|
| 1 | Low | Early game; starting area | Tier 1 | 1–3 star (rare 4-star) |
| 2 | Medium | Mid-game; requires hull upgrade | Tier 1–2 | 2–4 star; 5-star rare |
| 3 | High | Late game; requires combat modules | Tier 1–3 | 3–5 star |
| 4 | Extreme | Mega-Project zones | Unique rare materials only | Fixed 5-star |

### Resource Palette Structure

Every biome defines:

- **Primary resource:** Most common deposit type; low-purity sources abundant
- **Secondary resource:** Moderate presence; mixed purity distribution
- **Rare resource:** Uncommon; found in deep deposits or specific terrain features
- **Surface collectibles:** Visible without scanning; walk-up pickup or harvest — no mining required

### World Generation Rules

- Biome type determines the resource type palette (what can appear here)
- Biome threat tier determines purity and depth distribution (how good those deposits are)
- No two worlds are identical, but meta-rules guarantee that all required Mega-Project materials appear somewhere in the world
- Biome boundaries blend gradually — edge zones have mixed threat characteristics

---

## Biome Catalog

### B001 — Overgrown Suburbs

**Threat Tier:** 1 (Low)
**Visual Identity:** Rolling hills with sparse, dying alien foliage. Scattered debris from Serev technology and the ruins of a small residential settlement. Muted earth tones with flashes of oxidized metal and cracked synthetic material.
**Atmosphere:** Quiet. Eerie in its ordinariness — this is where the Serev lived. Now it's empty. The ruins are domestic in scale, which makes the silence feel heavier.

#### Enemies

- Very few hostile NPCs; designed as a safe learning zone
- Automated Serev defense remnants, if any, are disabled or barely functional
- No significant combat threat in the core zone

#### Resources

| Resource | Type | Collection Method | Use |
|---|---|---|---|
| Scrap Metal (fragments) | Surface collectible | Walk-up pickup | Basic crafting, early-game components |
| Scrap Metal (embedded) | Tier 1 deposit | Phase 1 scan → Phase 2 analyze → Hand Drill | Higher quantity; same crafting use |
| Organic Matter | Surface collectible | Walk-up harvest from plant-life | Fuel (low efficiency) |

**Scrap Metal — Fragments**

- Scattered visibly across terrain and atop/around debris piles; no scanner required to see
- Small amounts per pickup; rewards thorough exploration of the ruins
- Phase 1 scanner ping highlights nearby fragment clusters when "Scrap Metal" is selected
- Purity: not applicable (pre-processed fragments); uniform crafting cost regardless of source

**Scrap Metal — Embedded**

- Larger quantities lodged within debris structures and collapsed Serev architecture
- Requires Phase 1 scan to locate, Phase 2 scan to analyze before extraction
- Requires Hand Drill (Tier 1 tool) to extract
- Purity rating: 1–3 star; a 3-star find in this biome is a good result
- Mining minigame: 1–2 lines (simple pattern; tutorial-appropriate difficulty)

**Organic Matter**

- Harvested from alien plant-life clusters; visible without scanner
- Phase 1 scanner ping highlights the nearest organic matter cluster when selected
- No drill required; hand harvest action only
- Very low energy density as fuel — burns fast, produces little power
- Purity: not applicable; all organic matter is functionally identical

#### Design Notes

- This biome serves as the **tutorial zone**: the scanner-mine loop is introduced here at its simplest
- Scrap Metal fragments teach walk-up pickup *before* the full scanner loop is required — reducing early friction
- Organic Matter establishes the fuel system concept before the player needs efficient fuel
- The Serev ruins provide environmental storytelling without requiring combat engagement
- Biome is intentionally non-threatening — the true danger of Aur is revealed elsewhere, as the player ventures outward

---

## Adding New Biomes

When a new biome is designed, add an entry to this catalog following the B001 format:

1. Assign the next catalog ID (B002, B003, etc.)
2. Define: threat tier, visual identity, atmosphere, enemy types, and complete resource table with collection method and use for each resource
3. Notify engineering so the biome can be registered in the procedural generation system
4. Notify environment-artist for visual identity documentation and asset list
5. Add a resolved entry to `docs/design/open-questions.md` tracking the design decision
