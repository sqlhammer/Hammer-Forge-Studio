# QA System Audit & Improvement Plan

## Implementation Status

| # | Item | Status | File(s) |
|---|---|---|---|
| 1 | Scene Property Validation Tests | DONE | `game/tests/test_scene_properties_unit.gd` |
| 2 | Ship collision shape guard | DONE | Included in #1 (`ship_exterior_no_box_collision` spec) |
| 3 | Feature Spec Template | DONE | `docs/studio/templates/feature-spec.md` |
| 4 | Integration test convention | READY | Naming convention established; first tests pending M9 |
| 5 | Async test runner | DONE | `game/addons/hammer_forge_tests/test_suite.gd:187` + `test_runner.gd` await chain |
| 6 | Mid-milestone QA checkpoints | DONE | `docs/studio/templates/phase-gate-regression-template.md` Section 8 added |
| 7 | UAT verification method column | DONE | `docs/studio/templates/uat-signoff.md` updated |
| 8 | Playtest script authoring | DONE | `docs/qa/playtest-scripts/` (3 core loop scripts) |
| 9 | Scene property mandate in tickets | READY | Process enforcement — producer-level |
| 10 | Autonomous playthrough execution | BLOCKED | Requires T3 (TICKET-0236) |
| 11 | Visual regression baselines | BLOCKED | Requires T3 |
| 12 | CI playthrough gate | BLOCKED | Requires CI infrastructure |

---

## Context

Despite 879 passing tests, TDD discipline, phase gates, and a dedicated QA phase, the Studio Head consistently finds **completely non-functional features** at milestone sign-off. Post-M7 required 4 hotfix tickets (TICKET-0152, 0154, 0155, 0156) for broken HUD anchors, regressed collision shapes, and missing interaction wiring. These are not edge cases — they are core gameplay defects that any player would hit in the first 30 seconds.

This plan diagnoses why and prescribes specific, actionable fixes sequenced by impact.

---

## Part 1 — Root Cause Summary

1. **Unit tests validate API contracts, not player-observable outcomes.** All 879 tests exercise method return values, signal emissions, and state transitions on isolated instances. None verify that calling `NavigationSystem.initiate_travel()` results in the player standing in a new biome with working controls. Only 2 of 45 test files are multi-system integration tests.

2. **Scene metadata is the single largest unguarded attack surface.** All four M7 hotfixes were `.tscn` file properties: anchor presets reset to `ANCHOR_BEGIN` (TICKET-0152, 0156), collision shapes regressed from VHACD convex hulls to `BoxShape3D` (TICKET-0154), and an `Area3D` not wired to the interaction prompt group (TICKET-0155). Zero tests in the suite read scene files or query instantiated scene-tree properties.

3. **The QA agent cannot execute the test plan it writes.** The M7 QA sign-off (`docs/qa/reports/2026-02-26-m7-qa-signoff.md`) explicitly marks manual playtest items as untested due to "headless environment limitation." The regression checklist maps items to unit test suites (e.g., "Compass bar centered — PASS (test_compass_bar_unit 15/15)") but that test checks math, not visual position. The QA agent has `play_scene` and `simulate_input` in its tool spec but has never used them.

4. **QA is structurally siloed into the final phase.** M8 phases are TDD Foundation → Foundation → Gameplay → QA. QA writes test scaffolds in phase 1 then waits. By the final phase, all defects catchable by unit tests are caught, and all defects that unit tests *cannot* catch (scene-level, integration, visual) are invisible to the process.

5. **Self-validation creates an unfalsifiable loop.** The same qa-engineer writes tests, runs tests, declares coverage met, writes the UAT sign-off, and recommends milestone close. The M8 QA sign-off maps "Player mines Scrap Metal and Cryonite" to 90 tests and calls it PASS — but no agent ever verified this flow end-to-end in the actual game.

---

## Part 2 — Test Suite Gap Table

