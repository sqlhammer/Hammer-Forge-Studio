# Open Design Questions

**Owner:** game-designer
**Purpose:** Track unresolved design decisions that are blocking or deferring work.

---

## Format

Each entry:
- **Q:** The specific question that needs answering
- **Impact:** What tickets or systems are blocked by this
- **Options:** Possible answers being considered
- **Status:** Open / Escalated to Studio Head / Resolved
- **Resolution:** (fill in when resolved)

---

## OQ-001: Game Title

- **Q:** What is the working title of the game?
- **Impact:** Was blocking all player-visible text, store page copy, marketing materials, and documentation headers.
- **Status:** Resolved
- **Resolution:** **The Inheritance.** The player inherits the dead civilization's final, fatal project — the Naer-Reth — and completes it. Whether they knew what they were inheriting is the game's central question.

---

## OQ-002: World / Planet Setting and Backstory

- **Q:** What is the game world? What planet is this? What happened here? Why is the player alone?
- **Impact:** Was blocking narrative-bible, biome naming, resource palettes, and art direction.
- **Status:** Resolved
- **Resolution:** The player is a human researcher who arrived via cryo-sleep as part of an interstellar research expedition to study an alien civilization. They arrived after the civilization had already collapsed. The civilization built a planetary-scale machine (the World-Engine) to reverse an ecological crisis of their own making — and were consumed by it during its initial activation. The player does not know this at the start. See `docs/narrative/narrative-bible.md` for full world overview.

---

## OQ-003: Specific Mega-Project Endgame Objective

- **Q:** What is the Mega-Project? What does the player physically build or activate to win?
- **Impact:** Was blocking win-condition finalization, tech tree design, and the final narrative sequence.
- **Status:** Resolved
- **Resolution:** The Mega-Project is **activation of the World-Engine** — a planetary-scale machine distributed as a node network across the world's biomes, designed to restore the planet's dying ecological systems. The player activates it believing it will save the planet. It does restore the ecology — and also consumes all available energy on the planet, including the player. The "win" is a tragedy. See `docs/design/systems/endgame-arc.md` and `docs/narrative/narrative-bible.md`.

---

## OQ-004: Loss / Fail-State Reset Rules

