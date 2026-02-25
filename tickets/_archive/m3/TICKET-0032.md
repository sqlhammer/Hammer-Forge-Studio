---
id: TICKET-0032
title: "BUG: Mining extract() return type mismatch — items never added to inventory"
type: BUGFIX
status: DONE
priority: P1
owner: systems-programmer
created_by: systems-programmer
created_at: 2026-02-23
updated_at: 2026-02-23
milestone: "M3"
depends_on: [TICKET-0030]
blocks: []
tags: [bug, mining, critical]
---

## Summary
`Deposit.extract()` returns a `Dictionary` containing `{ "resource_type", "purity", "quantity" }`, but `mining.gd:_complete_mining()` assigned the return value to `var extracted: int`. GDScript coerces the Dictionary to `0`, so `if extracted > 0` always fails. Mining completion never adds items to player inventory.

## Root Cause
Type mismatch between `Deposit.extract()` return type (`Dictionary`) and the variable receiving it (`int`). The gameplay programmer likely expected `extract()` to return an `int` quantity, but the data layer API returns a full Dictionary per the TICKET-0022 acceptance criteria.

## Fix Applied
Changed `_complete_mining()` in `mining.gd` to unpack the Dictionary correctly:
```gdscript
var result: Dictionary = _mining_target.extract(EXTRACTION_AMOUNT)
if result.is_empty():
    return
var extracted: int = result.get("quantity", 0) as int
```

## Activity Log
- 2026-02-23 [systems-programmer] Found during TICKET-0030 code review. Fixed directly — single-line type mismatch. Committed with review.
- 2026-02-25 [producer] Archived