| Feature Area | Missing Test Type | Specific Scenario | File Path | Framework Tool |
|---|---|---|---|---|
| **Navigation Console UI** | Scene property validation | `.tscn` anchors and layout presets match spec (prevents TICKET-0152 class) | `game/tests/test_scene_properties_unit.gd` | `load()` scene → instantiate → query `anchors_preset`, `anchor_left`, `offset_*` on root Control |
| **Navigation Console UI** | Integration flow | Open console → select destination → confirm → verify biome changed AND player inputs re-enabled | `game/tests/test_navigation_flow_integration.gd` | Real `NavigationSystem` + `FuelSystem` + `TravelSequenceManager` + `InputManager` in scene tree; assert state after full sequence |
| **Biome Travel** | End-to-end integration | `initiate_travel()` → scene swap → player position valid → camera reset → inputs re-enabled → player can walk | `game/tests/test_travel_end_to_end_integration.gd` | Instantiate `TravelSequenceManager` with real biome container; verify `global_position` and `InputManager.is_gameplay_inputs_enabled()` |
| **Fuel System** | Cross-system integration | Full tank → travel → fuel consumed → travel again → insufficient fuel blocks travel | `game/tests/test_fuel_navigation_integration.gd` | Chain `FuelSystem` + `NavigationSystem` with real signal wiring; assert fuel level and `can_travel_to()` after two trips |
| **Ship Exterior Collision** | Scene property validation | Collision shapes are `ConvexPolygonShape3D` or `ConcavePolygonShape3D`, NOT `BoxShape3D` (prevents TICKET-0154) | `game/tests/test_scene_properties_unit.gd` | Load `res://scenes/objects/ship_exterior.tscn` → walk `CollisionShape3D` children → assert shape type |
| **Ship Interior Exit** | Scene wiring validation | Exit zone `Area3D` is in group `interaction_prompt_source` (prevents TICKET-0155) | `game/tests/test_scene_properties_unit.gd` | Load `res://scenes/gameplay/ship_interior.tscn` → find exit zone → `assert_true(node.is_in_group(...))` |
| **HUD Layout** | Scene property validation | All HUD children in `game_hud.tscn` have correct anchor presets (prevents TICKET-0152, 0156 class) | `game/tests/test_scene_properties_unit.gd` | Data-driven: array of `{scene, node_path, property, expected}` specs; loop and assert |
| **Procedural Terrain** | Physics integration | Generated terrain with `ConcavePolygonShape3D` → place `CharacterBody3D` at spawn → step physics → Y position stable (not falling through) | `game/tests/test_terrain_walkability_integration.gd` | Instantiate biome → `generate()` → place body → `move_and_slide()` → assert Y ≈ spawn Y |
| **Deep Resource Nodes** | Scene validation | `DeepResourceNode` scene has a `MeshInstance3D` child (visual indicator exists) | `game/tests/test_scene_properties_unit.gd` | Load scene → find `MeshInstance3D` descendant → `assert_not_null()` |
| **Headlamp HUD** | Scene property validation | Persistent controls panel anchor is bottom-right | `game/tests/test_scene_properties_unit.gd` | Load `res://scenes/ui/interaction_prompt_hud.tscn` → query anchor presets |
| **Mouse Interaction** | Input event integration | `InputEventMouseButton` at button rect center → button `pressed` signal fires | `game/tests/test_mouse_click_integration.gd` | Create Control node → calculate `get_global_rect()` → dispatch `InputEventMouseButton` → assert via SignalSpy |

---

## Part 3 — QA Role Improvement Recommendations

### 1. Scene Property Validation Tests (New Test Category)

**What:** A data-driven test file that loads `.tscn` files and asserts on node properties — anchor presets, collision shape types, group membership, node existence. Uses an inner class `ScenePropertySpec` with `scene_path`, `node_path`, `property_checks: Dictionary`.

