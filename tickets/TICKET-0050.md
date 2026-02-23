---
id: TICKET-0050
title: "BUG: Scan results hidden on mine-start; overlap with extraction notification"
type: BUGFIX
status: OPEN
priority: P2
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-23
updated_at: 2026-02-23
milestone: "M3"
depends_on: []
blocks: []
tags: [bug, hud, scanner, mining, ux]
---

## Summary
Three related HUD issues degrade the scan/mine loop. First, `game_hud.gd:_on_mining_started` calls `_scanner_readout.hide_readout()`, which actively dismisses the scan results the moment mining begins — the player loses purity/density/energy data exactly when they need it. Second, the `_process` loop in `game_hud.gd` that auto-shows the readout for already-analyzed deposits is suppressed while mining is active (because `hide_readout()` was just called). Third, the `ScannerReadout` panel and the `PickupNotificationManager` are both right-anchored at center-right with overlapping vertical ranges, causing visual collision when an extraction completes while the readout is visible.

## Acceptance Criteria
- [ ] Scan results remain visible throughout the full mining hold — from start through completion/cancellation
- [ ] Pointing at an already-analyzed deposit (while not mining) shows the scan readout immediately
- [ ] Pointing at an already-analyzed deposit while mining shows (or keeps showing) the scan readout
- [ ] After mining completes, the pickup notification (center-right toast) does not overlap the scan readout panel
- [ ] After mining completes and the readout is dismissed, the pickup notification occupies the full right-side zone cleanly
- [ ] No regression: readout still auto-dismisses when player walks beyond `DISMISS_DISTANCE` from the deposit
- [ ] No regression: readout still hides when the deposit is depleted

## Implementation Notes
**Root cause — hide on mining start** (`game_hud.gd:134`):
```gdscript
func _on_mining_started(_deposit: Deposit) -> void:
    _scanner_readout.hide_readout()   # ← remove this line
    _mining_progress.show_progress()
```
Remove the `hide_readout()` call. The readout should persist as long as the distance and depletion guards inside `ScannerReadout._process` allow.

**Auto-show for already-analyzed deposits** (`game_hud.gd:51–56`):
The existing `_process` loop already handles this for the idle case but is undercut by the hide on mining start. Removing that call should be sufficient; verify the loop still triggers correctly when mining is active (it is not gated on mining state today, so it should work).

**Overlap fix** (`game_hud.gd:_build_hud`):
- `ScannerReadout` is positioned at `(-READOUT_WIDTH - 80, -80)` relative to right-center anchor — roughly the upper-right quadrant.
- `PickupNotificationManager` is positioned at `(-TOAST_WIDTH - 32, 0)` relative to right-center anchor — center-right, partially overlapping.
- Shift `ScannerReadout` upward (e.g., `y = -160`) so the bottom of the readout panel clears the top of the notification stack, or shift `PickupNotificationManager` down far enough to clear the readout. Measure actual rendered heights before committing exact values; both readout and toast heights are dynamic.

**Relevant files:**
- `game/scripts/ui/game_hud.gd` — primary change site
- `game/scripts/ui/scanner_readout.gd` — review `_process` dismiss logic; ensure it doesn't inadvertently hide during mining
- `game/scripts/ui/pickup_notification.gd` — reference for toast positioning constants

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-23 [producer] Created ticket
