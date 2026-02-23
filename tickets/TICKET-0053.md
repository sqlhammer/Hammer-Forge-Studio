---
id: TICKET-0053
title: "BUG: recycler.gd is_processing() overrides Node.is_processing()"
type: BUG
status: OPEN
priority: P1
owner: systems-programmer
created_by: qa-engineer
created_at: 2026-02-23
updated_at: 2026-02-23
milestone: "M4"
depends_on: []
blocks: [TICKET-0049]
tags: [bug, parse-error, M4, blocking]
---

## Summary
`recycler.gd:117` defines a method `is_processing() -> bool` that overrides the built-in `Node.is_processing()` method. Godot 4.5.1 treats this as an error ("Warning treated as error"), causing the script to fail to parse. Combined with TICKET-0052, this completely blocks `Recycler` autoload initialization.

## Error Details
```
res://scripts/systems/recycler.gd:117 - Parse Error: The method "is_processing()" overrides a method from native class "Node". This won't be called by the engine and may not work as expected. (Warning treated as error.)
```

## Acceptance Criteria
- [ ] `recycler.gd` parses without errors
- [ ] Recycler processing state is queryable without overriding Node.is_processing()
- [ ] All existing Recycler functionality preserved

## Implementation Notes
- Rename `is_processing()` to avoid the collision, e.g. `is_job_processing()`, `is_job_active()`, or `has_active_job()`
- Update all callers of `Recycler.is_processing()` to use the new name
- This is independent from TICKET-0052 but both must be fixed before M4 scenes can run

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-23 [qa-engineer] Created from TICKET-0051 regression testing — parse error blocks Recycler autoload
