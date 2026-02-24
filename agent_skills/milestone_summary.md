---
name: milestone-summary
description: Use this when the user wants a summary of a milestone.
---

# Milestone Summary Instructions
When this skill is active, follow these rules:
- Always git pull first before reporting any status
- Fetch the latest state from the filesystem after pulling — never rely on session memory alone
- Always pull and read from the main repo (/c/repos/Hammer-Forge-Studio), not a worktree (may be stale)
- When reporting ticket statuses, always include at minimum these columns: Ticket | Title | Status | Owner | Dependencies | Milestone
- Do not open the Godot editor for game-state info — obtain it from tickets and handoff notes only
- Always end your summary with a bulleted list of agents who are unblocked and ready to take their next steps

# Workflow Steps (Ordered)

  1. git pull to get the latest state of the repo
  2. Read docs/studio/milestones.md for current milestone goals and phase structure
  3. Read relevant ticket files directly from tickets/ to get live status
  4. Identify open, in-progress, and blocked tickets
  5. Check the dependency graph — flag any ticket started while a depends_on was non-DONE
  6. Assess phase gate conditions (all tickets DONE, tests passing, no cross-milestone bleed, clean dependency graph)
  7. Report status with required columns
  8. End your summary with a bulleted list of agents who are unblocked and ready to take their next steps

## Examples
/milestone-summary
/milestone-summary M5
/milestone-summary 5
