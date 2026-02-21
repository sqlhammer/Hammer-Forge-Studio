# Open Design Questions

**Owner:** game-designer
**Purpose:** Track unresolved design decisions that are blocking or deferring work. For decisions that have already been answered, see `docs/design/resolved-questions.md`.

---

## Format

Each entry:
- **Q:** The specific question that needs answering
- **Impact:** What tickets or systems are blocked by this
- **Options:** Possible answers being considered
- **Status:** Open / Escalated to Studio Head / Deferred

When a question is resolved, move the full entry (including the Resolution) to `docs/design/resolved-questions.md` and update its Status to `Resolved`.

---

## OQ-019: Weather Damage to Structures

- **Q:** How does weather affect building and module durability? What weather types exist and what damage do they deal?
- **Impact:** Affects module durability system, biome weather design, and hazard balancing.
- **Status:** Deferred — not implemented in first pass. The durability system for buildings and modules ships first without weather damage. Weather as a durability source is a post-launch or later-milestone feature.
- **Resolution (when addressed):** Define weather types per biome, damage rates, and which modules are vulnerable vs. protected.

---

## OQ-020: Enemy NPC Attacks on Structures

- **Q:** Can hostile NPCs target and damage ship modules and buildings? How does this interact with module durability?
- **Impact:** Affects enemy AI targeting, combat design, and module durability tuning.
- **Status:** Deferred — not implemented in first pass. NPCs deal damage to the ship's Integrity (already modeled as a global variable) but do not target individual modules in V1. Per-module NPC damage is a later feature.
- **Resolution (when addressed):** Define which enemy types can target modules, damage rates, and whether module destruction is a discrete event or a health-pool degradation.
