# System Spec: Mobile Base (Atmospheric Ship)

**Owner:** game-designer
**Status:** Draft
**Last Updated:** 2026-02-21

> This is the canonical spec for the player's atmospheric ship — the mobile base that serves as home, vehicle, crafting station, and survival system simultaneously. All agents implementing ship-related systems must reference this document.

---

## Design Intent

The ship is not a static base the player retreats to. It is a **living entity** — a character in its own right — with survival needs that must be actively managed. Every design decision for the ship should reinforce the message: *"Your ship can die. Keep it alive."*

The ship's modularity creates meaningful build decisions, not cosmetic customization. Adding a room changes fuel consumption and top speed. Removing a module has consequences. There is no "optimal" loadout — only trade-offs.

---

## Global Variables

These four variables define the ship's survival state at all times. They are displayed via the HUD when in third-person (base) mode and via diegetic indicators in first-person mode.

| Variable | Range | Description |
|---|---|---|
| **Power** | 0–100% | Total electrical output from generators minus draw from all active modules. If Power reaches 0%, non-essential modules shut down. If it remains at 0% for [TBD] seconds, critical systems fail. |
| **Integrity** | 0–100% | Structural health of the ship hull. Reaches 0% → Ship destroyed (see Fail State). Degraded by environmental hazards, enemy attacks, and failed navigation events. Repaired with crafted materials. |
| **Heat** | 0–100% | Internal temperature. Extreme biomes push Heat toward 100%; cold biomes push toward 0%. Outside the safe range, crew efficiency drops and modules malfunction. Managed by thermal regulators. |
| **Oxygen** | 0–100% | Atmospheric viability inside the ship. Degraded by hull breaches and certain biome hazards. Dropping to 0% triggers a countdown before player health is affected. Maintained by O2 recyclers. |

### Variable Interdependencies

- Low **Power** disables Heat management → Heat drifts toward ambient biome temperature
- Low **Power** disables O2 recyclers → Oxygen begins to drop
- High **Heat** increases **Power** draw (cooling systems work harder)
- Low **Integrity** can cause hull breaches → Oxygen drops

---

## Module System

### Core Concept

The ship is built from **modules** — discrete rooms or structural components that slot into the ship's frame. Each module:
- Adds **weight** (affects fuel consumption and top speed)
- Has a **Power draw** (affects the Power global variable)
- Has a **function** (crafting, storage, power generation, etc.)
- Can be **upgraded** (improves function but increases weight/power cost)

### Weight → Performance Relationship

```
Total Ship Weight = Hull Base Weight + Sum of all module weights

Fuel Consumption = Base Rate × (1 + Weight Modifier)
Top Speed        = Base Speed  × (1 - Weight Modifier)

Weight Modifier  = (Total Ship Weight - Optimal Weight) / Optimal Weight
                   [clamped to 0 at or below Optimal Weight]
```

This means players are always making a decision: *"Do I add this module and accept slower travel and higher fuel cost, or do I leave it off?"*

### Module Categories

| Category | Function | Weight Class |
|---|---|---|
| **Power Generation** | Increases Power output (solar panels, fuel cells, fusion cores) | Light → Heavy |
| **Propulsion** | Required for navigation; upgrades increase top speed and fuel efficiency | Medium → Heavy |
| **Structural** | Increases max Integrity; required anchoring points for other modules | Medium |
| **Extraction Bay** | Enables ore processing / smelting on-board | Medium → Heavy |
| **Automation Hub** | Houses mining drones and auto-smelter logic (mid-game unlock) | Medium |
| **Thermal Management** | Regulates Heat; required in extreme biomes | Light → Medium |
| **Life Support** | Maintains Oxygen; required for toxic atmosphere biomes | Light |
| **Storage** | Expands cargo capacity for resources | Light → Heavy |
| **Scanner Array** | Improves scanner range, resolution, and deposit tier detection | Light |
| **Weapons/Defense** | Shields and weapons for high-threat zones | Medium → Heavy |

### Module Placement Rules

- Modules must be adjacent to at least one existing module (no floating rooms)
- Power Generation modules must be connected to the Power Grid (a structural pathway)
- Max module count is determined by the ship's current **hull tier** [TBD — hull tier progression]
- Some modules require other modules as prerequisites (e.g., Automation Hub requires Extraction Bay)

---

## Navigation System

### Biome-to-Biome Travel

Navigation is a deliberate act, not seamless open-world walking. The player pilots the ship from one **zone** to another. Travel between zones:
- Consumes fuel proportional to distance and ship weight
- Exposes the ship to **transit hazards** (storms, hostile fleets, terrain obstacles) based on route difficulty
- Takes real time — the player is active during transit (managing ship systems, responding to events)

### Fuel

- Fuel is a crafted resource (not found raw — must be refined)
- Fuel consumption is tracked as a global resource (not per-module)
- Running out of fuel mid-transit triggers an emergency landing event [TBD — consequences]

### Navigation Tiers

| Tier | Biome Threat | Required Ship Capability |
|---|---|---|
| 1 | Low | Base propulsion; no special requirements |
| 2 | Medium | Upgraded propulsion; thermal management recommended |
| 3 | High | Full thermal + life support; Integrity must be above 50% to enter |
| 4 | Extreme (Mega-Project zones) | Ship must meet Mega-Project spec requirements |

---

## Fail State: Ship Destruction

When Integrity reaches 0%, the ship is destroyed. **Partial persistence applies:**

| What Resets | What Persists |
|---|---|
| Resources (all raw materials and refined goods) | Tech tree progress (all unlocked nodes) |
| Ship modules (all installed modules lost) | Schematics (all learned crafting recipes) |
| Cargo / inventory | Rel (the AI companion) |
| Fuel | Biome map data (explored areas remain revealed) |

**Narrative framing:** The player is a researcher. Their knowledge — their notes, their schematics, their understanding of Aur — survives because they, the person, survive. The ship is the vessel. They are not the ship.

**Recovery:** The player respawns at the last safe location with the starting-tier ship configuration. They rebuild, faster than before, because they know everything they knew before.

**Optional Hard Mode:** Full restart (new world seed, no persistence) available as an optional difficulty setting for players who want maximum stakes. Not the default.

---

## Open Items

- Exact hull tier progression and max module counts [→ OQ-008]
- Emergency fuel-out consequences (full stop? forced landing? ship damage?)
- Specific transit hazard event types and resolution mechanics
- Third-person base-building UI/UX spec [→ ui-ux-designer] — must support gamepad as first-class input
- Diegetic HUD indicators for Global Variables in first-person mode [→ ui-ux-designer] — must support gamepad as first-class input