**Who:** qa-engineer writes and maintains. Implementing agents provide expected values in ticket ACs.

**Where:** `game/tests/test_scene_properties_unit.gd` (centralized, data-driven).

**When:** Runs at every phase gate as part of the standard headless test suite. No new infrastructure needed.

**Reference patterns:** `test_collision_coverage_unit.gd` (parameterized `ModelConfig` inner class, `_build_model_configs()` registry), `test_deep_resource_node_scene.gd` (scene instantiation via `add_child()`, property assertions).

### 2. Mid-Milestone QA Checkpoints

**What:** QA runs the scene validation + integration smoke tests at every phase gate, not just the final QA phase. `docs/studio/templates/phase-gate-regression-template.md` gains Section 8: "Scene Property Validation" with a mandatory pass/fail row.

**Who:** Producer adds checkpoint to phase definitions. QA engineer executes.

**Where:** Updated `docs/studio/templates/phase-gate-regression-template.md`.

**When:** At every phase gate boundary. Gate pass conditions in CLAUDE.md gain a fifth bullet: "Scene property validation tests pass with zero failures."

### 3. Integration Test Convention

**What:** New naming convention `test_<system>_integration.gd`. These tests instantiate multiple real systems (not mocks), connect real signals, and verify multi-step flows. TDD process doc gains an "Integration Coverage Target" column (minimum 1 integration test per multi-system feature).

**Who:** Implementing agent writes integration tests during Green phase. QA engineer reviews for coverage.

**Where:** `game/tests/test_<system>_integration.gd` files. Coverage targets added to `docs/studio/tdd-process-m8.md`.

**When:** Every test suite run. Test runner discovers them automatically (already matches `test_*.gd` glob).

### 4. UAT Verification Method Column

**What:** UAT sign-off template gains a "Verification Method" column per feature: `unit-test`, `scene-validation`, `integration-test`, or `manual-playtest`. Items marked `manual-playtest` are highlighted for the Studio Head so they know exactly what was NOT verified by automation.

**Who:** QA engineer fills the column. Systems-programmer validates accuracy before Studio Head review.

**Where:** Updated `docs/studio/templates/uat-signoff.md`.

**When:** After QA writes the UAT, before Producer submits for Studio Head review.

### 5. Feature Ticket Scene Property Mandate

**What:** Every ticket that creates or modifies a `.tscn` file must include a "Scene Property Assertions" section listing exact node paths and expected property values. These become test data for `test_scene_properties_unit.gd`.

**Who:** Ticket creator (Producer) includes placeholder section. Implementing agent fills in actual values before marking DONE.

**Where:** Ticket acceptance criteria sections in `tickets/<milestone>/`.

**When:** At ticket creation (placeholder) and ticket completion (filled values, test written).

### 6. Structured Playtest Scripts

**What:** Replace free-form regression checklist items with step-by-step playtest scripts: launch scene → input → assert state → input → assert. Machine-executable when Godot MCP is available; human-readable for Studio Head when not.

**Who:** QA engineer authors. Producer validates coverage against feature list.

**Where:** `docs/qa/playtest-scripts/<feature>.yaml` (declarative) and `game/tests/test_<feature>_playtest.gd` (executable).

**When:** QA phase of every milestone. Until T3 (parallel Godot MCP) completes, scripts serve as structured playtest documentation for the Studio Head.

### 7. Async Test Runner Support

**What:** Change `test_suite.gd:187` from `test_callable.call()` to `await test_callable.call()` to support integration tests that need frame delays (`await get_tree().create_timer(0.1).timeout`).

**Who:** systems-programmer (one-line change).

**Where:** `game/addons/hammer_forge_tests/test_suite.gd` line 187.

**When:** M9 Foundation phase (prerequisite for integration tests that involve physics steps or signal propagation delays).

---

## Part 4 — Autonomous Playthrough Agent Design

### Agent Name: `playtest-agent`

