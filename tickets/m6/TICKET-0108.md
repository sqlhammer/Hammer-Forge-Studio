---
id: TICKET-0108
title: "BUGFIX: icon textures loaded on every refresh in recycler, fabricator, tech tree panels"
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
tags: [icons, code-quality, ui]
---

## Summary

Three UI panels call `load()` to retrieve icon textures inside refresh methods that run on state changes, rather than caching the textures once at build/ready time:

- `recycler_panel.gd` — `_refresh_ui()` loads `RECIPE_INPUT_TYPE` and `RECIPE_OUTPUT_TYPE` icon paths on every refresh. Both are constants; the textures never change.
- `fabricator_panel.gd` — `_refresh_detail()` loads input/output slot icon textures on every detail refresh.
- `tech_tree_panel.gd` — `_refresh_card()` loads `icon_hud_lock.svg`, `icon_hud_unlock_check.svg`, and `icon_hud_unlock_chevron.svg` on every card state refresh. These three textures are used by every card and never change.

Godot's resource cache means disk is not re-read, but calling `load()` repeatedly for textures that are known at build time is an unnecessary code pattern and was flagged in the TICKET-0101 code review acceptance criteria.

## Fix

### recycler_panel.gd

Add member variables `_input_icon_tex: Texture2D` and `_output_icon_tex: Texture2D`. Load them once in `_build_ui()` (after slot icons are constructed). Remove the `load()` calls from `_refresh_ui()` and assign `.texture` directly from the cached members.

### fabricator_panel.gd

The slot icon textures depend on the selected recipe and may vary, so caching them is more involved. At minimum, avoid re-calling `load()` when the same recipe is still selected (e.g., guard with the current recipe ID). A simpler improvement: load the texture once per `_refresh_detail()` invocation and reference it twice if needed — no member variable required.

### tech_tree_panel.gd

Add class-level member variables:
```gdscript
var _lock_tex: Texture2D = null
var _unlock_check_tex: Texture2D = null
var _unlock_chevron_tex: Texture2D = null
```
Load them once in `_build_ui()` (or `_ready()`). Replace the inline `load()` calls in `_refresh_card()` with references to these cached textures.

## Acceptance Criteria

- [x] `recycler_panel.gd`: slot icon textures loaded once; `_refresh_ui()` uses cached textures
- [x] `tech_tree_panel.gd`: lock/unlock textures cached as member variables; `_refresh_card()` uses cached textures
- [x] `fabricator_panel.gd`: no repeated `load()` for the same path within a single `_refresh_detail()` call
- [x] No functional change to panel behavior

## Activity Log

- 2026-02-25 [systems-programmer] Filed during code review TICKET-0101
- 2026-02-26 [gameplay-programmer] Fixed — recycler_panel: cached _input_icon_tex/_output_icon_tex loaded once in _build_ui(); tech_tree_panel: cached _lock_tex/_unlock_check_tex/_unlock_chevron_tex loaded once in _build_ui(); fabricator_panel: added recipe-change guard with _last_detail_recipe_id to skip redundant load() calls when same recipe is selected.
