# UAT Sign-Off — M11: GDScript Standards Compliance & Remediation

> **Prepared by:** qa-engineer
> **For Studio Head review.** Follow the test steps for each `manual-playtest` item, then mark each checkbox. When all items are approved, sign off at the bottom.

---

## Header

| Field | Value |
|-------|-------|
| **Milestone** | M11 — GDScript Standards Compliance & Remediation |
| **Prepared By** | qa-engineer |
| **Date Prepared** | 2026-03-06 |
| **Test Build** | `99340ce` (main, post TICKET-0312) |
| **Test Suite** | 1009 tests, 0 failures (run 2026-03-04 16:57:38) |
| **Sign-Off Status** | ⏳ Pending |

---

## How to Use This Document

1. Launch the game from the Godot editor via `res://game.tscn` (or the debug launcher for faster startup — use `DebugLauncher` scene).
2. For each feature, check the **Verification Method** tag:
   - `unit-test` / `scene-validation` / `integration-test` — Automated. No manual action needed. These are pre-verified.
   - **`manual-playtest`** — **Requires hands-on testing.** Follow the How to Test steps.
3. Mark each checkbox `✅ Approved` or `❌ Rejected` (add notes on rejections).
4. Sign off at the bottom once all items are marked.

> **Known Open Issue:** TICKET-0313 — All biome loads spawn player below/inside terrain with a runtime error. Affects Shattered Flats, Rock Warrens, and Debris Field. Filed 2026-03-06. The Navigation Console travel feature below cannot be fully manual-tested until this is resolved — verify the console UI and biome list only; skip the travel execution step.

---

## Feature Sign-Off Checklist

### Inventory System

---

#### Inventory Screen opens, closes, and displays items correctly (TICKET-0293)

**Verification Method:** `manual-playtest`

**What changed:** `inventory_screen.gd` was refactored from programmatic UI construction (`_build_ui()`) to a `.tscn`-first scene with `@onready` node references. No gameplay behavior changed — only the construction approach.

**How to test:**
1. Load into the game world (start via DebugLauncher, begin-wealthy preset recommended for full inventory)
2. Press `Tab` (or the inventory keybind) to open the inventory screen
3. Confirm the inventory grid displays your items with icons and labels
4. Press `Tab` again (or `Escape`) to close the inventory screen
5. Pick up a resource item from the ground — confirm it appears in inventory

**Expected result:** Inventory screen opens cleanly, shows items, and closes without errors. No blank panels or missing nodes.

**Automated coverage:** `test_inventory_unit` — item add/remove/stack logic covered

- [ ] ✅ Approved / ❌ Rejected — _Notes:_

---

#### Inventory Action Popup appears on item interaction (TICKET-0293, TICKET-0308)

**Verification Method:** `manual-playtest`

**What changed:** `inventory_action_popup.gd` was refactored to `.tscn`-first. A regression (TICKET-0308) was found and fixed — the popup was visible by default and was not being located correctly via `get_node()`. Both issues are resolved.

**How to test:**
1. Open the inventory screen
2. Right-click (or press the interact button while hovering) an item in the inventory grid
3. Confirm the action popup appears with options (Drop, Destroy, etc.)
4. Select "Drop" — confirm the item drops into the world
5. Open inventory again, right-click a different item, select "Destroy" — confirm item is removed

**Expected result:** Popup is hidden by default, appears correctly positioned on item interaction, and actions function correctly. Popup is not visible when the inventory is first opened.

**Automated coverage:** `test_inventory_unit` — item drop/destroy logic covered

- [ ] ✅ Approved / ❌ Rejected — _Notes:_

---

### Navigation Console

---

#### Navigation Console opens and displays biomes (TICKET-0292, TICKET-0309)

**Verification Method:** `manual-playtest`

**What changed:** `navigation_console.gd` refactored to `.tscn`-first. A regression (TICKET-0309) was found and fixed — `_biome_node_ids` was missing `debris_field` after the refactor, causing it to be absent from the biome list.

**How to test:**
1. Enter the ship interior
2. Interact with the Navigation Console
3. Confirm the console modal opens
4. Verify all three biomes are listed: **Shattered Flats**, **Rock Warrens**, **Debris Field**

**Expected result:** All three biomes appear in the navigation console destination list. Debris Field is not missing.