### Role
Autonomously executes the game via Godot MCP tools, validates feature flows against declarative playthrough scripts, and auto-files BUG tickets on failure. Complements (does not replace) the unit test suite.

### Tool Access Required

| Tool | Source | Purpose |
|---|---|---|
| `play_scene(path)` | Godot MCP Tier 2 | Launch game scenes |
| `stop_running_scene()` | Godot MCP Tier 2 | Reset between scripts |
| `simulate_input(action, type)` | Godot MCP Tier 2 | Drive player actions |
| `get_scene_tree()` | Godot MCP Tier 1 | Assert on node state |
| `get_running_scene_screenshot()` | Godot MCP Tier 1 | Visual evidence capture |
| `get_godot_errors()` | Godot MCP Tier 1 | Runtime error capture |
| `execute_editor_script(gdscript)` | Godot MCP (needs QA access grant) | Query runtime properties (`global_position`, visibility, fuel level) |
| File write: `tickets/`, `docs/qa/` | Existing QA permissions | File BUG tickets and playtest reports |

**Delta from current qa-engineer Tier 1+2:** Only `execute_editor_script` is new — needed to query runtime state during play.

### Playthrough Script Format

```yaml
# docs/qa/playtest-scripts/navigate-to-rock-warrens.yaml
name: "Navigate to Rock Warrens"
scene: "res://scenes/debug/debug_launcher.tscn"
preconditions:
  - "NavigationSystem.current_biome == 'shattered_flats'"
  - "FuelSystem.fuel_current == FuelSystem.fuel_max"
steps:
  - action: simulate_input
    input: { action: "interact", type: "press" }
    context: "Open navigation console at cockpit"
    wait_after_seconds: 0.5
  - action: assert_state
    query: "get_node('/root/GameHUD/NavigationConsole').visible"
    expected: true
    failure_message: "Navigation console should be visible after interact"
  - action: execute_script
    gdscript: "NavigationConsole._select_biome('rock_warrens')"
    context: "Select Rock Warrens destination"
  - action: simulate_input
    input: { action: "ui_accept", type: "press" }
    context: "Confirm travel"
    wait_after_seconds: 3.0
  - action: assert_state
    query: "NavigationSystem.current_biome"
    expected: "rock_warrens"
    failure_message: "Should have arrived at Rock Warrens"
  - action: assert_state
    query: "InputManager.is_gameplay_inputs_enabled()"
    expected: true
    failure_message: "Gameplay inputs should be re-enabled after travel"
  - action: screenshot
    label: "post-travel-rock-warrens"
on_failure:
  file_bug: true
  severity: P1
  owner: gameplay-programmer
  tags: [navigation, travel, integration]
```

### BUG Ticket Auto-Population Template

On playthrough step failure, the agent generates:

```markdown
---
id: TICKET-NNNN
title: "[PLAYTEST] {failure_message}"
type: BUG
status: OPEN
priority: {on_failure.severity}
owner: {on_failure.owner}
created_by: playtest-agent
milestone: {current_milestone}
tags: {on_failure.tags}
---

## Summary
Automated playthrough "{script_name}" failed at step {step_index}.

## Reproduction Steps
{steps 1..step_index rendered as numbered list}

## Expected Behavior
{step.expected}

## Actual Behavior
{actual_value_or_error}

## Evidence
- Screenshot: {screenshot_path}
- Godot errors: {error_log}
- Playthrough script: {script_file_path}

## Activity Log
- {timestamp} — playtest-agent — Filed automatically from playthrough failure
```

### Coverage Complement

| Defect Class | Unit Tests | Scene Validation | Integration Tests | Playthrough Agent |
|---|---|---|---|---|
| Wrong return value | Yes | — | — | — |
| Signal not emitted | Yes | — | Yes | Yes (indirect) |
| Anchor/layout wrong | — | Yes | — | Yes (screenshot) |
| Collision shape type wrong | — | Yes | — | Yes (player falls) |
| Node wiring missing | — | Yes | — | Yes (feature broken) |
| Multi-system sequencing | — | — | Yes | Yes |
| Input not handled | — | — | Partial | Yes |
| Visual regression | — | — | — | Yes (screenshot) |
| Async race condition | — | — | Partial | Yes |

