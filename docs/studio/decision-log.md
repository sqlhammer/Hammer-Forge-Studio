# Decision Log

**Owner:** producer
**Last Updated:** 2026-02-24

> Authoritative record of architectural and design decisions that affect multiple systems, agents, or milestones. Each entry explains the decision, its rationale, and its downstream impact.

---

## Decision Schema

| Field | Description |
|-------|-------------|
| ID | Sequential identifier (DEC-NNNN) |
| Date | Date decision was made |
| Author | Who made the decision (Studio Head, Producer, etc.) |
| Status | Active / Superseded / Reverted |
| Impact | Scope of affected systems and documents |

---

## DEC-0001 — Non-abstract UI menus do not pause the game

**Date:** 2026-02-24
**Author:** Studio Head
**Status:** Active

### Decision

The game is paused only for menus that are more abstract than the game world itself — such as saving the game, changing key bindings, or accessing system settings. Menus that are diegetically part of the game world (inventory, machine interaction panels, drone programming, ship management, tech tree) do **not** pause the game.

When one of these menus is open:
- The player's movement and action inputs are suppressed — they cannot walk, scan, mine, or interact with the world.
- All automated game systems continue to run: drones travel and extract, Recycler jobs progress, Fabricator jobs progress, ship globals tick.
- Mouse mode switches to `MOUSE_MODE_VISIBLE` for menu interaction.
- On close: gameplay inputs are restored, mouse mode returns to `MOUSE_MODE_CAPTURED`.

The correct implementation is to suppress gameplay inputs via `InputManager` on menu open/close — **not** via `get_tree().paused`.

### Rationale

Pausing the game for in-world menus creates an inconsistent and exploitable experience. A player should not be able to "freeze" drone activity or machine timers simply by opening inventory. Menus like inventory and machine panels are abstractions of actions the player is already performing in the world — they are not interruptions to it. Keeping time running creates a more coherent and immersive game loop.

### Violations Found (as of 2026-02-24)

The following were implemented or designed under the old pause model and require remediation:

**Implemented code (3 scripts + 1 workaround):**
- `game/scripts/ui/inventory_screen.gd` — calls `get_tree().paused = true/false`
- `game/scripts/ui/recycler_panel.gd` — calls `get_tree().paused = true/false`
- `game/scripts/ui/module_placement_ui.gd` — calls `get_tree().paused = true/false`
- `game/scripts/levels/test_world.gd` — sets `Recycler.process_mode = ALWAYS` as a workaround to keep Recycler running through the pause (becomes obsolete)

**Design documents:**
- `docs/design/systems/input-system.md` — Pause State section defines pause-on-menu-open as the model
- `docs/design/wireframes/m3/inventory.md` — specifies `get_tree().paused = true` on open
- `docs/design/wireframes/m4/recycler-panel.md` — specifies `get_tree().paused = true` on open
- `docs/design/wireframes/m4/recycler-machine.md` — describes player as "stationary (game paused)"
- `docs/design/wireframes/m5/fabricator-panel.md` — specifies same pause pattern (not yet implemented)
- `docs/design/wireframes/m5/tech-tree.md` — specifies `get_tree().paused = true` on open (not yet implemented)
- `docs/design/wireframes/m5/drone-programming.md` — specifies `get_tree().paused = true` on open (not yet implemented)
- `docs/design/ui-style-guide.md` — groups inventory with pause as same overlay category
- `docs/studio/sop-ship-machine.md` — codifies `PROCESS_MODE_ALWAYS` as the machine pattern (workaround, not correct)

### Remediation Tickets

| Ticket | Title | Owner |
|--------|-------|-------|
| TICKET-0077 | Compliance — remove game pause from in-world UI panels | gameplay-programmer |
| TICKET-0078 | Compliance — update UI wireframes and style guide for non-pause model | ui-ux-designer |
| TICKET-0079 | Compliance — update input system design doc | systems-programmer |
| TICKET-0080 | Compliance — update ship machine SOP | producer |

---
