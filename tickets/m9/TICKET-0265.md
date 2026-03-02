---
id: TICKET-0265
title: "BUG: Gamepad stick menu navigation fires continuously while held — should require return-to-center between moves"
type: BUG
status: TODO
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-03-02
updated_at: 2026-03-02
milestone: "M9"
phase: "Gamepad Bugs"
depends_on: []
blocks: []
tags: [bug, gamepad, input, inventory, navigation, uat-rejection]
---

## Summary

When navigating the inventory (or any menu) with the left stick, the selection moves at an uncontrollably fast rate as long as the stick is held in a direction. The intent is discrete, step-by-step navigation: moving the stick fires **one** navigation event, the selection advances one slot, and no further navigation fires until the stick returns to neutral (center) and is deflected again.

Discovered during Studio Head UAT.

## Reproduction Steps

1. Launch the game with a gamepad connected.
2. Open inventory (**Select / Back** button).
3. Push the left stick in any direction and hold it there.
4. Observe: the cursor races through inventory slots at high speed, making precise selection nearly impossible.

## Expected Behavior

1. Player deflects stick past the dead zone threshold in a direction.
2. Selection moves **one** slot in that direction.
3. No further navigation fires — even if stick remains held.
4. Player returns stick to center (below dead zone threshold).
5. Player can now deflect stick again to move one more slot.

This is the standard "edge-triggered" stick navigation pattern used by most console UIs.

## Actual Behavior

Navigation fires continuously at the polling rate while the stick is held, causing uncontrollable fast-scrolling through the grid.

## Acceptance Criteria

- [ ] Deflecting the stick in any direction advances selection by exactly **one slot**, then stops.
- [ ] Holding the stick in that direction does **not** fire additional navigation events.
- [ ] Returning the stick to center resets the latch; the next deflection fires one move again.
- [ ] The behavior applies to the inventory grid and any other menu that uses stick navigation.
- [ ] Mouse / keyboard navigation in menus is unaffected.
- [ ] Existing unit tests pass.

## Implementation Notes

Implement an edge-triggered latch in the menu navigation input handler:

```gdscript
# State tracked per axis direction:
var _stick_nav_latched: bool = false

func _process_stick_navigation(stick: Vector2) -> void:
    var DEAD_ZONE: float = 0.5
    if stick.length() < DEAD_ZONE:
        _stick_nav_latched = false   # stick returned to center — reset
        return
    if _stick_nav_latched:
        return                       # still held from last move — ignore
    # First frame past dead zone: fire exactly one move
    _stick_nav_latched = true
    var dir := _dominant_direction(stick)
    _navigate(dir)
```

The latch resets only when the stick magnitude drops below the dead zone. Separate latches per axis (X and Y) may be preferable so diagonal inputs can trigger both a horizontal and vertical move independently without interfering.

## Activity Log

- 2026-03-02 [producer] Filed — UAT rejection. Studio Head reported inventory navigation races when stick is held; discrete step behavior required.
