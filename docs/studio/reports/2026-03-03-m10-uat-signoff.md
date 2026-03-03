# UAT Sign-Off — M10: Input & Feel Refinement

> **Template:** Populated by QA Engineer during the final QA phase, before requesting Studio Head sign-off.
>
> **Studio Head:** Review each feature below, play-test as described, then mark each checkbox.
> When all checkboxes are marked `✅ Approved`, reply to the Producer to grant final milestone sign-off.

---

## Header

| Field | Value |
|-------|-------|
| **Milestone** | M10 — Input & Feel Refinement |
| **Prepared By** | qa-engineer |
| **Date Prepared** | 2026-03-03 |
| **Test Build** | 0c5c02f (main branch — all 10 M10 implementation tickets merged) |
| **Sign-Off Status** | ✅ APPROVED — 15/15 UAT items approved by Studio Head (2026-03-03) |

---

## How to Use This Document

1. Launch the game from the Godot editor by pressing **Play** (F5) — this uses `game.tscn` as the project main scene.
2. For each feature, check the **Verification Method** tag:
   - `unit-test` — Covered by unit tests (automated, no manual action needed)
   - `integration-test` — Covered by integration or code review; no game-level action needed
   - **`manual-playtest`** — **Requires hands-on testing by Studio Head.** Follow the test steps.
3. For `manual-playtest` items, follow the **How to Test** steps.
4. Mark the checkbox:
   - `✅ Approved` — feature works as described, no blocking issues
   - `❌ Rejected` — feature is broken or missing; add a note describing the problem
5. Once all features are marked, sign off at the bottom of this document.

> **Note:** Items tagged `manual-playtest` require hands-on verification using a connected gamepad controller (Xbox or PlayStation). Have one available before testing gamepad-specific items.

---

## Feature Sign-Off Checklist

---

### Gamepad Input Remapping

---

#### Gamepad Interact — Reassigned from A to X (TICKET-0276)

**Verification Method:** `manual-playtest`

**What changed:** The `interact` action (board ship, interact with machines, pick up items) is now bound to `JOY_BUTTON_X` (Xbox X / PlayStation Square). Previously it was bound to A/Cross. `JOY_BUTTON_A` is now freed for other bindings (jump, use_item, ui_accept).

**How to test:**
1. Connect a gamepad. Launch the game to any biome (F5 → LAUNCH → Play).
2. Walk to the ship and stand near the boarding hatch.
3. Press the **X button** (Xbox) or **Square button** (PlayStation).
4. Confirm you **board the ship**.
5. Inside the ship, press **X/Square** again to exit.
6. Confirm pressing the **A button** (Xbox) does **not** trigger boarding (it should make you jump instead).
7. Confirm **keyboard E** still works for the same interact action.

**Expected result:** X/Square boards the ship. A/Cross no longer triggers interact. Keyboard E still works. Both X and E coexist.

**Automated coverage:** `test_input_manager_unit.gd` — `ping` action existence assertion confirms scan→ping rename; interact binding verified in code review (no automated hardware test possible).

- [x] ✅ Approved — no issues

---

#### Gamepad Jump — A Button (TICKET-0277)

**Verification Method:** `manual-playtest`

**What changed:** `JOY_BUTTON_A` (Xbox A / PlayStation Cross) is now bound to the `jump` action. Previously gamepad had no jump binding. Space bar jump is unchanged.

**How to test:**
1. With a gamepad connected, launch to any biome.
2. Press the **A button** (Xbox) or **Cross button** (PlayStation) while standing on the ground.
3. Confirm the player **jumps**.
4. Press **Space bar** on keyboard — confirm jump still works.
5. Confirm A/Cross jump works repeatedly without any stuck state.

**Expected result:** A/Cross makes the player jump in first-person. Space bar unchanged. No stuck-in-air bugs.

**Automated coverage:** Jump binding added to InputManager; unit tests confirm `jump` action is registered.

- [x] ✅ Approved — no issues

---

#### Gamepad Ping — LB (Left Bumper) (TICKET-0277)

**Verification Method:** `manual-playtest`

**What changed:** The `ping` action (formerly named `scan`) is now bound to `JOY_BUTTON_LEFT_SHOULDER` (LB / L1). Also renamed the input action from `"scan"` to `"ping"` across the entire codebase to match in-game terminology. Keyboard Q remains bound to ping.

