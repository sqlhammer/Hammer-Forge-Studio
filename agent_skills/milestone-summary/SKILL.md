---
name: milestone-summary
description: Use this when the user wants a summary of a milestone.
---

# Milestone Summary Instructions
When this skill is active, follow these rules:
- Always git pull first before reporting any status
- Fetch the latest state from the filesystem after pulling — never rely on session memory alone
- Always pull and read from the main repo (/c/repos/Hammer-Forge-Studio), not a worktree (may be stale)
- Do not open the Godot editor for game-state info — obtain it from tickets and handoff notes only
- Always end your summary with a bulleted list of agents who are unblocked and ready to take their next steps

# Workflow Steps (Ordered)

  1. `git -C /c/repos/Hammer-Forge-Studio pull` to get the latest state of the repo
  2. Run `bash tools/milestone_status.sh [M#]` (pass the milestone argument if the user specified one, otherwise omit to auto-detect the active milestone). This produces the full ticket status table and stats in one call.
  3. Read **only the target milestone section** from `docs/studio/milestones.md` — use `grep -n` or Read with offset/limit to extract just that milestone's heading through the next heading. Do NOT read the entire file.
  4. From the script output and milestone notes:
     - Present the ticket status table as-is (it already has the required columns)
     - Report the stats line (X/Y DONE, etc.)
     - Flag any dependency violations the script reported
     - Assess phase gate conditions (all tickets in phase DONE, tests passing, no cross-milestone bleed, clean dependency graph)
     - End with a bulleted list of agents who are unblocked and ready to take their next steps

## Examples
/milestone-summary
/milestone-summary M5
/milestone-summary 5
