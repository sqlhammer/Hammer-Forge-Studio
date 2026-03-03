---
id: TICKET-0293
title: "M11 Scene-First remediation — Inventory Screen and Inventory Action Popup"
type: TASK
status: DONE
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-03-03
updated_at: 2026-03-03
milestone: "M11"
phase: "Remediation"
depends_on: []
blocks: []
tags: [standards, scene-first, remediation, ui, inventory]
---

## Summary

Refactor `inventory_screen.gd` and `inventory_action_popup.gd` from programmatic UI construction into .tscn scenes.

---

## Acceptance Criteria

- [x] `inventory_screen.gd`: create `inventory_screen.tscn`; move entire screen (dim rect, inventory grid with 15 slots each containing PanelContainer+TextureRect+Label, detail panel, ShipStatsSidebar, InventoryActionPopup, destroy confirm dialog) to scene; remove LAYOUT_IN_READY violations (layer, visible at lines 72–73)
- [x] `inventory_action_popup.gd`: create `inventory_action_popup.tscn`; move entire popup (PanelContainer, title Label, HSeparator, 3 action rows, destroy fill ColorRect) to scene; remove LAYOUT_IN_READY violations (visible, mouse_filter at lines 59–61); fix docstring on line 1 (# → ##)
- [x] Both scripts: replace all `_build_ui()` construction with `@onready` vars; verify inventory open/close, slot interactions, and action popup work correctly

---

## Implementation Notes

See audit report `docs/studio/reports/2026-03-03-m11-gdscript-audit.md` Section 2 rows for `inventory_screen.gd` (lines 242–451, 72–73) and `inventory_action_popup.gd` (lines 170–248, 59–61). Priority 1 in Section 5. Note: the InputManager bypass in `inventory_screen.gd` line 84 is addressed by a separate ticket (TICKET-0301).

---

## Handoff Notes

(Leave blank until handoff occurs.)

---

## Activity Log

- 2026-03-03 [producer] Created ticket — Phase 2 remediation from M11 GDScript audit report (TICKET-0290)
- 2026-03-03 [gameplay-programmer] Starting work — Scene-First remediation for inventory_screen.gd and inventory_action_popup.gd
- 2026-03-03 [gameplay-programmer] DONE — commit c2c0623, PR https://github.com/sqlhammer/Hammer-Forge-Studio/pull/334 (merged)
