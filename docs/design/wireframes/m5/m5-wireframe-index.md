# M5 Wireframe Index

**Owner:** ui-ux-designer
**Ticket:** TICKET-0065
**Last Updated:** 2026-02-24

> Master index of all M5 UI/UX wireframe deliverables. Each file is the design gate for the corresponding implementation ticket. No implementation ticket may begin without game-designer approval of the relevant wireframe.

---

## Deliverables

| Wireframe | File | Blocks Ticket | Status |
|-----------|------|---------------|--------|
| Tech Tree UI | [`tech-tree.md`](tech-tree.md) | TICKET-0068 | IN_REVIEW |
| Fabricator Interaction Panel | [`fabricator-panel.md`](fabricator-panel.md) | TICKET-0069 | IN_REVIEW |
| Mining Minigame Overlay | [`minigame-overlay.md`](minigame-overlay.md) | TICKET-0070 | IN_REVIEW |
| Drone Programming UI | [`drone-programming.md`](drone-programming.md) | TICKET-0072 | IN_REVIEW |
| Third-Person Scan/Mine HUD | [`third-person-hud.md`](third-person-hud.md) | TICKET-0071 | IN_REVIEW |

---

## Style Compliance

All wireframes in this directory comply with the M3 style guide at `docs/design/ui-style-guide.md`. No new colors, typography tokens, or component patterns are introduced. The following established components are reused:

- Panel, Button, Progress Bar, Star Rating, Notification Toast — all per style guide
- Recycler panel pattern (M4) reused as baseline for Fabricator panel
- Scanner readout and mining progress bar from M3 reused in third-person HUD (repositioned only)

---

## Gamepad-First Compliance

All five designs specify gamepad as first-class input:
- All interactive elements ≥ 48x48px minimum touch/focus target
- Focus navigation defined for every interactive screen
- All designs legible at TV viewing distance (3m / 10ft from 1080p)
- Focus always visible — no invisible focus states

---

## Next Steps

1. Game Designer reviews and approves each wireframe
2. On approval: implementation tickets (TICKET-0068 through TICKET-0072) may begin
3. Gameplay Programmer wires logic using exported properties/signals documented in each wireframe
