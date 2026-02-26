---
id: TICKET-0122
title: "Add amber warning tier to battery bar icon tinting"
type: FEATURE
status: OPEN
priority: P3
owner: ""
created_by: qa-engineer
created_at: 2026-02-26
updated_at: 2026-02-26
milestone: "M7"
phase: "Build & Features"
depends_on: []
blocks: []
tags: [battery, hud, ui, icon-tinting, backlog]
---

## Summary

The battery bar icon currently transitions directly from teal (normal, 26-99%) to coral (critical, ≤25%). The icon-needs.md originally specified a 3-tier color system: Teal (full) → Amber (low) → Coral (critical). Add an amber (#FFB830) intermediate warning tier to `battery_bar.gd`.

## Acceptance Criteria

- [ ] Battery icon shows amber (#FFB830) tint at a mid-low charge threshold (e.g., 25-50%)
- [ ] Teal (#00D4AA) remains the normal state above the warning threshold
- [ ] Coral (#FF6B5A) remains the critical state at the lowest threshold
- [ ] Green (#4ADE80) remains the full (100%) state
- [ ] Existing tests pass; add test for the new amber tier

## Implementation Notes

- Modify `_get_state_color()` in `game/scripts/ui/battery_bar.gd`
- Add a `WARNING_THRESHOLD` constant (e.g., 0.50) alongside the existing `CRITICAL_THRESHOLD` (0.25)
- Update `docs/art/icon-needs.md` battery entry if thresholds change

## Activity Log

- 2026-02-26 [qa-engineer] Created from TICKET-0102 QA Finding 1 — battery amber warning tier missing. Studio Head directed: add to backlog.
- 2026-02-26 [producer] Scheduled into M7 — Ship Interior milestone