- **Q:** When the ship's Integrity reaches 0% and the player "loses," what resets and what persists?
- **Impact:** Was blocking mobile-base.md integrity section and save/load architecture.
- **Status:** Resolved
- **Resolution:** **Partial persistence.** The ship is destroyed. The tech tree progress and all schematics (the player's knowledge as a researcher) survive. Resources, ship modules, cargo, and fuel are lost. The player rebuilds from a stripped ship with all their knowledge intact. The researcher's identity survives; the vessel does not. See `docs/design/systems/mobile-base.md`.

---

## OQ-005: Target Platforms

- **Q:** Beyond PC (Windows/Steam), which platforms are in scope?
- **Impact:** Was blocking control scheme design, UI scaling decisions, and milestone planning.
- **Status:** Resolved
- **Resolution:** **PC first (Windows/Steam as primary; Linux/Mac via Godot export), with console post-launch (PS5/Xbox Series X).** Critical design constraint: **gamepad support is a first-class citizen from day one.** The scanner mechanic, ship UI, and all core systems must be designed to work fully with a controller — not bolted on as an afterthought. This is a launch-to-post-launch strategy, not a "maybe someday" plan.

---

## OQ-006: Monetization Model

- **Q:** What is the commercial model for this game?
- **Impact:** Was blocking scope decisions, DLC planning, and marketing positioning.
- **Status:** Resolved
- **Resolution:** **Premium one-time purchase. No DLC. No live service.** The game is complete on release. Aligns with the "Tactical Solitude" brand and the Efficient Architect persona who distrusts ongoing monetization. Revenue model: unit sales only. See `docs/studio/prd.md`.

---

## OQ-007: Art Style / Visual Direction

- **Q:** What is the visual identity of this game? What does it look like?
- **Impact:** Was blocking technical-artist and environment-artist agents, rendering pipeline decisions, and asset style guides.
- **Status:** Resolved
- **Resolution:** **Stylized sci-fi — distinct visual identity.** Strong authored color theory, readable silhouettes, bold environmental storytelling. Aur looks like no other game. Serev ruins have a visual language clearly distinct from human design. The atmospheric ship has immediate visual brand identity. Reference feel: Outer Wilds, Hades (strong artistic identity over raw fidelity). Hardware target: low-to-mid PC (GTX 970+). The art direction must be documented in a separate art style guide [→ technical-artist, environment-artist].

---

## OQ-008: Hull Tier Progression

- **Q:** How many hull tiers does the ship have, and what are the max module counts per tier?
- **Impact:** Blocks finalization of module system in `docs/design/systems/mobile-base.md`.
- **Options:** To be designed by game-designer in next documentation pass.
- **Status:** Open
- **Resolution:** —

---

## OQ-009: Does Purity Affect Yield Quantity (in addition to crafting cost)?

- **Q:** Should higher-purity deposits also yield more material per deposit, or only reduce crafting energy cost?
- **Impact:** Affects the resource economy balance and player incentive to seek high-purity deposits. Blocks final purity system design in `docs/design/systems/meaningful-mining.md`.
- **Options:**
  1. Purity affects crafting cost only (simpler; cleaner mental model)
  2. Purity affects both yield quantity and crafting cost (richer reward but more complex balancing)
- **Status:** Open
- **Resolution:** —

---

## OQ-010: NPC Factions in High-Threat Zones

- **Q:** Do NPC factions compete for rare materials in Tier 3–4 biomes?
- **Impact:** Affects late-game threat design, narrative opportunities, and whether the game needs faction/diplomacy systems.
- **Options:**
  1. No factions — hostile AI enemies only (simpler; keeps single-player focus clean)
  2. Hostile factions with no interaction — competing for the same rare veins but cannot be negotiated with
  3. Factions with limited interaction — can be avoided, fought, or (with effort) bargained with
- **Status:** Open — world setting now resolved; this can be decided in context of the alien world setting (no other humans present; enemy entities are likely ecological/environmental rather than factional)
- **Resolution:** —

---

## OQ-011: Planet Name

- **Q:** What is the name of the planet the game takes place on?
- **Impact:** Was blocking narrative text, UI location displays, store copy, and lore fragments.
- **Status:** Resolved
- **Resolution:** **Aur.** From 'aurum' / 'aurora' — gold, light, warmth. A name that records what Aur once was. The Serev named their world for what sustains you. The world no longer sustains anything. See `docs/narrative/narrative-bible.md`.

---

## OQ-012: Alien Civilization Name (The Extinct Species)

- **Q:** What is the in-universe name (or designation) for the alien civilization whose ruins the player explores?
- **Impact:** Was blocking lore fragments, Rel's dialogue, and all archaeological in-game documentation.
- **Status:** Resolved
- **Resolution:** **The Serev.** The extinct civilization that built the Naer-Reth, named Aur, and were consumed by what they built. Their self-designation; translated and provided by Rel. See `docs/narrative/narrative-bible.md`.

---

## OQ-013: World-Engine In-Universe Name

- **Q:** What did the alien civilization call the World-Engine?
- **Impact:** Was blocking data fragments, Rel's dialogue, and the in-game objective system.
- **Status:** Resolved
- **Resolution:** **Naer-Reth / "The Chrysalis."** Naer: emergence, the moment when a contained form is no longer contained. Reth: the lowest structural layer, the foundation everything is built on. Naer-Reth: the structure of emergence. Rel's translation: "The Chrysalis — a container for transformation. The old form dissolves. A new form emerges." The name is accurate and does not signal catastrophe. That is the point.

---

## OQ-014: AI Companion Name

- **Q:** What is the AI companion called?
- **Impact:** Was blocking all dialogue labels, ship UI, and companion writing.
- **Status:** Resolved
- **Resolution:** **Rel.** A fragment of the Serev's distributed intelligence, housed in a recovered artifact. The name functions as both designation and identity — short, precise, heard constantly. Neither fully alien nor fully human. Like Rel itself.

---

## OQ-015: Second Cycle "True Fix" Mechanics

- **Q:** In the Second Cycle (NG+ playthrough), the player has meta-knowledge of the Naer-Reth's true nature and can attempt to modify it to prevent the destruction cycle. What does "fixing" the Naer-Reth actually require mechanically?
- **Impact:** Was blocking Second Cycle system design and the True Ending narrative.
- **Status:** Resolved
- **Resolution:**
  - **Mechanic:** The player builds **the Regulator** in parallel with completing the standard Naer-Reth activation. Both must complete simultaneously. 2× total resources; separate Second Cycle tech tree branch (Phase 3). The Regulator is the first truly original construction in the world — something the Serev never built but knew could exist.
  - **Exclusive Rare Material:** "The Record" — a material whose location the Serev encoded in data fragments distributed across all of Aur's biomes. In Run 1 these are flavor text. In Run 2, Rel can translate them as coordinates. Requires revisiting all biome tiers. Material name TBD — narrative-designer to name.
  - See `docs/design/systems/endgame-arc.md` for full Second Cycle tech tree and mechanic spec.
