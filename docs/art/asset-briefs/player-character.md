# Asset Brief: Player Character

**Ticket:** TICKET-0008
**Author:** game-designer
**Date:** 2026-02-22

---

## In-Game Function

The Player Character is the full-body mesh visible in third-person orbital view when the player is on-foot outside the ship. The character is a human researcher wearing an environmental suit — this is their survival interface with the hostile alien world of Aur. The suit has four upgrade axes (battery, speed, scanner, armor) that will eventually need visual differentiation, but for this PoC only the base-tier suit is needed.

The character is seen from a medium-distance orbital camera (not extreme close-up), so broad silhouette and color reads matter more than fine detail.

---

## Approximate Scale

- **Type:** Full-body humanoid character in an environmental suit
- **Size reference:** Standard human proportions, slightly stylized (not hyper-realistic anatomy)
- **Poly budget (PoC target):** 5,000–10,000 triangles (third-person character seen at medium distance)
- **Height estimate:** ~1.8m in-engine

---

## Visual Context

- **Art style:** Stylized sci-fi. Outer Wilds / Hades reference. The suit should feel handcrafted and lived-in, not sleek military sci-fi
- **Material palette:** Layered fabric/composite suit with rigid armor plates at key joints, helmet with visor, visible equipment attachment points (belt, back mount for tools/battery)
- **Setting context:** This is a researcher, not a soldier. The suit is protective but purpose-built for exploration and extraction work. Think field scientist in a pressure suit, not space marine
- **Key visual reads:**
  - Immediately identifiable as a suited humanoid from the orbital camera distance
  - Helmet/visor gives the character a distinct head silhouette
  - Color blocking that separates torso, limbs, and helmet at a glance
  - Equipment attachment points visible (even if empty for PoC — they establish the visual language for upgrades later)

---

## PoC "Done" Criteria

This is a pipeline proof-of-concept, not a final asset. "Done" means:

- [ ] A single static mesh exported as `.glb`
- [ ] Silhouette reads as a suited humanoid from ~10m camera distance
- [ ] Proportions fit the stylized sci-fi aesthetic (slightly chunky, not photorealistic)
- [ ] Has at least 3 distinct material zones (helmet, suit body, armor/equipment plates)
- [ ] Imports into Godot 4.5 without errors at correct scale (~1.8m tall)
- [ ] UVs are clean enough that flat colors or simple textures read correctly
- [ ] T-pose or A-pose acceptable for PoC (no rigging or animation required)
- [ ] No facial features required (helmet with visor is sufficient)
