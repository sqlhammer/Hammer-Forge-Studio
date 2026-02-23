---
id: TICKET-0038
title: "FIX: test_world.gd missing class_name"
type: BUGFIX
status: DONE
priority: P2
owner: gameplay-programmer
created_by: systems-programmer
created_at: 2026-02-23
updated_at: 2026-02-23
milestone: "M3"
depends_on: []
blocks: []
tags: [coding-standards, test-world]
---

## Summary
`test_world.gd` is missing a `class_name` declaration. The coding standard requires `class_name` on all scripts that are not autoloads. `test_world.gd` is not an autoload and therefore requires a `class_name`.

## Acceptance Criteria
- [ ] `class_name TestWorld` (or appropriate name) added to `test_world.gd`
- [ ] `class_name` placed in the correct position per script structure order (above `extends`, below the docstring comment)
- [ ] All code follows `docs/engineering/coding-standards.md`
- [ ] No Godot editor errors or warnings

## Implementation Notes
- Found during TICKET-0030 code review (P2)
- Note: the coding standard was updated on 2026-02-23 to exempt autoload scripts from the `class_name` requirement — `test_world.gd` is not an autoload and is not exempt

## Activity Log
- 2026-02-23 [systems-programmer] Created from TICKET-0030 P2 findings
- 2026-02-23 [gameplay-programmer] Added class_name TestWorld to test_world.gd
