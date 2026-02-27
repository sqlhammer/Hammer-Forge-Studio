# M8 Test Coverage Guidelines

**Owner:** qa-engineer
**Status:** Active
**Last Updated:** 2026-02-27
**Milestone:** M8 — Ship Navigation

> This document provides system-specific test patterns for M8. Follow these guidelines when writing tests for each new system. For the general TDD process (Red/Green/Refactor cycle, commit conventions, coverage targets), see `docs/studio/tdd-process-m8.md`.

---

## Test Infrastructure

All M8 tests use the **Hammer Forge Tests** framework (`game/addons/hammer_forge_tests/`).

- Test files live in `game/tests/` — one file per system
- All test suites extend `TestSuite`
- Run via `res://addons/hammer_forge_tests/test_runner.tscn`
- M7 baseline: 480 tests. Every M8 phase gate must show a higher count.

---

## Navigation System

**Test file:** `game/tests/test_navigation_system.gd`
**Coverage target:** 85%

### Patterns

#### Waypoint Detection
```gdscript
# Test that a valid biome destination is accepted
func test_valid_destination_accepted() -> void:
    var nav := NavigationSystem.new()
    var result := nav.set_destination("shattered_flats")
    assert_true(result, "Valid biome destination should be accepted")

# Test that an unknown biome is rejected
func test_unknown_destination_rejected() -> void:
    var nav := NavigationSystem.new()
    var result := nav.set_destination("nonexistent_biome")
    assert_false(result, "Unknown biome should be rejected")
```

#### Travel Validation
```gdscript
# Test that travel to current biome is a no-op
func test_travel_to_current_biome_is_noop() -> void:
    var nav := NavigationSystem.new()
    nav.set_current_biome("rock_warrens")
    var changed := nav.travel_to("rock_warrens")
    assert_false(changed, "Travel to current biome should be a no-op")

# Test that travel requires sufficient fuel
func test_travel_blocked_when_no_fuel() -> void:
    var nav := NavigationSystem.new()
    nav.set_fuel(0)
    var result := nav.travel_to("shattered_flats")
    assert_false(result, "Travel should fail with zero fuel")
```

#### Pathfinding
```gdscript
# Test that route calculation returns a non-empty path
func test_route_calculated_successfully() -> void:
    var nav := NavigationSystem.new()
    var route := nav.calculate_route("rock_warrens", "debris_field")
    assert_gt(route.size(), 0, "Route should contain at least one step")

# Test null input handling
func test_route_with_null_origin_returns_empty() -> void:
    var nav := NavigationSystem.new()
    var route := nav.calculate_route(null, "debris_field")
    assert_eq(route.size(), 0, "Null origin should return empty route")
```

### Required Test Categories for Navigation
- Destination registration (all 3 biomes: Shattered Flats, Rock Warrens, Debris Field)
- Valid travel initiation
- Invalid travel attempts (no fuel, same biome, null destination)
- Travel state signals (`travel_started`, `travel_completed`, `travel_failed`)
- Route calculation correctness and edge cases
- State after failed travel (must return to idle, not stuck in traveling)

---

## Fuel System

**Test file:** `game/tests/test_fuel_system.gd`
**Coverage target:** 80%

### Patterns

#### Fuel Cell Crafting
```gdscript
# Test successful fuel cell creation from valid resources
func test_fuel_cell_crafted_from_metal_and_cryonite() -> void:
    var fuel := FuelSystem.new()
    fuel.add_resource("metal", 2)
    fuel.add_resource("cryonite", 1)
    var success := fuel.craft_fuel_cell()
    assert_true(success, "Fuel cell should craft with 2 Metal + 1 Cryonite")

# Test crafting fails without sufficient cryonite
func test_fuel_cell_fails_without_cryonite() -> void:
    var fuel := FuelSystem.new()
    fuel.add_resource("metal", 2)
    var success := fuel.craft_fuel_cell()
    assert_false(success, "Fuel cell crafting should fail without Cryonite")
```

#### Consumption Calculation
```gdscript
# Test that fuel decreases after travel
func test_fuel_consumed_after_travel() -> void:
    var fuel := FuelSystem.new()
    fuel.set_fuel_level(100.0)
    fuel.consume_for_travel("shattered_flats", "rock_warrens")
    assert_lt(fuel.get_fuel_level(), 100.0, "Fuel should decrease after travel")

# Test that fuel never goes below zero
func test_fuel_cannot_go_negative() -> void:
    var fuel := FuelSystem.new()
    fuel.set_fuel_level(1.0)
    fuel.consume_for_travel("shattered_flats", "debris_field")
    assert_gte(fuel.get_fuel_level(), 0.0, "Fuel level must not go negative")
```

#### Edge Cases
```gdscript
# Test full tank behavior
func test_fuel_cap_at_maximum() -> void:
    var fuel := FuelSystem.new()
    fuel.set_fuel_level(FuelSystem.MAX_FUEL)
    fuel.add_fuel(10.0)
    assert_eq(fuel.get_fuel_level(), FuelSystem.MAX_FUEL, "Fuel should cap at max")

# Test empty fuel state
func test_empty_fuel_state_signal() -> void:
    var fuel := FuelSystem.new()
    var signal_fired := false
    fuel.fuel_empty.connect(func(): signal_fired = true)
    fuel.set_fuel_level(0.0)
    assert_true(signal_fired, "fuel_empty signal should fire when fuel reaches zero")
```

