---
id: TICKET-0306
title: "BUG — tech_tree_defs.gd get_prerequisites() returns empty due to Array[String] type mismatch"
type: BUG
status: DONE
priority: P1
owner: systems-programmer
created_by: qa-engineer
created_at: 2026-03-03
updated_at: 2026-03-03
milestone: "M11"
phase: "QA"
depends_on: []
blocks: [TICKET-0304]
tags: [tech-tree, regression, m11, array-types]
---

## Summary

`tech_tree_defs.gd:get_prerequisites()` now returns an empty array for all nodes due to a
runtime type mismatch introduced by TICKET-0302 (Add element types to Array declarations).

---

## Severity

**P1 — Core gameplay mechanic broken**: Tech tree prerequisite enforcement is non-functional.
Any node can be unlocked regardless of whether its prerequisites are met. This affects the
full crafting and tech progression loop.

---

## Regression Source

**TICKET-0302** modified `game/scripts/data/tech_tree_defs.gd` to add `Array[String]` type
annotations. The `get_prerequisites()` function now attempts to assign a plain `Array` value
from a `Dictionary.get()` call into a typed `Array[String]` variable, which fails at runtime:

```
SCRIPT ERROR: Trying to assign an array of type "Array" to a variable of type "Array[String]".
   at: get_prerequisites (res://scripts/data/tech_tree_defs.gd:53)
```

When this error fires, `raw` remains empty, so `result` is returned empty for every node.

---

## Reproduction Steps

1. Open any scene that uses TechTree (e.g., DebugLauncher or GameWorld)
2. From the tech tree, attempt to unlock `automation_hub` without first unlocking
   `fabricator_module`
3. Observe: unlock succeeds (prerequisites not enforced)

Alternatively, run the headless test suite — `test_tech_tree_unit` reports:
- `automation_hub_requires_fabricator` FAIL: Expected '1' but got '0'
- `unlock_fails_missing_prerequisite` FAIL: Expected false but got true

---

## Expected Behavior

`TechTreeDefs.get_prerequisites("automation_hub")` returns `["fabricator_module"]`.
Unlocking `automation_hub` without `fabricator_module` DONE should fail.

## Actual Behavior

`get_prerequisites()` fires a runtime SCRIPT ERROR and returns `[]` for all nodes.
All tech tree nodes have zero prerequisites; any node can be unlocked without conditions.

---

## Evidence

Test output from M11 Phase Gate QA run (2026-03-03):
```
SCRIPT ERROR: Trying to assign an array of type "Array" to a variable of type "Array[String]".
   at: get_prerequisites (res://scripts/data/tech_tree_defs.gd:53)
[221647]   FAIL: automation_hub_requires_fabricator -- Automation Hub should have 1 prerequisite: Expected '1' but got '0'
[221649]   FAIL: unlock_fails_missing_prerequisite -- Automation Hub unlock should fail without fabricator_module unlocked: Expected false but got true
```

---

## Root Cause

In `tech_tree_defs.gd:53`:
```gdscript
var raw: Array[String] = entry.get("prerequisites", [] as Array[String])
```

`TECH_TREE_CATALOG` stores `prerequisites` as an untyped `Array` (GDScript dictionary literal).
`entry.get()` returns an `Array` (untyped), which cannot be assigned to `Array[String]`.
The fix is to use `Array[String](entry.get("prerequisites", []))` or iterate and cast.

---

## Suggested Fix

```gdscript
static func get_prerequisites(node_id: String) -> Array[String]:
    var entry: Dictionary = TECH_TREE_CATALOG.get(node_id, {})
    var result: Array[String] = []
    var raw: Array = entry.get("prerequisites", [])
    for item in raw:
        result.append(item as String)
    return result
```

---

## Files Involved

- `game/scripts/data/tech_tree_defs.gd` — line 53 (`get_prerequisites`)

---

## Activity Log

- 2026-03-03 [qa-engineer] Filed — P1 regression from TICKET-0302; tech tree prerequisites fully broken. Blocks TICKET-0304 Phase Gate QA sign-off.
- 2026-03-03 [systems-programmer] IN_PROGRESS — Starting work. Applying fix: change `var raw: Array[String]` to untyped `var raw: Array` and iterate+cast into typed result.
- 2026-03-03 [systems-programmer] DONE — Fix committed and merged. Commit: 8d3d2eb, merge commit: bee447f. PR: https://github.com/sqlhammer/Hammer-Forge-Studio/pull/352