**How to test:**
1. With a gamepad connected, launch to any biome with resource deposits visible.
2. Press **LB** (Xbox) or **L1** (PlayStation).
3. Confirm the scanner radial wheel opens (hold) or a ping fires (tap with last-used type if a type was previously selected).
4. Confirm compass markers appear for nearby deposits.
5. Tap **keyboard Q** — confirm ping also fires from keyboard.

**Expected result:** LB/L1 fires the scanner ping (or opens the radial wheel on hold). Keyboard Q unchanged. Compass shows deposit markers.

**Automated coverage:** `test_input_manager_unit.gd` — asserts `ping` action is registered (renamed from `scan`). `test_scanner_unit.gd` — scanner unit tests pass.

- [x] ✅ Approved — no issues

---

#### Gamepad Use Item — A Button in Inventory Context (TICKET-0278)

**Verification Method:** `manual-playtest`

**What changed:** `JOY_BUTTON_A` is now bound to `use_item`. In the inventory screen context, pressing A activates the selected item's use action (same as G on keyboard). A is shared across `jump` and `use_item` with context separation: `set_gameplay_inputs_enabled(false)` suppresses `jump` when the inventory UI is open.

**How to test:**
1. Launch with **Begin Wealthy** enabled (so inventory has items).
2. Open inventory (**I** key or gamepad Select).
3. Select an item slot using the gamepad D-pad or left stick.
4. Press the **A button** (Xbox).
5. Confirm the item actions popup appears (drop / destroy options).
6. Press **G** on keyboard for the same slot — confirm same popup appears.
7. Close inventory and press **A** in gameplay — confirm the player **jumps** (not inventory action).

**Expected result:** A/Cross triggers use_item when inventory is open. A/Cross jumps when inventory is closed. No cross-context conflicts.

**Automated coverage:** `test_input_manager_unit.gd` — action registration verified. Manual context-switch test required.

- [x] ✅ Approved — no issues

---

#### Gamepad Toggle Headlamp — RB (Right Bumper) (TICKET-0278)

**Verification Method:** `manual-playtest`

**What changed:** `JOY_BUTTON_RIGHT_SHOULDER` (RB / R1) is now bound to `toggle_head_lamp`. Previously gamepad had no headlamp binding. Keyboard F unchanged.

**How to test:**
1. With a gamepad connected, launch to any biome.
2. Press **RB** (Xbox) or **R1** (PlayStation).
3. Confirm the headlamp **toggles on** (environment brightens).
4. Press **RB/R1** again — confirm headlamp **toggles off**.
5. Press **F** on keyboard — confirm same toggle behavior.

**Expected result:** RB/R1 toggles headlamp on/off. Keyboard F unchanged. Battery UI reflects headlamp power draw.

**Automated coverage:** `test_head_lamp_unit.gd` — headlamp toggle behavior verified.

- [x] ✅ Approved — no issues

---

#### Gamepad Use Tool — RT (Right Trigger) for Mining (TICKET-0279)

**Verification Method:** `manual-playtest`

**What changed:** The `use_tool` action (hold to mine) now has a gamepad binding using `JOY_AXIS_TRIGGER_RIGHT` (RT / R2). Triggers are analog axes, not buttons — a 0.5 threshold activates the action. A new `_add_joy_axis_to_existing_action()` helper was added to InputManager for this. `interaction_prompt_hud.gd` was updated to show "RT" for axis-mapped actions.

**How to test:**
1. With a gamepad connected, launch to any biome.
2. Walk to a surface resource deposit (Scrap Metal or Cryonite node).
3. Approach the deposit until the interaction prompt appears.
4. **Hold RT** (Xbox) or **R2** (PlayStation) to mine.
5. Confirm the player begins mining (progress indicator advances, yield decreases).
6. **Hold left mouse button** — confirm same mining behavior on keyboard/mouse.
7. Confirm the interaction prompt shows **"RT"** (not "?" or a blank) when gamepad is the active device.

**Expected result:** RT/R2 held triggers mining. Left mouse button unchanged. HUD shows "RT" label when on gamepad.

**Automated coverage:** Trigger axis registration verified in code review. HUD label lookup updated to handle `InputEventJoypadMotion`.

- [x] ✅ Approved — no issues

---

#### HUD Button Labels — Dynamic Gamepad Glyphs After Device Switch (TICKET-0276 / TICKET-0278 / TICKET-0279)

**Verification Method:** `manual-playtest`

**What changed:** The interaction prompt HUD already used dynamic label resolution via `InputMap.action_get_events()`. With M10's new bindings (X for interact, A for jump/use_item, LB for ping, RB for headlamp, RT for use_tool), the HUD should now display the correct new glyph labels when a gamepad is active.

