---
name: milestone-summary
description: Use this when the user wants a summary of a milestone.
---

# ROLE: PRODUCER

# Milestone Summary Instructions
When this skill is active, follow these rules:
- Always git pull first before reporting any status
- Fetch the latest state from the filesystem after pulling — never rely on session memory alone
- Always pull and read from the main repo (/c/repos/Hammer-Forge-Studio), not a worktree (may be stale)
- Do not open the Godot editor for game-state info — obtain it from tickets and handoff notes only
- Always end your summary with a bulleted list of agents who are unblocked and ready to take their next steps
- **Output format: plain GitHub-flavored markdown only. Paste the script's pipe table verbatim. NEVER reformat it into a Unicode box-drawing grid table — this generates 5× more tokens and is the primary cause of slow responses.**

# Workflow Steps (Ordered)

  1. `git -C /c/repos/Hammer-Forge-Studio pull` to get the latest state of the repo
  2. Run `bash tools/milestone_status.sh --brief [M#]` (pass `--brief` always; pass the milestone argument if the user specified one, otherwise omit to auto-detect). `--brief` omits DONE rows and keeps output small.
  3. Run `python orchestrator/status.py` and include highlight information if it contains relevant updates not present in the milestone status script output. This may include:
     - Unblocked agents and their next steps
     - Updated phase gate statuses
     - Any critical blockers or risks that have emerged since the last milestone summary
  4. Output your summary using **plain markdown only** — paste the script output verbatim, then append:
     - Bullet-point phase gate status per phase (no table)
     - Bullet-point list of truly unblocked agents ready to act (skip any agent whose next ticket still has an open dependency)
  5. Do NOT read milestones.md unless the user specifically asks for the milestone goal text. The script output already contains everything needed for a status summary.

## Examples
/milestone-summary
/milestone-summary M5
/milestone-summary 5
