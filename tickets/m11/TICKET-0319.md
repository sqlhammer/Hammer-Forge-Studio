---
id: TICKET-0319
title: "M11 Studio Head — UAT play-test sign-off"
type: TASK
status: IN_PROGRESS
priority: P1
owner: studio-head
created_by: producer
created_at: 2026-03-07
updated_at: 2026-03-07
milestone: "M11"
phase: "QA"
depends_on: [TICKET-0304, TICKET-0313, TICKET-0314, TICKET-0315, TICKET-0316, TICKET-0317, TICKET-0318]
blocks: []
tags: [uat, sign-off, studio-head, milestone-close]
---

## Summary

Studio Head reviews the M11 UAT sign-off document and performs hands-on play-testing to
approve or reject each manual feature. When all 9 features are marked, the Studio Head
signs off at the bottom of the document and marks this ticket DONE.

M11 scope: GDScript Scene-First rule compliance remediation across the full codebase,
standards fixes (input bypass, Array types, docstrings), and resolution of 14 regression
bugs discovered during QA (TICKET-0305 through TICKET-0318).

**Test suite status:** 1009 tests, 0 failures (run 2026-03-04).

---

## UAT Sign-Off Document

`docs/studio/reports/2026-03-06-m11-uat-signoff.md`

Open this file and follow the instructions. All `manual-playtest` items require hands-on
testing in the Godot editor. Automated items are pre-verified and require no action.

---

## Acceptance Criteria

- [ ] All 9 features in the UAT sign-off document are marked `✅ Approved` or `❌ Rejected`
- [ ] The Final Sign-Off section at the bottom of the UAT document is completed and dated
- [ ] If any features are `❌ Rejected`, the Producer is notified and bug tickets are opened
      before this ticket is marked DONE
- [ ] This ticket is marked DONE

---

## Features to Play-Test

| # | Feature | Tickets |
|---|---------|---------|
| 1 | Inventory Screen opens, closes, and displays items | TICKET-0293 |
| 2 | Inventory Action Popup appears on item interaction | TICKET-0293, TICKET-0308 |
| 3 | Navigation Console opens and displays all 3 biomes | TICKET-0292, TICKET-0309 |
| 4 | Biome travel executes correctly (fade + spawn on terrain) | TICKET-0292, TICKET-0311, TICKET-0313–0318 |
| 5 | Tech Tree panel shows items with correct prerequisites | TICKET-0295, TICKET-0306 |
| 6 | Fabricator panel opens and queues crafting jobs | TICKET-0291, TICKET-0311, TICKET-0312 |
| 7 | Ship boarding prompt only shows when aiming at hull | TICKET-0305 |
| 8 | HUD elements correctly positioned and functional | TICKET-0294, TICKET-0300, TICKET-0307 |
| 9 | Ship interior loads with all module zones accessible | TICKET-0297, TICKET-0298, TICKET-0299 |
| 10 | Main Menu loads and starts a new game | TICKET-0296 |

> Note: The UAT doc lists 9 checklist items; feature #10 (Main Menu) is item 9 in the doc
> and biome travel is split from console open/close into two checklist entries. Total = 9.

---

## Quick-Start: Recommended Test Session Order

1. **DebugLauncher → begin-wealthy** — fast path to inventory, fabricator, tech tree, HUD
2. **Board ship → visit each module zone** — covers fabricator, recycler, tech tree, nav console
3. **Travel to each biome** — covers nav console travel + player spawn
4. **Exit ship → approach hull** — covers boarding prompt
5. **Launch via `res://game.tscn`** — covers main menu

---

## Handoff Notes

(Leave blank until sign-off is granted.)

---

## Activity Log

- 2026-03-07 [producer] Created ticket — M11 Studio Head UAT play-test sign-off. All QA and
  bug-fix dependencies (TICKET-0304, TICKET-0313–0318) are DONE. UAT doc updated to remove
  TICKET-0313 open-issue caveats; biome travel test is now fully unblocked.
- 2026-03-07 [studio-head] Starting work — reviewing UAT sign-off document and marking features.