**How to test:**
1. Use **keyboard and mouse** — walk to a deposit. Confirm the interaction prompt shows keyboard labels (e.g., **"E"** for interact near ship, **"LMB"** or similar for mining).
2. Move the **right stick or press any face button** on the gamepad to switch input device.
3. Walk near the deposit again — confirm the interaction prompt now shows **"X"** for boarding the ship and **"RT"** for mining.
4. Walk near the ship and confirm **"X"** appears for the boarding action.
5. Switch back to keyboard (move mouse) — confirm labels revert to keyboard glyphs.
6. Confirm the **headlamp persistent hint** in the bottom-right HUD shows **"RB"** on gamepad and **"F"** on keyboard.

**Expected result:** All interaction prompt labels and persistent control hints dynamically update when switching between keyboard and gamepad. Correct M10 button names appear (X, RT, RB, LB, A).

**Automated coverage:** Label resolution logic confirmed via code audit — no hardcoded button strings found in any `.gd` or `.tscn` file outside the `_joy_button_name()` lookup table (which is the correct pattern).

- [x] ✅ Approved — no issues

---

### Ship Boarding Feel

---

#### Ship Boarding Requires Aiming at Ship Hull (TICKET-0280)

**Verification Method:** `manual-playtest`

**What changed:** Boarding the ship now requires the player to be pointing their camera at the ship's exterior mesh (not just standing near it). A raycast from the camera is performed against the ship's collision shape when `interact` is pressed. If the ray doesn't hit the ship, boarding does not trigger. This resolves D-034 (boarding from M9 UAT feedback).

**How to test:**
1. Launch to any biome and walk to the ship.
2. **Facing AWAY from the ship** (back to hull), stand in the old boarding trigger zone and press **E** (or gamepad X).
3. Confirm boarding does **NOT** trigger.
4. **Turn to face the ship hull** and press **E/X**.
5. Confirm you **board the ship**.
6. Test at several angles (front, side, slight diagonal) — confirm boarding works at any reasonable angle where the camera ray hits the exterior mesh.
7. Confirm all other interact targets (machines inside the ship, deposits, dropped items) are **unaffected** — they still work normally.

**Expected result:** Boarding only triggers when aiming at the ship exterior. Facing away or aiming at geometry between player and ship blocks boarding. All other interact targets work normally.

**Automated coverage:** None — raycast behavior requires manual play-test verification.

- [x] ✅ Approved — no issues

---

### Scanner Improvements

---

#### Scanner Radial Wheel — Resource Type Selection Before Ping (TICKET-0281)

**Verification Method:** `manual-playtest`

**What changed:** Holding the `ping` action (Q / LB) now opens a radial wheel letting the player select which resource type to ping for. Releasing fires a ping filtered to the selected type. Tapping ping without holding fires immediately with the last-used type. The wheel shows one segment per resource type (currently Scrap Metal and Cryonite) with icons. Mouse direction selects on keyboard; left stick selects on gamepad. This resolves D-001.

**How to test:**
1. Launch to a biome with multiple deposit types (e.g., Rock Warrens has both Cryonite and Scrap Metal).
2. **Hold Q** on keyboard for more than 0.2 seconds — confirm the radial wheel appears with two resource segments (Scrap Metal and Cryonite).
3. **Move the mouse** to aim at the Cryonite segment.
4. **Release Q** — confirm only **Cryonite** markers appear on the compass.
5. Repeat holding Q, select Scrap Metal — confirm only **Scrap Metal** markers appear on compass.
6. **Tap Q quickly** (under 0.2s) — confirm ping fires immediately with the last-used resource type (no wheel shown).
7. With a gamepad: **hold LB** — confirm wheel opens. Move **left stick** to select type. Release to ping.
8. Confirm ping cooldown still applies between consecutive pings.

**Expected result:** Hold to open wheel, release to fire filtered ping. Tap to fire immediately with last type. Wheel works with both mouse and left stick. Ping cooldown enforced.

**Automated coverage:** `test_scanner_unit.gd` — scanner state machine and ping flow tests pass. Manual playtest required to verify wheel UI and input behavior.

- [x] ✅ Approved — no issues

---

#### Animated Ping Ring with Progressive Compass Reveal (TICKET-0282)

**Verification Method:** `manual-playtest`

**What changed:** The scanner ping is now animated. A visible ring originates at the player and expands outward at 100 m/s up to a 1000 m range limit (10 seconds to full expansion). Compass markers appear only as the expanding ping front reaches each deposit — not all at once. This gives a spatial sense of the ping sweeping outward. This resolves D-015.

