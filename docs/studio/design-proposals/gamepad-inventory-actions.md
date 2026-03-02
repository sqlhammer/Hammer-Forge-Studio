# Design Proposal: Gamepad Controls for Inventory Drop and Destroy Actions

**Ticket:** TICKET-0266
**Author:** ui-ux-designer
**Date:** 2026-03-02
**Status:** Awaiting Studio Head decision

---

## Problem Statement

The inventory screen currently shows controls only as keyboard/mouse descriptors (`[G] Drop | [Enter/A] Destroy | [Right-Click] Drop`). When a gamepad is the active controller, there are no equivalent bindings and no UI indication of how to perform Drop or Destroy. Players using a controller have no discoverable path to these actions.

**Constraints fixed before this proposal:**
- **A button (JOY_BUTTON_A / `interact`)** is already mapped to Destroy — this binding is confirmed and must not change.
- Left-stick navigation is being resolved in TICKET-0265 (discrete step navigation, latching behaviour). Proposals may assume the d-pad and left stick navigate the inventory grid one slot at a time.
- Destroy is a destructive, irreversible action; the pattern must reduce the risk of accidental activation.
- The gamepad face buttons (A/B/X/Y), shoulder buttons (LB/RB), triggers (LT/RT), D-pad, and stick clicks (L3/R3) are all available.

---

## Option A — Dedicated Face Buttons (Y = Drop, X = Hold-to-Destroy)

Assign additional face buttons directly to inventory actions:

- **Y (Triangle)** → Drop one (immediate, no hold)
- **X (Square)** → Destroy — requires **1-second hold** to prevent accidental activation; a progress arc fills around the button icon while held

On-screen hint bar at the bottom of the inventory panel updates when a slot is focused:

```
┌────────────────────────────────────────────────────────────────────┐
│  INVENTORY                                                         │
│                                                                    │
│  [ item grid ... ]                                                 │
│                                                                    │
│  ──────────────────────────────────────────────────────────────    │
│  [A] Select/Confirm  [B] Close  [Y] Drop  [X] Hold to Destroy     │
└────────────────────────────────────────────────────────────────────┘
```

**Pros:**
- Single-step interaction — fastest path for power users
- Consistent with common console inventory patterns (Borderlands, Dead Cells)
- Fully discoverable via the hint bar
- Hold-to-destroy provides meaningful protection against accidents
- No popup penalty for players iterating through many items

**Cons:**
- Consumes two face buttons (Y and X), which could conflict with future actions (e.g., Equip, Examine, Mark as Favourite)
- Hold-to-destroy requires visual feedback implementation (progress arc or fill bar)
- Slightly asymmetric: Drop is instant while Destroy requires a hold — players may expect parity

**Implementation complexity:** Low. Two new input bindings, one hold-timer with feedback.

---

## Option B — Context Popup on Y Button

Pressing **Y (Triangle)** opens a small action popup centred over (or adjacent to) the selected inventory slot:

```
         ┌──────────────────┐
         │  Item Actions    │
         ├──────────────────┤
         │ ▶ Drop Item      │
         │   Destroy Item   │
         │   Cancel         │
         └──────────────────┘
```

Navigation: **D-pad up/down** (or left stick — per TICKET-0265 discrete step navigation). Confirm with **A**. Cancel with **B** or **Y** again. First item in the list is focused by default to favour the safer action.

If "Destroy Item" is selected, a secondary confirmation prompt appears:

```
         ┌──────────────────────────────┐
         │  Destroy [Item Name]?        │
         │  This cannot be undone.      │
         ├──────────────────────────────┤
         │  [A] Confirm   [B] Cancel    │
         └──────────────────────────────┘
```

On-screen hint:

```
┌────────────────────────────────────────────────────────────────────┐
│  INVENTORY                                                         │
│                                                                    │
│  [ item grid ... ]                                                 │
│                                                                    │
│  ──────────────────────────────────────────────────────────────    │
│  [A] Select  [B] Close  [Y] Actions                               │
└────────────────────────────────────────────────────────────────────┘
```