### Required Test Categories for Fuel
- Fuel cell crafting (valid inputs, missing Metal, missing Cryonite, both missing)
- Fuel level arithmetic (add, consume, cap, floor)
- Travel cost calculation correctness per route
- Fuel empty signal firing
- Fuel full signal firing
- Crafting with zero resources (null-safety)

---

## Biome Transition Logic and State Management

**Test file:** `game/tests/test_biome_manager.gd`
**Coverage target:** 75%

### Patterns

#### Biome Activation
```gdscript
# Test that biome change updates current biome
func test_biome_change_updates_active_biome() -> void:
    var bm := BiomeManager.new()
    bm.activate_biome("debris_field")
    assert_eq(bm.get_active_biome(), "debris_field", "Active biome should update")

# Test that activating same biome is a no-op
func test_activating_same_biome_fires_no_signal() -> void:
    var bm := BiomeManager.new()
    bm.activate_biome("shattered_flats")
    var signal_count := 0
    bm.biome_changed.connect(func(_b): signal_count += 1)
    bm.activate_biome("shattered_flats")
    assert_eq(signal_count, 0, "No signal for same-biome activation")
```

#### Resource Respawn on Biome Change
```gdscript
# Test that resource nodes respawn on biome change
func test_resources_respawn_on_biome_change() -> void:
    var bm := BiomeManager.new()
    bm.activate_biome("rock_warrens")
    # mine all resources
    bm.clear_all_resources_for_test()
    bm.activate_biome("shattered_flats")
    bm.activate_biome("rock_warrens")
    assert_gt(bm.get_resource_node_count(), 0, "Resources should respawn on re-entry")
```

#### State Transitions
```gdscript
# Test transition from idle to traveling
func test_state_transitions_from_idle_to_traveling() -> void:
    var bm := BiomeManager.new()
    assert_eq(bm.get_state(), BiomeManager.State.IDLE)
    bm.begin_transition("debris_field")
    assert_eq(bm.get_state(), BiomeManager.State.TRAVELING)

# Test that invalid transition from TRAVELING is rejected
func test_cannot_begin_transition_while_traveling() -> void:
    var bm := BiomeManager.new()
    bm.begin_transition("rock_warrens")
    var result := bm.begin_transition("debris_field")
    assert_false(result, "Cannot start a new transition while already traveling")
```

### Required Test Categories for Biome
- Biome activation and current biome tracking
- Biome change signal accuracy
- Resource respawn on biome re-entry
- State machine: IDLE → TRAVELING → ARRIVED (all transitions)
- Invalid state transitions (mid-travel interrupts)
- Seed-based reproducibility (same seed = same biome layout)

---

## Common Pitfalls and How to Avoid Them

### Pitfall 1: Testing Implementation, Not Behavior
**Wrong:** `assert_eq(nav._internal_route_array.size(), 3)`
**Right:** `assert_eq(nav.calculate_route("a", "b").size(), 3)`

Test public API. Never access `_private` members in tests.

---

### Pitfall 2: Tests That Always Pass
A test that never fails — even with a stub implementation — is not a red-phase test. Before implementing, your test must fail. If it doesn't, the test is testing nothing.

```gdscript
# Wrong — this will pass even with an empty implementation
func test_fuel_not_null() -> void:
    var fuel := FuelSystem.new()
    assert_not_null(fuel)

# Right — this fails until FuelSystem.get_fuel_level() is implemented
func test_initial_fuel_is_positive() -> void:
    var fuel := FuelSystem.new()
    assert_gt(fuel.get_fuel_level(), 0.0, "Initial fuel should be greater than zero")
```

---

### Pitfall 3: Shared Mutable State Between Tests
Each test must create its own instance. Never share a single system instance across multiple test methods — state from one test will contaminate the next.

```gdscript
# Wrong
var _shared_nav: NavigationSystem

func before_all() -> void:
    _shared_nav = NavigationSystem.new()

func test_a() -> void:
    _shared_nav.set_destination("rock_warrens")
    # test_b now has stale state

# Right
func test_a() -> void:
    var nav := NavigationSystem.new()
    nav.set_destination("rock_warrens")
    # fresh instance, no contamination
```

---

### Pitfall 4: Skipping Failure Cases
It is tempting to test only the happy path. M8 requires failure case tests for every system (see `docs/studio/tdd-process-m8.md`). If the happy-path test passes and no failure-case test is written, the ticket is not complete.

---

### Pitfall 5: Forgetting Signal Tests
Signals are the primary M8 inter-system communication channel. Every signal defined on an M8 class must have at least one test verifying it fires under the correct condition.

```gdscript
func test_travel_completed_signal_fires_on_arrival() -> void:
    var nav := NavigationSystem.new()
    var fired := false
    nav.travel_completed.connect(func(_biome): fired = true)
    nav.travel_to("shattered_flats")
    nav._simulate_arrival()  # or however the system signals completion
    assert_true(fired, "travel_completed must fire on arrival")
```

---

## Document History

| Date | Author | Change |
|------|--------|--------|
| 2026-02-27 | producer | Initial creation for M8 kickoff |