**How to test:**
1. Launch to a biome with deposits spread at varying distances.
2. Fire a ping (tap Q / LB or select type from wheel).
3. Observe a **ring expanding outward** from the player's position on the ground plane.
4. Watch the compass — deposit markers should appear **one by one** as the ring passes their location, not all simultaneously.
5. Deposits closer to the player should appear on the compass **before** deposits further away.
6. Wait or fire multiple pings — confirm the ring fades at the 1000 m limit.
7. Confirm the ping **cooldown still applies** from the moment ping fires (not when the ring finishes expanding).
8. Confirm previously existing compass/HUD code still works normally after the ping completes.

**Expected result:** Animated ring visible. Compass markers reveal progressively as ring reaches deposits. Far deposits appear later than close ones. Ring fades at 1000 m. Cooldown starts at ping fire.

**Automated coverage:** `test_scanner_unit.gd` — `ping_range_is_1000` assertion confirms PING_RANGE = 1000.0 m (updated from 320 m in TICKET-0282). Progressive reveal timing is manual-only.

- [x] ✅ Approved — no issues

---

### Orchestrator Tooling

> This item is backend orchestrator infrastructure. No in-game playtesting is required. Verification is by code audit.

---

#### Orchestrator --max-turns Replaces Dead USD Budget Caps (TICKET-0283)

**Verification Method:** `integration-test`

**What changed:** `budget_usd` fields and `get_budget()` in `conductor.py` were dead code — the Claude CLI has no `--budget` flag and the values only gated a hardcoded `--max-turns 200`. Replaced with configurable per-agent `max_turns` limits in `config.json`. All dispatch paths now unconditionally pass `--max-turns <agent_max_turns>`. Defaults: gameplay-programmer=150, qa-engineer=100, producer=25, all others=75. This resolves D-033.

**Expected result:** Confirmed — `config.json` contains `max_turns` section (no `budget_usd` fields remain), `conductor.py` has no `get_budget()` function, and all dispatch paths pass `--max-turns`. Agent runs in M10 received correct per-agent turn limits.

**Automated coverage:** Code audit — zero `budget_usd` or `get_budget` references remain in the orchestrator. M10's multi-wave run (7+ waves) confirms dispatch operates correctly with the new config.

- [x] ✅ Approved — no issues

---

### Producer Decisions

> This item is a producer workflow outcome. No in-game playtesting is required.

---

#### D-007 Requirements Interview — Resource Respawn Design Confirmed (TICKET-0284)

**Verification Method:** `integration-test`

**What changed:** The Producer interviewed the Studio Head to finalize D-007 (resource respawn requirements). Decisions recorded: in-biome timed respawn desired (each node tracks its own timer from depletion); default 300 s configurable per resource type; deep nodes excluded; no resource scarcity pressure goal at this phase. TICKET-0286 was created to implement these requirements and is now DONE. D-007 status updated in `docs/studio/deferred-items.md`.

**Expected result:** Confirmed — TICKET-0286 is DONE. `deferred-items.md` shows D-007 as Scheduled → TICKET-0286. Design decisions are recorded in TICKET-0284 activity log.

**Automated coverage:** Process artifact — no automated tests. Implementation covered by TICKET-0286 below.

- [x] ✅ Approved — no issues

---

### Resource Gameplay

---

#### In-Biome Timed Resource Node Respawn (TICKET-0286)

**Verification Method:** `manual-playtest`

**What changed:** Resource deposits now respawn after a configurable per-type delay (default 300 seconds / 5 minutes) when fully mined. A depleted deposit hides its mesh and disables its collision shape but remains in the scene tree so it can track its own respawn timer. When the timer expires the deposit becomes fully mineable again. Deep resource nodes (infinite yield) are unaffected. Depleted nodes are excluded from scanner pings and compass markers (already handled by existing `is_depleted()` filters). Config is in `game/config/resource_respawn_config.gd`. This resolves D-007.

**How to test (deposit depletion and respawn):**
1. Launch to any biome with **Begin Wealthy** disabled.
2. Find a small surface deposit (Scrap Metal or Cryonite node) — surface nodes have limited yield.
3. **Hold LMB / RT** to mine it until fully depleted.
4. Confirm the deposit **disappears** (mesh hidden, no interaction prompt, no collision).
5. For a quick test: open `game/config/resource_respawn_config.gd` in a text editor and **temporarily reduce** the respawn time to `5` (5 seconds) for the resource type you mined. Save and reload the scene.
6. After ~5 seconds, confirm the deposit **reappears** and is fully mineable again.
7. Restore the respawn time to `300` after testing.

