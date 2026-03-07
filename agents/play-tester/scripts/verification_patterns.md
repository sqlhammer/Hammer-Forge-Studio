# Verification Patterns

Common verification patterns for the play-tester agent. Each pattern describes a scenario type, the MCP tool sequence, and what to check.

---

## Pattern: Spawn Position Check

**Use when:** Verifying player spawns correctly (on floor, correct position, not clipping).

**Steps:**
1. `clear_output_logs`
2. `play_scene("res://scenes/gameplay/game_world.tscn")` — launches with default biome
3. Wait 3 seconds for biome generation
4. `get_running_scene_screenshot()` — check first-person view shows terrain at eye level (not underground)
5. `simulate_input("debug_state_dump", "press")`
6. `get_godot_errors()` — parse state dump

**Assert:**
- Screenshot shows terrain surface from player's eye level, not sky from below terrain
- `PLAYER_POS` Y > 0
- `PLAYER_ON_FLOOR` = true
- `PLAYER_VELOCITY` Y is near 0 (not falling)
- No ERROR lines in console

---

## Pattern: Player Movement

**Use when:** Verifying player can move through the world.

**Steps:**
1. After spawn check, capture initial `PLAYER_POS`
2. `simulate_input("move_forward", "press")` — hold for movement
3. Wait 2 seconds
4. `simulate_input("move_forward", "release")`
5. `get_running_scene_screenshot()` — visual shows different view
6. `simulate_input("debug_state_dump", "press")`
7. `get_godot_errors()` — parse new position

**Assert:**
- `PLAYER_POS` has changed from initial position (Z or X delta)
- `PLAYER_ON_FLOOR` still true
- Screenshot shows different scene from initial spawn point

---

## Pattern: Biome Load via DebugLauncher

**Use when:** Verifying a specific biome loads correctly (not default).

**Steps:**
1. `play_scene("res://scenes/gameplay/game.tscn")` — opens DebugLauncher
2. `get_running_scene_screenshot()` — confirm DebugLauncher UI is visible
3. Navigate to biome dropdown via `simulate_input`:
   - Use keyboard: Tab to cycle to dropdown, arrow keys to select biome, Enter to confirm
   - Or interact with the DebugLauncher buttons directly
4. Activate the "LAUNCH" button
5. Wait 3-5 seconds for biome generation
6. `get_running_scene_screenshot()` — confirm game world loaded
7. `simulate_input("debug_state_dump", "press")`
8. `get_godot_errors()` — verify `BIOME` matches expected

**Assert:**
- `BIOME` matches the selected biome name
- Player is spawned correctly (see Spawn Position Check)
- No ERROR lines

---

## Pattern: Interaction Verification

**Use when:** Verifying an interact-triggered behavior (e.g., opening a menu, using a machine).

**Steps:**
1. Move player near the target object using `simulate_input` movement actions
2. `get_running_scene_screenshot()` — confirm interaction prompt is visible on HUD
3. `simulate_input("interact", "press")` then release
4. Wait 1 second
5. `get_running_scene_screenshot()` — confirm UI/menu opened or action occurred
6. `simulate_input("debug_state_dump", "press")`
7. `get_godot_errors()` — check for state changes

**Assert:**
- Screenshot shows the expected UI/menu or state change
- State dump reflects the interaction result
- No ERROR lines

---

## Pattern: Inventory Operation

**Use when:** Verifying items appear in inventory or inventory counts change.

**Steps:**
1. Spawn in game (optionally with begin-wealthy via DebugLauncher)
2. `simulate_input("debug_state_dump", "press")` — baseline inventory count
3. `get_godot_errors()` — record `INVENTORY_USED` value
4. Perform the action that should change inventory (mine, craft, pick up)
5. `simulate_input("debug_state_dump", "press")` — post-action dump
6. `get_godot_errors()` — compare `INVENTORY_USED`
7. `simulate_input("inventory_toggle", "press")` — open inventory UI
8. `get_running_scene_screenshot()` — visual confirmation of items

**Assert:**
- `INVENTORY_USED` changed as expected
- Inventory UI screenshot shows expected items
- No ERROR lines

---

## Pattern: Unit Test Suite

**Use when:** Every VERIFY ticket (mandatory).

**Steps:**
1. `play_scene("res://addons/hammer_forge_tests/test_runner.tscn")`
2. Wait 10-15 seconds for test suite to complete (large suites take time)
3. `get_godot_errors()` — read test output
4. Look for the summary line: `Results: N passed, M failed, K skipped`
5. `stop_running_scene()`

**Assert:**
- 0 failures
- 0 errors
- All expected tests ran (count matches known total if available)

---

## Pattern: No Runtime Errors

**Use when:** Every VERIFY scenario (check at every step).

After each `get_godot_errors()` call, scan for lines containing:
- `ERROR`
- `SCRIPT ERROR`
- `Push Error`
- `Condition "...is true" is true`

Any of these indicate a runtime error that should be logged as a finding, even if the visual verification passes. Runtime errors in non-critical paths should be noted as P2/P3 findings.
