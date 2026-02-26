---
id: TICKET-0107
title: "BUGFIX: scanner_readout.gd loads star textures twice"
type: BUGFIX
status: DONE
priority: P3
owner: gameplay-programmer
created_by: systems-programmer
created_at: 2026-02-25
updated_at: 2026-02-26
completed_at: 2026-02-26
milestone: "M6"
phase: "Integration & QA"
depends_on: []
blocks: []
tags: [icons, code-quality, scanner]
---

## Summary

`scanner_readout.gd` loads `icon_hud_star_filled.svg` and `icon_hud_star_empty.svg` twice: once as local variables in `_build_ui()` (not retained) and again in `_update_readout_data()` every time deposit data refreshes. This is unnecessary duplication — the textures never change and should be cached as member variables.

## Root Cause

In `_build_ui()` (line ~126), the star textures are loaded into locals `star_filled_tex` and `star_empty_tex` to initialize the star `TextureRect` children, but these locals are discarded at end of scope.

In `_update_readout_data()` (line ~197), the same two paths are loaded again via fresh `load()` calls before updating each star's texture. Godot's resource cache means this doesn't re-read disk, but the redundancy is a code quality violation against the acceptance criteria for TICKET-0101 (no unnecessary duplication of icon loading).

## Fix

Add two private member variables:

```gdscript
var _star_filled_tex: Texture2D = null
var _star_empty_tex: Texture2D = null
```

Load them once in `_build_ui()` and store to these members. Replace the redundant `load()` calls in `_update_readout_data()` with references to the cached members.

## Acceptance Criteria

- [x] `_star_filled_tex` and `_star_empty_tex` declared as member variables in `ScannerReadout`
- [x] Loaded once in `_build_ui()` and stored to member variables
- [x] `_update_readout_data()` references members — no `load()` calls for star textures inside it
- [x] No functional change to star display behavior

## Activity Log

- 2026-02-25 [systems-programmer] Filed during code review TICKET-0101
- 2026-02-26 [gameplay-programmer] Fixed — added _star_filled_tex and _star_empty_tex member vars, loaded once in _build_ui(), removed redundant load() calls from _update_readout_data().