**How to test (deep nodes unaffected):**
1. In Rock Warrens or Debris Field, find a **deep resource node** (the large submerged deposits mineable only by drone — they appear as partially-buried larger formations).
2. Confirm you **cannot** start a respawn timer on a deep node — they have unlimited yield and never deplete.

**How to test (compass ping exclusion):**
1. Mine a surface deposit to depletion (it disappears).
2. Fire a scanner ping (Q / LB).
3. Confirm the **depleted deposit does NOT appear** as a compass marker.
4. Confirm **other active deposits** still appear as compass markers normally.

**Expected result:** Depleted deposits disappear and reappear after their configured respawn timer. Deep nodes never deplete or respawn. Depleted deposits excluded from scanner results and compass. Config is in a dedicated file (no magic numbers in game logic).

**Automated coverage:** `test_resource_respawn_unit.gd` (biome-change system) and `test_deposit_unit.gd` (deposit state machine) confirm related behavioral contracts. Timed respawn behavior requires manual verification due to timer dependency.

- [x] ✅ Approved — no issues

---

### Bug Fixes

---

#### Ping Radial Wheel — Renders at Screen Center (TICKET-0287)

**Verification Method:** `manual-playtest`

**What changed:** The resource-type radial wheel was rendering at the upper-left corner of the screen (position 0, 0) instead of the screen center. The `ResourceTypeWheel` Control node's anchor and offset settings were corrected so the wheel centers itself on the viewport. No logic changes — purely a UI layout fix.

**How to test:**
1. Launch to any biome (F5 → LAUNCH → Play).
2. **Hold Q** on keyboard (or **LB** on gamepad) for more than 0.2 seconds.
3. Observe where the radial wheel appears.
4. Confirm the wheel appears at the **center of the screen**, not the upper-left corner.
5. Move the mouse (or left stick) to select a resource type and release to ping — confirm the wheel closes and ping fires normally.

**Expected result:** Radial wheel renders at viewport center when activated. All selection and ping-fire behavior is unchanged.

**Automated coverage:** UI position is a layout property — no unit test. Manual playtest required. Regression guard: confirmed no `position = Vector2.ZERO` or explicit offset assignments in `resource_type_wheel.gd` outside the anchor/centering logic.

- [x] ✅ Approved — no issues

---

#### Compass Distance Cone — Resource Label Only Near Compass Center (TICKET-0288)

**Verification Method:** `manual-playtest`

**What changed:** The resource distance readout label on the compass previously appeared for any resource marker, regardless of how far it was from compass center. It now only appears when the marker is within 3× the ping icon width of the compass center point. Ship distance label behavior is unchanged (it always shows). This focuses the distance information on the most relevant nearby resource and reduces HUD clutter.

**How to test:**
1. Launch to a biome with resource deposits at varying distances.
2. Fire a scanner ping (tap Q / LB).
3. Observe the compass — resource markers appear progressively as the ping ring expands.
4. **At the compass center:** a resource marker that is nearly directly ahead (within 3× ping icon width of center) should show its **distance label** (e.g., "142 m").
5. **Toward the edges of the compass:** resource markers far from the center should show the **marker icon only** — no distance label.
6. Rotate the player so a distant resource marker drifts toward compass center — confirm the **distance label appears** as it enters the cone.
7. Rotate away — confirm the distance label **disappears** as the marker exits the cone.
8. Verify the **ship distance label** still appears at all times when the ship marker is on the compass (not limited by the cone).

**Expected result:** Resource distance label visible only when marker is within 3× ping icon width of compass center. Ship distance label always visible. Marker icon visible at all compass positions.

**Automated coverage:** `test_compass_bar_unit.gd` covers compass marker logic. The cone threshold is a display-layer property — manual playtest required to verify label visibility at range boundaries.

- [x] ✅ Approved — no issues

---

## Rejection Notes

> List any rejected features here with detail. QA Engineer will triage and open bug tickets.

| Feature | Ticket | Issue Description |
|---------|--------|-------------------|
| — | — | — |

---

## Final Sign-Off

> Complete this section after all checkboxes above are marked.

**Total Features:** 15
**Approved:** 15
**Rejected:** 0

**Gate Condition:** All 15 features must be `✅ Approved` for sign-off to be granted.

---

**Studio Head Sign-Off:**

- [x] All features approved — milestone is cleared for close

**Signed off by:** Studio Head
**Date:** 2026-03-03