**Automated coverage:** `test_navigation_unit` — biome registry and fuel logic covered

- [ ] ✅ Approved / ❌ Rejected — _Notes:_

---

#### Biome travel executes correctly (TICKET-0292)

**Verification Method:** `manual-playtest`

**What changed:** Navigation console and travel sequence refactored to `.tscn`-first; `travel_sequence_manager.gd` TravelFadeLayer/TravelFadeRect nodes fixed (TICKET-0311).

**How to test:**
1. Open the Navigation Console with enough Fuel Cells in inventory
2. Select any destination biome
3. Confirm travel — the screen should fade out, load the new biome, and fade back in
4. Confirm the player spawns on solid terrain in the new biome

> **Note:** TICKET-0313 (all-biome spawn bug) is currently open. If the player spawns below terrain, that is a known pre-existing issue — mark the travel fade itself as approved if it plays correctly, and note the spawn failure separately.

**Expected result:** Travel fade plays correctly (fade out → load → fade in). Player spawn position is blocked on TICKET-0313.

**Automated coverage:** `test_navigation_unit`, `test_biome_unit`

- [ ] ✅ Approved / ❌ Rejected — _Notes:_

---

### Tech Tree

---

#### Tech Tree panel opens and shows unlockable items with prerequisites (TICKET-0295, TICKET-0306)

**Verification Method:** `manual-playtest`

**What changed:** `tech_tree_panel.gd` refactored to `.tscn`-first. A P1 regression (TICKET-0306) was found and fixed — `tech_tree_defs.gd:get_prerequisites()` was returning empty arrays due to an `Array[String]` type mismatch, causing all tech tree items to appear as unlockable with no prerequisites.

**How to test:**
1. Open the Tech Tree (press the tech tree keybind or interact with the tech tree terminal in the ship)
2. Confirm the panel opens and displays tech tree entries
3. Select a tech that has prerequisites — confirm its prerequisites are listed and are not blank
4. Select a tech that is available to unlock — confirm it can be unlocked if you have the required resources

**Expected result:** Tech tree displays items with correct prerequisites shown. No items appear incorrectly prerequisite-free.

**Automated coverage:** `test_tech_tree_unit` — prerequisite lookup and unlock gating covered

- [ ] ✅ Approved / ❌ Rejected — _Notes:_

---

### Fabricator

---

#### Fabricator panel opens and can queue crafting jobs (TICKET-0291, TICKET-0311, TICKET-0312)

**Verification Method:** `manual-playtest`

**What changed:** `fabricator_panel.gd` refactored to `.tscn`-first. Two regressions were found and fixed — an `Array[Dictionary]` type mismatch in `fabricator_panel.gd` (TICKET-0311) and a follow-up `as`-cast regression in `fabricator_defs.gd:get_inputs()` (TICKET-0312). Both are resolved using `Array.assign()`.

**How to test:**
1. Enter the ship interior and interact with the Fabricator
2. Confirm the fabricator panel opens with a list of craftable items
3. Select a recipe (e.g., a basic component) — confirm its input requirements are displayed (not blank)
4. If you have the required inputs, queue the recipe and confirm it starts processing

**Expected result:** Fabricator panel opens, recipes list populates with inputs shown, and crafting can be queued without errors.

**Automated coverage:** `test_fabricator_unit` — recipe lookup, input resolution, and job queueing covered

- [ ] ✅ Approved / ❌ Rejected — _Notes:_

---

### Ship Boarding

---

#### Ship boarding contextual prompt only appears when aiming at the hull (TICKET-0305)

**Verification Method:** `manual-playtest`

**What changed:** `debug_ship_boarding_handler.gd` was incorrectly showing the "Board Ship" contextual prompt when the player was near the ship but not aiming at the hull. Fixed by syncing `_aim_valid` with the prompt display.

**How to test:**
1. Approach the ship exterior on foot
2. Without aiming directly at the ship hull — confirm **no** "Board Ship" prompt appears
3. Aim your crosshair directly at the ship hull — confirm the "Board Ship" prompt **does** appear
4. Move crosshair away from the hull — confirm the prompt disappears

**Expected result:** The boarding prompt is context-sensitive — only visible when the player's crosshair is on the ship hull.

**Automated coverage:** None — manual only

