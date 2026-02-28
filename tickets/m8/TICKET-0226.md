---
id: TICKET-0226
title: "Bugfix — Mining Cryonite throws error: missing icon asset icon_item_cryonite.svg"
type: BUGFIX
status: DONE
priority: P1
owner: technical-artist
created_by: producer
created_at: 2026-02-28
updated_at: 2026-02-28
milestone: "M8"
phase: "QA"
depends_on: []
blocks: []
tags: [bugfix, cryonite, mining, icon, asset, pickup-notification, m8-qa]
---

## Summary

Mining a Cryonite deposit successfully extracts the resource but immediately throws a resource-not-found error because the pickup notification system attempts to load `res://assets/icons/item/icon_item_cryonite.svg`, which does not exist. The toast notification fails to display.

## Error

```
E 0:00:43:070   pickup_notification.gd:114 @ _create_toast(): Resource file not found: res://assets/icons/item/icon_item_cryonite.svg (expected type: unknown)
  <C++ Error>   Method/function failed. Returning: Ref<Resource>()
  <C++ Source>  core/io/resource_loader.cpp:351 @ _load()
  <Stack Trace> pickup_notification.gd:114 @ _create_toast()
                pickup_notification.gd:64 @ show_pickup()
                pickup_notification.gd:227 @ _on_item_added()
                inventory.gd:97 @ add_item()
                mining.gd:185 @ _complete_mining()
                mining.gd:147 @ _update_mining()
                mining.gd:61 @ _process()
```

## Steps to Reproduce

1. Launch any biome containing Cryonite deposits
2. Scan, analyze, and mine a Cryonite node to completion
3. Observe: error logged in console; pickup toast notification fails to appear

## Expected Behavior

Mining Cryonite produces a pickup toast notification identical to other resources, with the Cryonite item icon displayed. No errors are logged.

## Acceptance Criteria

- [x] `res://assets/icons/item/icon_item_cryonite.svg` exists and loads without error
- [x] Pickup toast notification displays correctly after mining Cryonite
- [x] Icon is visually consistent with other item icons in the M6 icon set (same style, dimensions, and color palette)
- [x] No errors logged during Cryonite pickup in any biome
- [x] Full test suite passes with no new failures

## Implementation Notes

- The M6 icon pipeline (`agents/technical-artist/`) produced SVG icons for all items known at the time — Cryonite was added in M8 (TICKET-0157) and its item icon was never created
- Create `icon_item_cryonite.svg` using the established M6 programmatic SVG method (Python + svgwrite); refer to existing item icons (e.g., `icon_item_scrap_metal.svg`) for style reference
- Place the file at `res://assets/icons/item/icon_item_cryonite.svg`
- Verify `pickup_notification.gd:114` loads it without error after placement
- Check whether `resource_defs.gd` or any icon registry maps resource types to icon paths — if so, ensure Cryonite is registered there

## Activity Log

- 2026-02-28 [producer] Created — Studio Head reported error during M8 playtest
- 2026-02-28 [technical-artist] Status → IN_PROGRESS. Starting work — creating cryonite icon SVG asset
- 2026-02-28 [technical-artist] Status → DONE. Created icon_item_cryonite.svg (faceted crystal, M6 style, #00D4AA cyan accent). Commit: 4a3b0f5, PR: https://github.com/sqlhammer/Hammer-Forge-Studio/pull/192 (merged as ab14eee)
