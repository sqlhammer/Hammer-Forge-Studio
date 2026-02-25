---
id: TICKET-0087
title: "Asset folder structure — define permanent, temp, and archive paths"
type: TASK
status: OPEN
priority: P1
owner: producer
created_by: producer
created_at: 2026-02-25
updated_at: 2026-02-25
milestone: "M6"
milestone_gate: "M5"
phase: "Foundation"
depends_on: []
blocks: [TICKET-0097]
tags: [icons, folder-structure, foundation, producer]
---

## Summary

Before experiments begin, the three asset locations used in this milestone must be defined and the directory structure created on disk. This prevents path confusion during production and integration, and ensures agents know exactly where to commit each category of icon output.

## Acceptance Criteria

- [ ] The following three directory paths are created in the repository (empty `.gitkeep` files used to commit empty dirs):
  - `game/assets/icons/` — permanent approved icons; these ship with the game
  - `game/assets/icons/temp/` — integration test assets placed here during TICKET-0099/0100; promoted or deleted after QA sign-off
  - `docs/art/icon-experiments/` — archive location for all experiment outputs (non-winning sets moved here after method selection in TICKET-0096/0097)
- [ ] A `docs/art/icon-experiments/README.md` is created explaining the archive structure: one subfolder per method (e.g., `method-a/`, `method-b/`, `method-c/`), each containing `item-icons/` and `hud-icons/` subfolders plus an `iteration-log.md`
- [ ] A `game/assets/icons/README.md` is created explaining: icons in root are permanent/approved; `temp/` contains integration-test assets under review; nothing in `temp/` is referenced by released code
- [ ] All created paths and their purposes are committed to `main`

## Implementation Notes

- Create directories by committing `.gitkeep` placeholder files — Git does not track empty directories
- The experiment subfolders (`method-a/`, etc.) do not need to be created now; technical-artist creates them per experiment ticket
- Coordinate with the icon needs audit (TICKET-0086) if the audit reveals additional subdirectory needs (e.g., categorized subfolders within `game/assets/icons/`)

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-25 [producer] Created ticket for M6 Foundation phase
