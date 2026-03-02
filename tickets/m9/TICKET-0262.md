---
id: TICKET-0262
title: "BUG: Global.log() naming conflict causes Godot 4.5 headless GDScript parse error — entire test suite unrunnable headlessly"
type: BUG
status: OPEN
priority: P1
owner: systems-programmer
created_by: qa-engineer
created_at: 2026-03-01
updated_at: 2026-03-01
milestone: "M9"
phase: "Root Game"
depends_on: []
blocks: [TICKET-0235]
tags: [bug, global, log, godot-4.5, headless, tests, parse-error]
---

## Summary

`Global.gd` defines a method named `log(message: String)` which conflicts with the Godot 4.5 built-in global function `log(float) -> float` (natural logarithm). When Godot 4.5 runs in headless mode, the GDScript compiler raises a parse error at `Global.gd:11` because `log("string")` is interpreted as a call to the built-in `log(float)` rather than the class method. This causes `Global.gd` to fail compilation, which cascades to every script that depends on Global (all autoloads and ~50+ game scripts), making the entire headless test suite unrunnable.

**Root file:** `game/autoloads/Global.gd`

**Severity:** P1 — Blocks all headless test execution; the test suite cannot be verified via `godot --headless`.

## Reproduction Steps

1. Locate `Godot_v4.5.1-stable_win64_console.exe`
2. Run:
   ```
   Godot_v4.5.1-stable_win64_console.exe --headless --path game res://addons/hammer_forge_tests/test_runner.tscn
   ```
3. Observe immediately:
   ```
   SCRIPT ERROR: Parse Error: Invalid argument for "log()" function: argument 1 should be "float" but is "String".
      at: GDScript::reload (res://autoloads/Global.gd:11)
   ERROR: Failed to load script "res://autoloads/Global.gd" with error "Parse error".
   ERROR: Failed to instantiate an autoload, script 'res://autoloads/Global.gd' does not inherit from 'Node'.
   ```
4. All downstream scripts fail to compile: AgentLogger, ShipState, ModuleManager, Recycler, HeadLamp, TechTree, Fabricator, AutomationHub, FuelSystem, NavigationSystem, ResourceRespawnSystem, and all test files.

## Expected Behavior

The test suite runs headlessly with zero compilation errors and produces a JSON report in `user://test_reports/`.

## Actual Behavior

`Global.gd` fails to parse because `log()` is interpreted as the Godot built-in `log(float)` function, causing a parse error on every headless invocation. The entire test suite cannot execute.

## Root Cause

`Global.gd` line 15 defines `func log(message: String)` — a custom logging helper. Line 11 (inside `_ready()`) calls `log(...)` with a String argument. In Godot 4.5 headless compilation, the parser resolves `log()` as the built-in global function `@GDScript.log(value: float) -> float` before considering the class method, causing a type-mismatch parse error. This did not surface in editor-based runs because the editor uses cached GDScript bytecode (`.godot/` cache) compiled before this version restriction was enforced.

## Fix Recommendation

Rename `Global.log()` to `Global.debug_log()` (or similar) and update all call sites across the codebase. This is a mechanical rename with no behavioral change.

**Scope of call sites:** All occurrences of `Global.log(` in game scripts — approximately 100+ call sites across gameplay, systems, and test files.

## Evidence

Headless test run output (partial):
```
SCRIPT ERROR: Parse Error: Invalid argument for "log()" function: argument 1 should be "float" but is "String".
   at: GDScript::reload (res://autoloads/Global.gd:11)
ERROR: Failed to load script "res://autoloads/Global.gd" with error "Parse error".
ERROR: Failed to instantiate an autoload, script 'res://autoloads/Global.gd' does not inherit from 'Node'.
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://autoloads/AgentLogger.gd:0)
ERROR: Failed to load script "res://autoloads/AgentLogger.gd" with error "Compilation failed".
[... 50+ more cascade failures ...]
ERROR: Failed to load script "res://tests/test_game_startup_unit.gd" with error "Compilation failed".
```

Exit code: 0 (test runner exited cleanly but ran 0 tests)

## Activity Log

- 2026-03-01 [qa-engineer] Filed — discovered while attempting headless test execution for TICKET-0235 Root Game QA gate. Headless command: `Godot_v4.5.1-stable_win64_console.exe --headless --path game res://addons/hammer_forge_tests/test_runner.tscn`. Full output reviewed — parse error on Global.gd:11 blocks all compilation. BUG filed; TICKET-0235 gate documented with this blocker noted.
