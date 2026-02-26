---
id: TICKET-0097
title: "Promote winning icons and archive experiments"
type: TASK
status: DONE
priority: P1
owner: technical-artist
created_by: producer
created_at: 2026-02-25
updated_at: 2026-02-26
milestone: "M6"
milestone_gate: "M5"
phase: "Integration & QA"
depends_on: [TICKET-0087, TICKET-0096]
blocks: [TICKET-0099, TICKET-0100]
tags: [icons, asset-management, promotion, archive]
---

## Summary

Move the winning experiment's icon outputs into the permanent game asset location. Archive all non-winning experiment outputs in their experiment subfolders under `docs/art/icon-experiments/`. After this ticket, `game/assets/icons/` contains the production-ready icon set that TICKET-0099 and TICKET-0100 will wire into the game.

## Acceptance Criteria

- [x] Winning method identified from TICKET-0096 Handoff Notes
- [x] All item icons from the winning experiment copied to `game/assets/icons/item/`
- [x] All HUD/functional icons from the winning experiment copied to `game/assets/icons/hud/`
- [x] If Studio Head approved a hybrid (different method for items vs HUD), item icons sourced from one experiment and HUD icons from the other — both placed in their respective subdirs
- [x] Non-winning experiment output folders remain in `docs/art/icon-experiments/` (no files deleted)
- [x] `game/assets/icons/temp/` is confirmed empty (no experiment assets placed here — temp is for integration-test assets only, populated by TICKET-0099/0100)
- [x] All icon files in `game/assets/icons/` follow the naming conventions from TICKET-0090/0091 style guides
- [x] Committed to `main` with a clear commit message referencing the winning method

## Implementation Notes

- Use `git mv` or copy + add — do not delete the originals in `docs/art/icon-experiments/`; the archive must remain intact
- If the winning experiment's files are already correctly named per the style guide naming convention, no renaming is needed. If they deviate, rename during promotion
- Create `game/assets/icons/item/` and `game/assets/icons/hud/` subdirectories if not already present (TICKET-0087 created the parent `game/assets/icons/` structure)

## Handoff Notes

**Winning method:** Method A — Programmatic SVG (Python direct XML construction)

- Source icons: `docs/art/icon-experiments/method-a/item-icons/` (9 SVGs) and `docs/art/icon-experiments/method-a/hud-icons/` (20 SVGs)
- **No hybrid.** All 29 icons from Method A only. Do not mix with Method B or C outputs.
- No CC BY 3.0 attribution required.

## Activity Log

- 2026-02-25 [producer] Created ticket for M6 Integration & QA phase
- 2026-02-26 [producer] Updated handoff notes with Studio Head's method selection: Method A Only (TICKET-0096 DONE)
- 2026-02-26 [technical-artist] Promoted 29 Method A icons to production: 9 item → game/assets/icons/item/, 20 HUD → game/assets/icons/hud/. Archives preserved. temp/ empty. Committed c8baf26, PR #68 merged. DONE.
