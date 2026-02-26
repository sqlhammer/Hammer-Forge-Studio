---
id: TICKET-0141
title: "Bugfix — ship machines are pre-placed at game start; module zones should begin empty"
type: BUGFIX
status: IN_PROGRESS
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-26
updated_at: 2026-02-26
milestone: "M7"
phase: "QA"
depends_on: []
blocks: [TICKET-0130]
tags: [ship-interior, machine-room, gameplay, bugfix, p1]
---

## Summary

When the game starts, the Recycler, Fabricator, and Automation Hub are already fully placed on their module zone pads in the machine room. Machines should not be pre-built — the module zones should start empty and require the player to install machines.

**Note:** The M7 spec described the zones as "3 occupied by Recycler/Fabricator/Automation Hub." This ticket supersedes that intent — the correct design is empty zones at game start. The machines exist in the game world but are not pre-installed in the ship.

## Steps to Reproduce

1. Launch the game
2. Enter the ship
3. Navigate to the machine room

## Expected Behavior

All 4 module zones are empty at game start. No machines are pre-installed. Each zone displays its empty floor marking and an install/place prompt.

## Actual Behavior

The Recycler, Fabricator, and Automation Hub are already placed and visible on their zone pads when the game loads. The player has no opportunity to install them — they are part of the static scene.

## Acceptance Criteria

- [ ] All 4 module zones are empty when a new game session starts
- [ ] No machines are spawned or visible in the module zones at startup
- [ ] Each empty zone displays its floor marking (teal pad) and an appropriate install prompt when the player looks at it
- [ ] Machines remain installable via the existing module install mechanic

## Implementation Notes

- The ship interior scene (`ship_interior.tscn` or equivalent) likely has the machine nodes as static children — remove them from the scene tree as pre-placed nodes
- Machines should be spawned/placed dynamically when installed, not embedded in the scene at edit time
- Check whether the module manager or ship state tracks installed machines — game start state should reflect empty slots

## Activity Log

- 2026-02-26 [producer] Created — design finding during M7 QA review; supersedes M7 spec intent of pre-occupied zones
- 2026-02-26 [gameplay-programmer] IN_PROGRESS — Starting work. Fix: remove Recycler, Fabricator, AutomationHub static instances from ship_interior.tscn so all 4 zones begin empty.
