# UAT Sign-Off — M8 — Ship Navigation

> **Studio Head:** Signed off 2026-03-01.

---

## Header

| Field | Value |
|-------|-------|
| **Milestone** | M8 — Ship Navigation |
| **Prepared By** | qa-engineer / producer |
| **Date Prepared** | 2026-03-01 |
| **Test Build** | commit f5ad2ce (TICKET-0247 final fix) |
| **Sign-Off Status** | ✅ Approved |

---

## How to Use This Document

Items tagged `manual-playtest` require hands-on testing. Items tagged `unit-test` or `integration-test` are covered by the automated suite (879 tests, 0 failures as of 2026-02-27 QA run).

---

## Feature Sign-Off Checklist

### Fuel System

---

#### Fuel Cell Crafting (TICKET-0157, TICKET-0163)

**Verification Method:** `unit-test`

**What changed:** Fuel Cell added as a craftable item — recipe: Metal + Cryonite → Fuel Cell. Cryonite added as a new minable resource.

**Automated coverage:** test_cryonite_unit (28 tests), test_fabricator_unit (19 tests)

- [x] ✅ Approved

---

#### Fuel System Autoload (TICKET-0158)

**Verification Method:** `unit-test`

**What changed:** `FuelSystem` autoload manages ship fuel tank (capacity 1000 units). Fuel Cells refuel at 100 units each. Emits `fuel_low` at ≤25%, `fuel_empty` at 0.

**Automated coverage:** test_fuel_system_unit (42 tests)

- [x] ✅ Approved

---

#### Fuel Gauge HUD (TICKET-0162)

**Verification Method:** `unit-test` + `manual-playtest`

**What changed:** Fuel gauge displays current/max fuel units and fuel cell count in the game HUD.

**How to test:**
1. Launch DebugLauncher → Begin Wealthy → LAUNCH
2. Board the ship, open the navigation console
3. Observe the fuel gauge in HUD reflects 1000/1000 units

**Automated coverage:** test_fuel_gauge_unit (23 tests)

- [x] ✅ Approved

---

### Navigation System

---

#### Biome Registry (TICKET-0159)

**Verification Method:** `unit-test`

**What changed:** `BiomeRegistry` defines 3 biomes (Shattered Flats, Rock Warrens, Debris Field) with seed-based 500×500m maps and inter-biome distances.

**Automated coverage:** test_navigation_system_unit (36 tests)

- [x] ✅ Approved

---

#### Navigation Console Modal (TICKET-0167)

**Verification Method:** `manual-playtest`

**What changed:** Cockpit console opens a navigation modal on E-key interaction. Shows biome map, destination detail panel (distance, fuel cost, your fuel), and CONFIRM TRAVEL button.

**How to test:**
1. Launch DebugLauncher → Begin Wealthy → LAUNCH
2. Walk into the ship hull (boarding zone), board the ship
3. Walk to the cockpit console, press E
4. Verify the Navigation Console modal opens
5. Select a destination biome — check fuel cost and sufficiency indicator display correctly
6. Confirm the CONFIRM TRAVEL button enables when fuel is sufficient

**Automated coverage:** test_navigation_console_unit (15 tests)

- [x] ✅ Approved

---

#### Biome Travel — Full Sequence (TICKET-0168, TICKET-0247)

**Verification Method:** `manual-playtest`

**What changed:** Pressing CONFIRM TRAVEL triggers fade-out → biome swap → fade-in sequence. `TravelSequenceManager` handles the transition. Fuel is consumed by `NavigationSystem.initiate_travel()`. Fix in TICKET-0247 wired `TravelSequenceManager` into the DebugLauncher game path (previously only TestWorld created it).

**How to test:**
1. Launch DebugLauncher → Begin Wealthy → LAUNCH
2. Board the ship, walk to cockpit console, press E
3. Select Rock Warrens → CONFIRM TRAVEL
4. Observe: screen fades to black, biome swaps, screen fades back in at the new biome
5. Verify player is spawned at the new biome's spawn point
6. Verify fuel level has decreased by the travel cost

**Automated coverage:** test_travel_sequence_unit (17 tests), test_navigation_system_unit (36 tests)

- [x] ✅ Approved — _Notes: Static analysis of commit f5ad2ce confirms TravelSequenceManager correctly wired in DebugLauncher path. Studio Head sign-off granted on code review basis after 4 iteration fixes._

---

#### Resource Respawn on Biome Change (TICKET-0161)

**Verification Method:** `unit-test`

**What changed:** All resource deposits respawn when the player travels to a new biome (listen on `NavigationSystem.biome_changed`).

**Automated coverage:** test_resource_respawn_unit (26 tests)

- [x] ✅ Approved

---

### Biome Generation

---

#### Three Biomes: Shattered Flats, Rock Warrens, Debris Field (TICKET-0164, TICKET-0165, TICKET-0166)

**Verification Method:** `unit-test` + `manual-playtest`

**What changed:** Three procedurally generated 500×500m seed-based biomes with distinct terrain (plateau, corridor-based rock warrens, debris scattering). Deep resource nodes (infinite yield, drone-minable) placed in each biome.

**How to test:**
1. Launch DebugLauncher → select each biome in turn → LAUNCH
2. Confirm each biome generates distinct terrain
3. Confirm deep resource nodes are present and mineable

**Automated coverage:** test_navigation_system_unit, test_deep_resource_node_unit (27 tests), test_deep_resource_node_scene (14 tests)

- [x] ✅ Approved

---

### HUD & UX

---

#### Debug Launcher Scene (TICKET-0180)

**Verification Method:** `manual-playtest`

**What changed:** Debug Launcher provides biome selector dropdown, Begin Wealthy toggle (200× all resources), and LAUNCH button. Replaces manual TestWorld scene selection.

**How to test:**
1. Open `game/scenes/debug/debug_launcher.tscn` in Godot and run
2. Verify biome dropdown lists all 3 biomes
3. Verify Begin Wealthy grants 200× resources on launch

**Automated coverage:** test_debug_launcher_unit

- [x] ✅ Approved

---

#### Player Jump (TICKET-0175)

**Verification Method:** `unit-test`

**What changed:** Player can now jump (50% standard jump height).

**Automated coverage:** test_player_jump_unit (11 tests)

- [x] ✅ Approved

---

#### Mouse Interaction for Menus (TICKET-0176)

**Verification Method:** `unit-test`

**What changed:** Navigation console supports mouse-click selection of destination biomes in addition to keyboard navigation.

**Automated coverage:** test_mouse_interaction_unit (13 tests)

- [x] ✅ Approved

---

#### Headlamp Toggle (TICKET-0173)

**Verification Method:** `unit-test`

**What changed:** Headlamp can be toggled via the interaction controls.

**Automated coverage:** test_interaction_prompt_hud_unit (7 tests)

- [x] ✅ Approved

---

## Rejection Notes

| Feature | Ticket | Issue Description |
|---------|--------|-------------------|
| — | — | None |

---

## Final Sign-Off

**Total Features:** 12
**Approved:** 12
**Rejected:** 0

**Gate Condition:** All features must be `✅ Approved` for sign-off to be granted.

---

**Studio Head Sign-Off:**

- [x] All features approved — milestone is cleared for close

**Signed off by:** Studio Head
**Date:** 2026-03-01
