# Asset Brief: Resource Node (Scrap Metal Deposit)

**Ticket:** TICKET-0008
**Author:** game-designer
**Date:** 2026-02-22

---

## In-Game Function

Resource Nodes are the mineable deposits scattered across biome terrain. For this PoC, the target is a **Scrap Metal (embedded)** deposit from the Overgrown Suburbs biome (Tier 1, low-threat starting area). This is a Tier 1 deposit requiring the Hand Drill to extract.

Resource nodes are what the player scans for, walks up to, analyzes, and mines. They are the primary interaction point of the core game loop. They need to be visually distinct from terrain at scanner range but feel like natural parts of the environment up close.

The scrap metal deposit is embedded within collapsed Serev architecture — it reads as alien technology debris partially buried in the ground, with extractable metal visible within.

---

## Approximate Scale

- **Type:** Environmental prop / interactable deposit
- **Size reference:** Large boulder to small car — big enough to walk up to and interact with, small enough to be one of many scattered across terrain
- **Poly budget (PoC target):** 1,500–4,000 triangles (many instances will be placed; must be efficient)
- **Bounding box estimate:** ~2m wide, ~1.5m tall, ~2m deep

---

## Visual Context

- **Art style:** Stylized sci-fi. Should blend with the Overgrown Suburbs biome aesthetic — muted earth tones, oxidized metal, cracked synthetic materials
- **Material palette:** Exposed metal veins or fragments embedded in rock/debris, surrounding material is weathered alien construction rubble, visible contrast between extractable metal and inert surrounding material
- **Setting context:** This is Serev technology debris — collapsed alien architecture that has been weathered by time. The extractable scrap metal is visible within the rubble as brighter or more reflective material
- **Key visual reads:**
  - Distinct from plain terrain rocks (the player must be able to spot it as "something interactable")
  - Visible metal element that communicates "this contains resources"
  - Partially buried / embedded in ground — not floating or sitting on top of terrain
  - Should support a future glowing highlight overlay (scanner visualization) — the base mesh needs clean geometry for this

---

## PoC "Done" Criteria

This is a pipeline proof-of-concept, not a final asset. "Done" means:

- [ ] A single static mesh exported as `.glb`
- [ ] Silhouette reads as a distinct interactable object (not generic terrain)
- [ ] Visual contrast between extractable metal and surrounding debris/rock material
- [ ] Proportions fit the stylized sci-fi aesthetic
- [ ] Has at least 2 distinct material zones (metal deposit + surrounding debris)
- [ ] Imports into Godot 4.5 without errors at correct scale (~2m wide)
- [ ] UVs are clean enough that flat colors or simple textures read correctly
- [ ] No animation required for PoC
- [ ] Efficient enough for multiple instances (stays within poly budget)
