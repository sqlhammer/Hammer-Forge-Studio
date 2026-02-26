---
id: TICKET-0105
title: "Regenerate all 29 icons — apply contrast-compliant palette from amended style guides"
type: TASK
status: DONE
priority: P1
owner: technical-artist
created_by: producer
created_at: 2026-02-25
updated_at: 2026-02-26
completed_at: 2026-02-26
milestone: "M6"
phase: "Integration & QA"
depends_on: [TICKET-0104]
blocks: [TICKET-0106]
tags: [icons, regeneration, contrast, method-a, svg]
---

## Summary

The current production icons in `game/assets/icons/` are too dark against the game's UI panel backgrounds. Using the contrast requirements defined in TICKET-0104, update the Method A Python SVG generator to apply the approved contrast-compliant fill palette and regenerate all 29 icons. Replace the existing files in-place — integration code (TICKET-0099/0100) does not need to change.

## Acceptance Criteria

- [x] Read `docs/art/icon-style-guide-items.md` and `docs/art/icon-style-guide-hud.md` (post TICKET-0104 amendments) and identify the approved fill hex values and contrast threshold
- [x] Update the Method A Python SVG generator to use the approved fill palette
- [x] Regenerate all 29 icons:
  - 9 item icons → `game/assets/icons/item/` (replace in-place)
  - 20 HUD/functional icons → `game/assets/icons/hud/` (replace in-place)
- [x] All regenerated icons visually verified at 16px and 48px for legibility — confirm icons are clearly readable against their known background colors before committing
- [x] File names unchanged — integration code must require zero changes
- [x] Source experiment archive (`docs/art/icon-experiments/method-a/`) updated to reflect the revised generator output (replace archived SVGs with the new versions so the archive stays current)
- [x] Committed to `main` with a clear commit message referencing both this ticket and TICKET-0104

## Implementation Notes

- The Python SVG generator was used in TICKET-0092 — locate it in `docs/art/icon-experiments/method-a/` or wherever it was committed during that ticket
- Only the fill colors (and stroke/outline if required by the style guide amendment) need to change. Do not alter icon shapes, proportions, or dimensions.
- If the style guide requires a light outline/drop-shadow for contrast, implement it in the SVG generator as a `<filter>` or explicit stroke element — do not add it manually per-icon
- Godot imports SVG natively; no import settings changes should be needed if the SVG structure is otherwise unchanged

## Activity Log

- 2026-02-25 [producer] Created ticket — icon contrast fix. Depends on TICKET-0104 style guide amendments. Blocks TICKET-0106 visual QA.
- 2026-02-26 [technical-artist] DONE — Updated generator: item icons stroke="#F1F5F9", HUD icons stroke="#FFFFFF" + fill="#FFFFFF". Regenerated all 29 icons to both game/assets/icons/ and docs/art/icon-experiments/method-a/. Commit 54335a0, PR #74.