### Phase Gate Integration

- **Smoke subset** runs at every phase gate (2-3 scripts covering core loops: mine, craft, travel).
- **Full suite** runs at QA phase gate.
- Gate pass condition: All playthrough scripts pass, OR all failures have been triaged as BUG tickets with Studio Head approval to proceed.

### Feasibility

- **Requires T3 (Parallel Godot MCP, TICKET-0236).** The QA agent needs a running Godot instance to use `play_scene`/`simulate_input`. T3 gives each agent its own headless Godot on a unique port pair.
- **Headless limitation:** `--headless` disables rendering but processes scene tree, physics, and input. `simulate_input` dispatches through the normal pipeline. `get_running_scene_screenshot()` requires a display server — screenshots won't work headless.
- **Pre-T3 workaround:** Playthrough scripts serve as structured documentation for the Studio Head. The YAML format is human-followable.

---

## Part 5 — Feature Specification Standard Template

To be placed at `docs/studio/templates/feature-spec.md`:

```markdown
# Feature Specification — [Feature Name]

**Ticket:** TICKET-NNNN
**Author:** [agent-slug]
**Testability Reviewed By:** [qa-engineer or systems-programmer]
**Status:** Draft / Approved / Implemented

---

## 1. Overview

One paragraph: what does this feature do from the player's perspective?

---

## 2. Acceptance Criteria

Numbered. Each criterion is independently testable.

1. [Criterion — include concrete values, not vague language]
2. ...

---

## 3. Input/Output Contracts

### Public API

| Method / Signal | Input | Output | Side Effects |
|---|---|---|---|
| `SystemName.method(param: Type)` | Description | Return type | State changes, signals emitted |

### Signals

| Signal | Emitter | Payload | When Emitted |
|---|---|---|---|
| `signal_name` | `ClassName` | `(param: Type)` | Condition |

---

## 4. State Machine (if applicable)

| State | Entry Condition | Exit Condition | Invariants |
|---|---|---|---|

---

## 5. UI State Machine (if applicable)

| UI State | Visible Elements | Disabled Elements | Transitions |
|---|---|---|---|

---

## 6. Scene Property Assertions

Properties that must hold in committed `.tscn` files. These become test data.

| Scene Path | Node Path | Property | Expected Value |
|---|---|---|---|
| `res://scenes/ui/example.tscn` | `Root/ChildNode` | `anchors_preset` | `5` |

---

## 7. Failure States

| Condition | Expected Behavior | Test Strategy |
|---|---|---|
| Null input | Return default / emit error | Unit test |
| Insufficient resource | Block action, show warning | Unit + integration |

---

## 8. Testability Gate

Before implementation begins, ALL must be confirmed:

- [ ] Every acceptance criterion maps to at least one test (unit, scene validation, or integration)
- [ ] Scene property assertions filled for every `.tscn` created or modified
- [ ] At least one integration test scenario defined for multi-system features
- [ ] Failure states enumerated with test strategies

**Reviewed by:** _______________  **Date:** _______________

---

## 9. Traceability Matrix

| AC # | Unit Test | Scene Validation | Integration Test | Playtest Step | Regression Item |
|---|---|---|---|---|---|
| 1 | `test_foo_unit::test_bar` | `test_scene_properties::foo_anchor` | `test_foo_integration::flow` | `navigate.yaml` step 4 | Regression #42 |

---

## 10. Implementation Notes

