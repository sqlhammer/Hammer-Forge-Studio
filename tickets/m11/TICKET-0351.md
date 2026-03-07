---
id: TICKET-0351
title: "BUG — tech_tree_defs.gd line 53: var raw: Array still untyped after TICKET-0302"
type: BUG
status: DONE
priority: P3
owner: systems-programmer
created_by: play-tester
created_at: 2026-03-07
updated_at: 2026-03-07
milestone: "M11"
phase: "QA"
depends_on: []
blocks: []
tags: [bug, standards, array-types, tech-tree]
---

## Summary

TICKET-0302 was marked DONE but the acceptance criterion for `tech_tree_defs.gd` line 53 was not applied. The variable `raw` is still declared as an untyped bare `Array` rather than `Array[String]` (or a typed equivalent).

---

## Severity

P3 — Code standards non-compliance; no runtime failure observed (Godot coerces the value via `item as String` in the loop), but the declaration does not meet GDScript typing standards and was explicitly required by TICKET-0302.

---

## Reproduction Steps

1. Open `game/scripts/data/tech_tree_defs.gd`
2. Navigate to the function `get_prerequisites()` around line 50
3. Observe line 53: `var raw: Array = entry.get("prerequisites", [])`
4. The Array type has no element type annotation — it should be typed (e.g., `Array[String]` with an explicit conversion, or left as-is with a suppression comment, per the design decision in TICKET-0302)

---

## Expected Behavior

Per TICKET-0302 acceptance criteria: "add element type to `var raw: Array = entry.get(...)` (use `Array[String]` or appropriate type)". The declaration should use a typed Array consistent with the GDScript typing standards.

Note: `Dictionary.get()` returns a `Variant`, so direct assignment to `Array[String]` requires explicit conversion (e.g., `Array(entry.get("prerequisites", []), TYPE_STRING, "", null)`). The systems programmer should choose the appropriate approach.

---

## Actual Behavior

`game/scripts/data/tech_tree_defs.gd:53` reads:
```
var raw: Array = entry.get("prerequisites", [])
```
This is a bare untyped `Array` — no element type annotation is present.

---

## Evidence

Code inspection during TICKET-0331 VERIFY of TICKET-0302. Screenshot: Debug Launcher started successfully (no runtime type errors observed); the issue is a static typing standards gap, not a runtime failure.

---

## Activity Log

- 2026-03-07 [play-tester] Created BUG ticket — found during VERIFY of TICKET-0302 (TICKET-0331)
- 2026-03-07 [systems-programmer] Starting work — applying typed Array fix to tech_tree_defs.gd line 53
- 2026-03-07 [systems-programmer] DONE — commit db67357, PR https://github.com/sqlhammer/Hammer-Forge-Studio/pull/378 merged to main
