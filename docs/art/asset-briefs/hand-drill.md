# Asset Brief: Hand Drill

**Ticket:** TICKET-0008
**Author:** game-designer
**Date:** 2026-02-22

---

## In-Game Function

The Hand Drill is the player's starting extraction tool — the first thing they use to mine. It extracts Tier 1 deposits (surface and near-surface soft rock, embedded scrap metal). It is always visible in the player's hand during first-person mode when equipped. It does not degrade or break; it runs on suit battery charge.

This is a workhorse tool. The player uses it constantly in the early game and occasionally in the mid/late game for low-tier deposits. It needs to feel solid, functional, and satisfying to hold.

---

## Approximate Scale

- **Type:** Handheld tool (one-handed or two-handed — design decision open; lean toward one-handed for this PoC)
- **Size reference:** Roughly the size of a real-world cordless drill, slightly oversized for sci-fi readability
- **Poly budget (PoC target):** 2,000–5,000 triangles (this is a first-person hero prop — visible up close)
- **Bounding box estimate:** ~30cm long, ~15cm wide, ~20cm tall

---

## Visual Context

- **Art style:** Stylized sci-fi. Reference tone: Outer Wilds (handcrafted, slightly chunky proportions) crossed with Hades (bold color reads, strong silhouettes)
- **Material palette:** Worn metal housing, rubber/polymer grip, visible energy conduit or glowing element to indicate charge state
- **Setting context:** Human-made research equipment, not alien. This is gear the player brought from their ship. It should look utilitarian and purpose-built — a tool, not a weapon
- **Key visual reads:**
  - Immediately identifiable as a drilling/extraction tool (not a gun, not a scanner)
  - Glowing element or indicator that could later animate to show charge level
  - Chunky, slightly oversized proportions appropriate for stylized aesthetic

---

## PoC "Done" Criteria

This is a pipeline proof-of-concept, not a final asset. "Done" means:

- [ ] A single static mesh exported as `.glb`
- [ ] Silhouette is clearly readable as a handheld drill/extraction tool
- [ ] Proportions fit the stylized sci-fi aesthetic (not photorealistic, not cartoonish)
- [ ] Has at least 2 distinct material zones (e.g., metal body + grip + energy element)
- [ ] Imports into Godot 4.5 without errors at correct scale (handheld prop scale)
- [ ] UVs are clean enough that a flat color or simple texture reads correctly
- [ ] No animation required for PoC
- [ ] No rigging required for PoC
