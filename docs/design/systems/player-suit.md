# System Spec: Player Suit

**Owner:** game-designer
**Status:** Draft
**Last Updated:** 2026-02-21

> The suit is the player's personal equipment — distinct from the ship. It upgrades on its own track, independent of the ship tech tree. Where the ship is infrastructure, the suit is capability.

---

## Design Intent

The player is a researcher operating in a hostile environment. Their suit is their interface with that environment — it powers their tools, protects their body, moves them across terrain, and augments their scanner. The suit upgrade system is the player's *personal* progression axis, running in parallel with the ship's tech tree rather than competing with it.

---

## Suit Upgrade System

The suit has **four upgrade axes**, each independently upgradable via the suit upgrade path. The suit upgrade system is separate from the ship's tech tree — suit upgrades do not consume ship tech tree resources, and ship upgrades do not advance the suit.

| Axis | Description |
|---|---|
| **Battery Capacity** | Maximum charge the suit battery holds; determines how long the player can operate in the field before needing to recharge or use a spare |
| **Movement Speed** | Base movement speed and the severity of the battery-depletion movement penalty |
| **Scanner Range / Quality** | The player's personal scanner baseline; complements the ship's Scanner Array module — the module sets the detection ceiling, the suit upgrade improves the player's baseline range and resolution |
| **Armor / Damage Resistance** | Reduces damage taken from environmental hazards and enemy attacks |

> Balance values (capacity numbers, speed multipliers, armor ratings, upgrade costs) are TBD — to be determined during gameplay balancing pass.

---

## Suit Battery

### Capacity and Recharge

- **Capacity:** Upgradable via the Battery Capacity suit axis. Base capacity is TBD (set during balance pass).
- **Recharge:** Fast — a few seconds at any ship recharge point. Recharge is a short, visible process, not instant and not a significant wait.
- **Depletion penalty:** At 0% charge, movement speed is reduced by 25%. The player is never immobilized. Scanning remains fully functional at 0% battery. Tools will not fire when charge is depleted.

### Spare Batteries

- **Carry limit:** No dedicated spare battery slot. Spare batteries occupy **general inventory slots** — carrying more batteries means carrying fewer extracted resources. This is a deliberate field-trip trade-off.
- **Sources:**
  - **Crafted:** Basic spare batteries are craftable from available materials. This is the reliable baseline supply.
  - **Found:** Higher-quality or extra-capacity spare batteries are discoverable as exploration rewards in the world (Serev ruins, debris fields, etc.). Found batteries may offer better capacity or lighter weight than crafted equivalents — rewarding thorough exploration.

---

## Scanner Integration

The suit's Scanner axis and the ship's Scanner Array module interact:

- **Ship Scanner Array module:** Sets the maximum deposit tier detectable and the maximum ping range. This is the hard ceiling.
- **Suit scanner upgrade:** Improves the player's baseline range and resolution within that ceiling — a better-suited player gets more information from the same Scanner Array module.

A player with a high-tier Scanner Array but a low-tier suit scanner still benefits from the module; a player with a high-tier suit scanner but a low-tier module is still constrained by the module's detection ceiling. Both axes matter.

---

## Open Items

- All balance values: battery capacity per tier, speed multipliers per upgrade level, armor resistance values, upgrade material costs [→ game-designer, balance pass]
- Number of upgrade tiers per axis [→ game-designer, next pass]
- Found battery variants: names, capacity values, rarity distribution per biome tier [→ game-designer + narrative-designer for naming]
- Suit upgrade UI/UX spec [→ ui-ux-designer] — must support gamepad as first-class input
- Whether suit upgrades are performed at the ship or at a dedicated crafting station [→ game-designer, next pass]
