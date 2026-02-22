# Asset Brief: Ship Exterior

**Ticket:** TICKET-0008
**Author:** game-designer
**Date:** 2026-02-22

---

## In-Game Function

The Ship Exterior is the atmospheric ship hull visible in the third-person orbital camera view. This is the player's mobile base — home, vehicle, crafting station, and survival system. It is the most visually prominent object in third-person mode and the centerpiece of the game's "Living Ship" pillar.

The ship starts small (early game) and grows as modules are added. For this PoC, only the **base hull** is needed — the minimum starting configuration before any module expansion.

The ship must communicate "functional vehicle that can fly in atmosphere" while also reading as "a place you live in." It is not a sleek fighter — it is a mobile workshop.

---

## Approximate Scale

- **Type:** Atmospheric vessel / mobile base (not a starship — operates within a single planet's atmosphere)
- **Size reference:** Small cargo plane or large helicopter in footprint. Big enough to contain internal rooms but not massive
- **Poly budget (PoC target):** 8,000–15,000 triangles (hero asset seen from medium-to-far distance in orbital view)
- **Bounding box estimate:** ~15m long, ~8m wide, ~5m tall (rough starting hull)

---

## Visual Context

- **Art style:** Stylized sci-fi. Outer Wilds (the ship in that game is a strong reference — handmade, cobbled-together, personality-rich) meets industrial utility
- **Material palette:** Riveted metal plating, visible structural seams, engine housings/thruster nozzles, cargo bay doors or hatches, antenna/sensor arrays
- **Setting context:** Human-built research vessel. It was assembled for an expedition, not for war. It should look capable but not military. Think research icebreaker or deep-sea submersible translated to atmosphere flight
- **Key visual reads:**
  - Reads as a vehicle (not a building) from orbital camera distance
  - Asymmetric or utilitarian profile preferred over sleek symmetry — this ship has character
  - Visible propulsion elements (thrusters, engines, lift surfaces)
  - Hull surface that suggests modularity — panel lines, attachment points, or bay doors that hint at expandability
  - Landing gear or ground-contact elements visible (the ship lands on terrain)

---

## PoC "Done" Criteria

This is a pipeline proof-of-concept, not a final asset. "Done" means:

- [ ] A single static mesh exported as `.glb`
- [ ] Silhouette reads as an atmospheric vessel / flying base from orbital camera distance
- [ ] Proportions fit the stylized sci-fi aesthetic (chunky, utilitarian, not sleek)
- [ ] Has at least 3 distinct material zones (hull plating, engine/thruster elements, details like windows/hatches)
- [ ] Imports into Godot 4.5 without errors at correct scale (~15m long)
- [ ] UVs are clean enough that flat colors or simple textures read correctly
- [ ] No interior modeled for PoC (exterior hull only)
- [ ] No animation or rigging required for PoC
