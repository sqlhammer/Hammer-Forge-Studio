---
id: TICKET-0121
title: "Bugfix — compass_bar.gd crashes with 'Trying to cast a freed object' on line 220"
type: BUGFIX
status: DONE
priority: P2
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-25
updated_at: 2026-02-25
milestone: "M5"
phase: "QA"
depends_on: []
blocks: []
tags: [bugfix, compass-bar, hud, freed-object, crash]
---

## Summary

`compass_bar.gd` crashes with `Trying to cast a freed object` at line 220 inside `_clean_expired_markers()`. The error occurs when a `Deposit` node that is still referenced in `_ping_markers` has been freed from the scene tree — the `as Deposit` cast runs before the `is_instance_valid()` guard on line 221.

```
E   compass_bar.gd:220 @ _clean_expired_markers(): Trying to cast a freed object.
```

## Root Cause

```gdscript
# compass_bar.gd:217
func _clean_expired_markers() -> void:
    for i: int in range(_ping_markers.size() - 1, -1, -1):
        var deposit: Deposit = _ping_markers[i].get("deposit") as Deposit  # line 220 — CRASHES here
        if not deposit or not is_instance_valid(deposit) or deposit.is_depleted():
            _ping_markers.remove_at(i)
```

When a `Deposit` node is freed (e.g., removed from the scene), Godot raises an error on the typed `as Deposit` cast before execution reaches the `is_instance_valid()` check.

The same pattern appears in `_draw_ping_markers()` (the two `as Deposit` casts inside that loop) and is equally at risk.

## Fix

Retrieve the raw value first, validate it with `is_instance_valid()`, then cast. Apply to both `_clean_expired_markers()` and `_draw_ping_markers()`:

### `_clean_expired_markers()`

```gdscript
func _clean_expired_markers() -> void:
    for i: int in range(_ping_markers.size() - 1, -1, -1):
        var raw: Variant = _ping_markers[i].get("deposit")
        if not is_instance_valid(raw):
            _ping_markers.remove_at(i)
            continue
        var deposit: Deposit = raw as Deposit
        if not deposit or deposit.is_depleted():
            _ping_markers.remove_at(i)
```

### `_draw_ping_markers()`

Apply the same pattern to the two `as Deposit` casts inside that method's loops.

## Acceptance Criteria

- [ ] No `Trying to cast a freed object` error when a tracked deposit's node is freed while still in `_ping_markers`
- [ ] Freed-deposit markers are silently removed from the list without a log error
- [ ] All existing compass bar behaviour is unchanged (markers appear, fade, distance readout works)
- [ ] All code follows `docs/engineering/coding-standards.md`

## Activity Log

- 2026-02-25 [producer] Created ticket — crash reproducible when deposit node is freed while compass marker is active
- 2026-02-25 [gameplay-programmer] DONE — added is_instance_valid() guard before `as Deposit` cast in _clean_expired_markers() and both loops in _draw_ping_markers(). Commit c535d25, PR #57.