Technical notes for the implementing agent.
```

### Enforcement

- Producer includes a blank feature-spec section in every FEATURE and TASK ticket at creation
- `testability_reviewed: true` added to ticket frontmatter as a prerequisite for `status: IN_PROGRESS`
- QA engineer or systems-programmer reviews the spec and signs the testability gate before work begins

---

## Part 6 — Implementation Roadmap

Prioritized by impact/effort. Highest-impact, lowest-effort items first.

### Phase 1: Quick Wins (Adopt at M9 Kickoff)

| # | Item | Impact | Effort | Owner |
|---|---|---|---|---|
| 1 | **Scene Property Validation Tests** — Create `test_scene_properties_unit.gd`. Data-driven specs for HUD anchors, collision shapes, group wiring. Directly prevents the entire M7 hotfix class. | HIGH | LOW — pattern exists in `test_collision_coverage_unit.gd` and `test_deep_resource_node_scene.gd` | qa-engineer |
| 2 | **Ship collision shape guard** — Assert `ship_exterior.tscn` shapes are not `BoxShape3D` | HIGH | VERY LOW — 5-line test addition to #1 | qa-engineer |
| 3 | **Feature Spec Template** — Deploy `docs/studio/templates/feature-spec.md` with traceability matrix and scene property section. Mandate for all M9 tickets. | MEDIUM | LOW — one markdown file | producer |

### Phase 2: Foundation (M9 Foundation Phase)

| # | Item | Impact | Effort | Owner |
|---|---|---|---|---|
| 4 | **Integration test convention** — Establish `test_<system>_integration.gd` naming. Write first integration tests for navigation flow and fuel-travel chain. Add coverage targets to TDD doc. | HIGH | MEDIUM | qa-engineer + gameplay-programmer |
| 5 | **Async test runner** — Change `test_suite.gd:187` to `await test_callable.call()` for async integration tests | MEDIUM | LOW — one-line change | systems-programmer |
| 6 | **Mid-milestone QA checkpoints** — Scene validation at every phase gate, not just QA phase. Update regression template. | MEDIUM | LOW — template update | producer + qa-engineer |

### Phase 3: Process (M9 Gameplay Phase)

| # | Item | Impact | Effort | Owner |
|---|---|---|---|---|
| 7 | **UAT verification method column** — Add column to UAT template. Systems-programmer validates coverage before Studio Head review. | MEDIUM | LOW | producer + systems-programmer |
| 8 | **Playtest script authoring** — Write YAML playtest scripts for core loops (mine, craft, navigate, equip). Initially as structured documentation for Studio Head. | MEDIUM | MEDIUM | qa-engineer |
| 9 | **Scene property mandate in tickets** — Every ticket modifying `.tscn` must include expected property values in ACs. | MEDIUM | LOW — process enforcement | producer |

### Phase 4: Automation (Post-T3)

| # | Item | Impact | Effort | Owner |
|---|---|---|---|---|
| 10 | **Autonomous playthrough execution** — QA agent runs playtest scripts via live Godot MCP. Auto-files BUG tickets. | VERY HIGH | HIGH — requires T3 | qa-engineer |
| 11 | **Visual regression baselines** — Reference screenshots at milestone close. Pixel-diff comparison. | HIGH | HIGH | qa-engineer |
| 12 | **CI playthrough gate** — Reduced playthrough suite on every commit to main. | VERY HIGH | HIGH — CI infrastructure | tools/devops |

---

## Verification

After implementing Phase 1–2 items:

1. Run the full test suite headless — `godot --headless --path game res://addons/hammer_forge_tests/test_runner.tscn` — verify scene property tests are discovered and pass
2. Deliberately break a HUD anchor in `game_hud.tscn` — re-run suite — verify test FAILS (validates the guard catches regressions)
3. Deliberately change `ship_exterior.tscn` collision to `BoxShape3D` — re-run suite — verify test FAILS
4. Write one integration test (`test_navigation_flow_integration.gd`) — verify it runs alongside unit tests with no runner changes
5. Review the feature spec template with the Producer to confirm it's usable for M9 ticket creation
