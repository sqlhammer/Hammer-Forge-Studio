---
id: TICKET-0289
title: "M11 GDScript Standards Audit — full codebase compliance report"
type: TASK
status: DONE
priority: P1
owner: systems-programmer
created_by: producer
created_at: 2026-03-03
updated_at: 2026-03-03
milestone: "M11"
phase: "Audit"
depends_on: []
blocks: [TICKET-0290]
tags: [standards, audit, compliance, scene-first-rule]
---

## Summary

Perform a full audit of all GDScript files in `game/` against the current coding standards
(`docs/engineering/coding-standards.md`). Produce a structured compliance report that the
Producer will use to create targeted remediation tickets.

**Scene-First Rule violations are the highest-priority finding** and must be enumerated in
their own dedicated section. All other standards violations follow in a separate section.

The report is the sole deliverable. Do not fix anything during this ticket — the fix work
is scoped to Phase 2.

---

## Acceptance Criteria

### Deliverable

- [ ] Report file created at `docs/studio/reports/YYYY-MM-DD-m11-gdscript-audit.md`
      (replace `YYYY-MM-DD` with the date of completion)

### Report structure

The report must contain all of the following sections in order:

#### 1. Executive Summary

A brief paragraph summarizing:
- Total `.gd` files scanned
- Total violations found, broken down by category
- Number of Scene-First Rule violations specifically
- Overall compliance health (e.g., "32 of 47 files are fully compliant")

#### 2. Scene-First Rule Violations *(dedicated section — highest priority)*

A table with one row per violation:

| File | Line(s) | Violation Type | Description | Severity |
|------|---------|----------------|-------------|----------|

Violation types to detect (from `coding-standards.md` Scene-First Rule section):
- `NEW_FOR_PERSISTENT` — `.new()` + `add_child()` used for a node that is always present
- `CANVAS_LAYER_NEW` — `CanvasLayer.new()` (or similar) used for a persistent overlay
- `LAYOUT_IN_READY` — anchors, size, position, visibility, or modulate of a persistent node
  set in `_ready()` rather than in the editor
- `READY_SCENE_CONSTRUCTION` — `_ready()` builds the scene tree (multiple `.new()` + `add_child()`
  calls constructing the hierarchy)

Severity scale:
- `HIGH` — node is persistent/semi-persistent; layout or visibility will be wrong at runtime
- `MEDIUM` — node is created at runtime but could easily be persistent; minor layout risk
- `LOW` — borderline case; acceptable only with justification

#### 3. All Other Standards Violations

A table with one row per violation, grouped by category:

| Category | File | Line(s) | Violation | Description | Severity |
|----------|------|---------|-----------|-------------|----------|

Categories to check (matching sections in `docs/engineering/coding-standards.md`):

- **Naming** — file names, class names (`class_name` vs `extends "res://..."`), node names
  (PascalCase, descriptive), signal names (past-tense snake_case), abbreviations
- **Variable Typing** — untyped variables or function parameters, missing return types,
  missing `-> void` on void functions, missing `_` prefix on private members
- **Script Structure** — section order violation (signals → constants → exports → private vars
  → onready → built-in virtuals → public methods → private methods)
- **Documentation** — missing `##` docstring on script (above `class_name`), missing `##`
  docstring on public methods
- **Debugging** — bare `print()` calls instead of `Global.log()` / `push_warning()` /
  `push_error()`
- **Communication** — direct `Input.is_action_pressed()` calls (must go through `InputManager`),
  `get_node()` with magic string paths beyond direct children (use `@onready` instead),
  `extends "res://..."` string-path inheritance
- **Method & Expression** — multi-component expressions passed directly as method arguments
  (must be broken into named local variables first)
- **Editor Compliance** — any scripts known to produce Godot editor errors or warnings
  (note: list these if discovered during the scan; a full editor run is not required for
  this ticket)

#### 4. Compliant Files

A simple list of all `.gd` files that have zero violations, for completeness.

#### 5. Remediation Priority Recommendation

A prioritized list of components the Producer should address first, based on severity and
blast radius. Suggest groupings if multiple violations share a file or logical system.

---

## Scope

- All `.gd` files under `game/` — recursively
- Exclude `game/addons/` (third-party code)
- Exclude `game/tests/` (test files follow a relaxed standard — note any egregious issues
  but do not flag test files as violations)

---

## Implementation Notes

Perform the audit by reading files directly. Use `grep`-style searches and `Read` tool
calls to locate violations. Do not run Godot for this ticket — static analysis only.

Suggested search patterns:
- `.new()` followed by `add_child(` on nearby lines
- `CanvasLayer.new()`
- `= .new()` in `_ready()` context
- Bare `print(` (not `Global.log(`)
- `Input.is_action_pressed(`
- `extends "res://`
- Variables declared without type annotation: `var \w+ =` (no colon)
- Functions with untyped parameters: `func \w+\([^)]*\w\s*[,)]` (parameter with no `:`)
- Missing `-> void` on functions that return nothing

---

## Handoff Notes

(Leave blank until handoff occurs.)

---

## Activity Log

- 2026-03-03 [producer] Created ticket — full GDScript standards audit, Scene-First Rule priority
- 2026-03-03 [systems-programmer] Starting work — static analysis audit of all game/ .gd files
- 2026-03-03 [systems-programmer] DONE — Report at docs/studio/reports/2026-03-03-m11-gdscript-audit.md. 82 files scanned, 65 violations found (44 Scene-First, 21 other), 51 fully compliant. Commit 269b33c.
