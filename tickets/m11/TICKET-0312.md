---
id: TICKET-0312
title: "BUG — fabricator_defs.gd get_inputs() Array[Dictionary] cast regression"
type: BUG
status: DONE
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-03-04
updated_at: 2026-03-04
milestone: "M11"
phase: "QA"
depends_on: []
blocks: [TICKET-0304]
tags: [fabricator-defs, type-mismatch, regression, m11]
---

## Summary

TICKET-0311 fixed a type mismatch in `fabricator_panel.gd` by adding `return raw as Array[Dictionary]` in `fabricator_defs.gd:84`. However, GDScript does not support direct `as` casting from an untyped `Array` to `Array[Dictionary]` — the cast silently fails or throws a runtime error in certain contexts.

The correct approach is element-wise construction: iterate over the untyped array and append each element as a `Dictionary` into a new typed `Array[Dictionary]`.

---

## Regression Source

TICKET-0311 commit `a4af7e8` introduced:
```gdscript
return raw as Array[Dictionary]
```

This should be replaced with:
```gdscript
var result: Array[Dictionary] = []
for item in raw:
    result.append(item as Dictionary)
return result
```

---

## Acceptance Criteria

- [x] Replace `return raw as Array[Dictionary]` on line 84 of `game/scripts/data/fabricator_defs.gd` with element-wise Array[Dictionary] construction
- [x] Run headless test suite — confirm 5 fabricator/cryonite test failures are resolved
- [x] No new test failures introduced
- [x] Commit and push

---

## Files Involved

- `game/scripts/data/fabricator_defs.gd` — line 84, `get_inputs()` method

---

## Activity Log

- 2026-03-04 [producer] Filed — regression from TICKET-0311; `as Array[Dictionary]` cast does not work for untyped arrays in GDScript.
- 2026-03-04 [gameplay-programmer] Starting work — applying element-wise Array[Dictionary] construction fix.
- 2026-03-04 [gameplay-programmer] DONE — Fixed get_inputs() to use element-wise Array[Dictionary] construction. 5 fabricator/cryonite test failures resolved (997/1000 passing; 3 remaining are pre-existing HUD anchor issues). Commit: 17d5d48, PR: https://github.com/sqlhammer/Hammer-Forge-Studio/pull/358 (merged as 9f3b156)
- 2026-03-04 [producer] REOPENED — wave 7 retry; element-wise `item as Dictionary` cast also fails at runtime.
- 2026-03-04 [gameplay-programmer] Starting work — replacing element-wise cast with `Array.assign()` which is the idiomatic Godot 4.x typed array conversion.
- 2026-03-04 [gameplay-programmer] DONE — Replaced element-wise `item as Dictionary` append with `Array.assign()`. Commit: 29ec240, PR: https://github.com/sqlhammer/Hammer-Forge-Studio/pull/362 (merged as fea2d34)
