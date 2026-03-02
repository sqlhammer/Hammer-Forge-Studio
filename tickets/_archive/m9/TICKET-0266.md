---
id: TICKET-0266
title: "DESIGN: Gamepad controls for Drop and Destroy inventory actions — propose options for Studio Head review"
type: TASK
status: DONE
priority: P2
owner: ui-ux-designer
created_by: producer
created_at: 2026-03-02
updated_at: 2026-03-02
milestone: "M9"
phase: "Gamepad Bugs"
depends_on: []
blocks: []
tags: [design, gamepad, inventory, drop, destroy, ux, studio-head-review]
---

## Summary

The inventory screen shows controls for **Drop** and **Destroy** using keyboard/mouse descriptors (`[G] Drop | [Enter/A] Destroy | [Right-Click] Drop`). When a gamepad is the active controller, there are no equivalent bindings and no UI indication of how to perform these actions. The designer must propose **2–3 concrete UX patterns** for the Studio Head to choose from before implementation begins.

**This is a design task.** Do not implement. Produce a design proposal document and update the Activity Log with your recommendation. Implementation follows in a separate ticket.

## Context

- The inventory uses a grid of item slots; the player navigates with the left stick (after TICKET-0265 is resolved).
- The currently highlighted slot is the "selected" item.
- Actions needed: **Drop** (spawns item in world at player's feet) and **Destroy** (permanently removes item).
- Destroy is a destructive action and may warrant confirmation.
- The gamepad has face buttons (A/B/X/Y), shoulder buttons (LB/RB), triggers (LT/RT), D-pad, and the two stick clicks (L3/R3).
- The **A** button (JOY_BUTTON_A) is already mapped to **Destroy** (`interact` action used as confirm in menus). Do not reassign A.

## Design Options to Evaluate

Evaluate at least the following options. Add others if warranted.

### Option A — Dedicated face buttons
Assign specific face buttons directly:
- **Y (Triangle)** = Drop one
- **X (Square)** = Destroy (with a brief 1-second hold to prevent accidental destruction)

_Pros:_ Fast, no sub-menus, discoverable via on-screen hint.
_Cons:_ Consumes two face buttons that might be wanted elsewhere; hold-to-destroy requires clear visual feedback.

---

### Option B — Context popup on Y button
Pressing **Y (Triangle)** opens a small popup menu over the selected slot:
```
╔══════════════╗
║  Drop Item   ║
║  Destroy     ║
║  Cancel      ║
╚══════════════╝
```
Navigate with D-pad up/down; confirm with **A**; cancel with **B**.

_Pros:_ Groups actions clearly; extensible (future actions like "equip", "examine" fit here); familiar console UI pattern.
_Cons:_ Two-step interaction (open menu, then choose); slower than direct buttons.

---

### Option C — Hold LT (left trigger) for action overlay
Holding **LT** dims the inventory grid slightly and reveals context labels on the face buttons:
- **A** = Destroy (hold LT + tap A)
- **X** = Drop (hold LT + tap X)
Release LT to dismiss without acting.

_Pros:_ Shift-key pattern keeps face buttons free for navigation; no popup required; works cleanly with one hand managing stick navigation.
_Cons:_ Less discoverable unless a hint is shown; trigger-as-modifier is unconventional on console (more common on PC).

---

## Deliverables

1. **Design Proposal** — post to `docs/studio/design-proposals/gamepad-inventory-actions.md`
   - Evaluate each option (pros, cons, fit with existing UX, implementation complexity estimate)
   - State a **recommended option** with rationale
   - Include rough ASCII mockups for any overlay or popup UI

2. **Activity Log entry** — summarize your recommendation here so the Producer can route to Studio Head for a decision.

The Studio Head will select an option; the Producer will then open an implementation ticket assigned to the gameplay-programmer.

## Acceptance Criteria

- [ ] Design proposal document committed to `docs/studio/design-proposals/gamepad-inventory-actions.md`.
- [ ] At least three options evaluated with pros/cons.
- [ ] A clear recommended option is stated.
- [ ] ASCII mockups included for any popup/overlay option.
- [ ] Activity Log updated with recommendation summary.
- [ ] **No implementation.** This ticket is complete when the proposal is ready for Studio Head review.

## Activity Log

- 2026-03-02 [producer] Filed — UAT rejection. Inventory controls descriptor only shows keyboard/mouse bindings; no gamepad equivalent for Drop or Destroy exists. Designer to propose options before implementation.
- 2026-03-02 [ui-ux-designer] Starting work. Evaluating options A, B, C plus an additional Option D. Will produce proposal at docs/studio/design-proposals/gamepad-inventory-actions.md.
- 2026-03-02 [ui-ux-designer] Proposal complete. Recommendation: **Option B — Context Popup on Y Button** (modified: single popup, hold-A-within-popup for Destroy rather than double dialog). Rationale: best extensibility for future item actions, single face-button commitment (Y only), familiar console pattern consistent with Outer Wilds/Hades references, strong accident protection without friction overhead of a second dialog. Proposal committed to docs/studio/design-proposals/gamepad-inventory-actions.md. Awaiting Studio Head decision; Producer to route for review.