- [ ] ✅ Approved / ❌ Rejected — _Notes:_

---

### HUD Components

---

#### HUD elements are correctly positioned and functional (TICKET-0294, TICKET-0300, TICKET-0307)

**Verification Method:** `manual-playtest`

**What changed:** HUD readout components (`scanner_readout`, `ship_globals_hud`, `ship_stats_sidebar`) refactored to `.tscn`-first (TICKET-0294). Eight HUD components had layout properties moved from `_ready()` into the scene (TICKET-0300). A regression (TICKET-0307) caused CompassBar, MiningProgress, and MiningMinigameOverlay anchor presets to reset to 0 — fixed by setting explicit float anchor values in `game_hud.tscn`.

**How to test:**
1. Load into the game world
2. Confirm the HUD is visible and elements are correctly positioned:
   - **Compass bar** — visible at top/bottom of screen, not collapsed or misaligned
   - **Battery bar** and **Fuel gauge** — visible in expected HUD location
   - **Scanner readout** — visible when scanner is active (press scan key)
3. Activate the scanner — confirm the scanner readout appears with data
4. Begin mining a resource — confirm the **mining progress bar** appears and updates
5. Trigger the mining minigame — confirm the **mining minigame overlay** appears correctly positioned

**Expected result:** All HUD elements are correctly positioned, not squashed or displaced. No anchor-related layout regressions.

**Automated coverage:** `test_scene_properties_unit` — anchor values for CompassBar, MiningProgress, MiningMinigameOverlay verified (3 tests)

- [ ] ✅ Approved / ❌ Rejected — _Notes:_

---

### Ship Interior

---

#### Ship interior loads with all modules accessible (TICKET-0297, TICKET-0298, TICKET-0299)

**Verification Method:** `manual-playtest`

**What changed:** `ship_interior.gd` underwent the largest single refactor in M11 — 60+ persistent nodes moved from `_ready()` programmatic construction into the `.tscn` scene. `game_world.gd` persistent system node groups (6 groups) similarly refactored. `ship_status_display.gd` and `travel_sequence_manager.gd` also moved to `.tscn`-first.

**How to test:**
1. Board the ship from the exterior
2. Confirm the ship interior loads without errors
3. Navigate to each module zone and confirm they are accessible:
   - Fabricator
   - Recycler
   - Automation Hub
   - Navigation Console
   - Tech Tree terminal
4. Exit the ship and confirm the exterior world is intact

**Expected result:** Ship interior loads cleanly with all module zones present and interactable. No missing nodes or null reference errors.

**Automated coverage:** `test_ship_interior_unit`, `test_scene_properties_unit`

- [ ] ✅ Approved / ❌ Rejected — _Notes:_

---

### Main Menu

---

#### Main Menu loads and can start a new game (TICKET-0296)

**Verification Method:** `manual-playtest`

**What changed:** `main_menu.gd` refactored to `.tscn`-first. No UI layout or behavior changes.

**How to test:**
1. Launch the game via `res://game.tscn` (non-debug path)
2. Confirm the main menu appears
3. Press "New Game" (or equivalent) — confirm the game world loads

**Expected result:** Main menu displays correctly and starts a new game without errors.

**Automated coverage:** `test_scene_properties_unit` — scene structure verified

- [ ] ✅ Approved / ❌ Rejected — _Notes:_

---

## Known Open Issues

These issues exist as of the UAT sign-off date and are tracked separately. They do not block M11 close unless the Studio Head determines they are regressions introduced by M11 work.

| Ticket | Priority | Description | Status |
|--------|----------|-------------|--------|
| TICKET-0313 | P1 | All biomes: player spawns below/inside terrain on biome load with runtime error | OPEN — affects Shattered Flats, Rock Warrens, Debris Field; pre-existing |

---

## Rejection Notes

> Complete this section if any features are rejected.

| Feature | Ticket | Issue Description |
|---------|--------|-------------------|
| — | — | — |

---

## Final Sign-Off

**Total Features:** 9
**Approved:** —
**Rejected:** —

**Gate Condition:** All 9 features must be `✅ Approved` for sign-off to be granted.

---

**Studio Head Sign-Off:**

- [ ] All features approved — M11 is cleared for close

**Signed off by:** Studio Head
**Date:** YYYY-MM-DD