**Pros:**
- Extensible: future actions (Equip, Examine, Favourite, Transfer) slot in without consuming more face buttons
- Strongest protection against accidental Destroy (double confirmation)
- Familiar console UI pattern (similar to Hades, Hollow Knight, Outer Wilds on controller)
- Single face button commitment (Y only)
- Keeps A/B as primary navigation verbs

**Cons:**
- Two-step minimum for Drop, three-step for Destroy — slower for power users performing bulk operations
- Requires popup scene implementation and focus management within the popup
- Modal popup can interrupt the spatial flow of inventory browsing
- Double confirmation for Destroy may feel patronising to experienced players

**Implementation complexity:** Medium. Requires a reusable popup scene, focus-trap navigation, and confirmation dialog.

---

## Option C — Hold LT (Left Trigger) for Action Modifier Overlay

Holding **LT** activates an "action mode" overlay. The inventory grid dims slightly and revised face-button labels appear:

```
┌────────────────────────────────────────────────────────────────────┐
│  INVENTORY            [ LT HELD — ACTION MODE ]                   │
│                                                                    │
│  [ item grid dims to ~60% opacity ... ]                           │
│                                                                    │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │  [A] Destroy    [X] Drop    [B] Cancel    [Y] —            │   │
│  └────────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────────┘
```

Release LT to dismiss without acting. Destroy (LT + A) still uses the existing `interact` binding — it just requires LT to be held simultaneously, reducing accident risk. Drop is LT + X.

**Pros:**
- Face buttons remain free in normal navigation mode (no button clutter)
- Keeps navigation and action modes cleanly separated
- No popup required — overlay is lightweight
- Shift-key metaphor is natural to PC players who may cross-play

**Cons:**
- Least discoverable option — players must find the LT modifier hint
- Trigger-as-modifier is unconventional on console (more natural on PC); may feel foreign to console-primary players
- Holding a trigger while tapping a face button is ergonomically awkward for some players
- LT may already be used or reserved for other inventory interactions (e.g., scroll, page)
- Conflicts with any future "hold LT to sprint/lock-on" patterns outside inventory

**Implementation complexity:** Medium-low. Requires input modifier state tracking and a secondary hint bar; no popup scene.

---

## Option D — Confirm-to-Drop via B Button + Hold-to-Destroy via X (No Popup)

Repurpose **B** as a secondary action when inside the inventory (B normally closes the inventory from the grid level, but only acts as close when no item is selected/focused):

- **B (when slot focused)** → Drop one (same single-button drop pattern many RPGs use for quick-discard)
- **X (hold 1 second)** → Destroy (hold-to-destroy with progress arc)
- **B (when no slot focused / grid not active)** → Close inventory (existing behaviour preserved)

On-screen hint updates contextually based on whether a slot has focus:

```
┌────────────────────────────────────────────────────────────────────┐
│  INVENTORY                                                         │
│                                                                    │
│  [ item grid ... ]              [slot focused state]              │
│                                                                    │
│  ──────────────────────────────────────────────────────────────    │
│  [A] Confirm  [B] Drop  [Y] —  [X] Hold to Destroy  [Menu] Close  │
└────────────────────────────────────────────────────────────────────┘
```

**Pros:**
- Doesn't consume Y — leaves it free for future use
- B-as-drop is common in action-RPG inventories (Diablo-style quick-discard)
- Mirrors the asymmetric hold pattern from Option A but with different button pairing
- Close can be moved to the Menu/Start button (many games shift close to Menu inside inventory to free up B)

**Cons:**
- Redefining B's behaviour in context requires clear visual signposting — players trained on "B = back/close" will need to relearn
- Two different hold durations/behaviours (instant drop vs. hold-to-destroy) still present; players may accidentally drop rather than close
- Requires context-sensitive hint bar logic (slot-focused vs. no-focus state)

**Implementation complexity:** Low-medium. Context-sensitive hint bar update + hold timer; no popup.

---

## Comparison Summary

| | Button Efficiency | Discovery | Accident Safety | Extensibility | Implementation |
|---|---|---|---|---|---|
| **Option A** (Y + X hold) | Uses Y + X | High (hint bar) | Good (hold) | Low | Low |
| **Option B** (Y popup) | Uses Y only | High (hint bar) | Excellent (double confirm) | High | Medium |
| **Option C** (LT modifier) | Uses LT + A/X | Low (needs hint) | Good (two-input) | Medium | Medium-low |
| **Option D** (B + X hold) | Uses B + X | Medium | Fair | Low | Low-medium |

---

## Recommendation: Option B — Context Popup on Y Button

**Recommended:** **Option B**, with a simplified single confirmation step for Destroy (remove the secondary dialog; replace with hold-to-confirm directly within the popup selection, i.e., hold A while "Destroy Item" is focused).

**Rationale:**

1. **Extensibility is the decisive factor.** The inventory is a growing system. As the game adds more item types, the likelihood of needing additional item actions (Equip, Examine, Transfer to Ship, Mark as Favourite) is high. Option B's popup model absorbs these cleanly without consuming more face buttons. Options A and D hit a wall at 2–3 dedicated actions.

2. **Single face-button commitment.** Only Y is consumed. A (confirm), B (cancel/close), and the triggers remain available for navigation and future use.

3. **Familiar pattern for the target platform.** The style guide cites Outer Wilds and Hades as aesthetic references — both use single-button popup/action menus on controller. Players coming from those games will find this immediately legible.

4. **Adequate accident protection without double dialogs.** Instead of a two-dialog approach, I recommend hold-A-within-popup for Destroy (hold A for 0.8 seconds while the "Destroy Item" row is focused, with a progress fill on the row highlight). This is a single popup, single hold — fast enough for intentional use, resistant to accidental presses.

5. **Consistent with style guide component patterns.** The Tooltip/Info Popup and Panel components in `ui-style-guide.md` give us a ready-made visual language for the popup. No new component category is needed.

**Modified Option B — Action Popup with Hold-to-Confirm Destroy:**

```
         ┌──────────────────────┐
         │    Item Actions      │
         ├──────────────────────┤
         │ ▶ Drop Item    [A]   │
         │   Destroy      [A]▓▓ │  ← hold A to fill; releases = confirm
         │   Cancel       [B]   │
         └──────────────────────┘

   Navigation: D-pad ↑↓ or left stick ↑↓
   Confirm: [A]   Cancel/Close: [B] or [Y]
```

Hint bar while popup is open:

```
   [A] Confirm / Hold to Destroy   [B] Cancel   D-pad ↑↓ Navigate
```

This approach collapses three steps (open popup → select → confirm dialog) into two (open popup → hold confirm) while maintaining strong protection for the destructive action.

---

## Implementation Notes for Gameplay Programmer

When the Studio Head selects an option, the implementation ticket should document:

- **For Option B (recommended):** A `InventoryActionPopup` Control scene; signals: `action_requested(action: String, slot_index: int)` where `action` is `"drop"` or `"destroy"`; the popup must manage its own focus trap; the inventory grid pauses navigation input while popup is open.
- **For Option A or D:** New `InputMap` actions `inventory_drop` (JOY_BUTTON_Y for A, JOY_BUTTON_B for D) and `inventory_destroy` (JOY_BUTTON_X for both); hold timer in the inventory controller script; `hold_progress_updated(progress: float)` signal for UI feedback.
- **For Option C:** Modifier state `_lt_held: bool` tracked in the inventory input handler; secondary hint bar visible only while LT is held; no new scene required.

---

*Proposal ready for Studio Head review. No implementation has been performed.*
