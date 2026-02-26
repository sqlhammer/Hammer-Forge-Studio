---
name: milestone-summary-no-pull
description: Use this when the user wants a summary of a milestone. This is a speed optimized skill that does not do any git actions, so it may be stale. Use /milestone-summary instead for a fresh report. 
---

# ROLE: PRODUCER

# Milestone Summary Instructions
When this skill is active, follow these rules:
- Do not perform any git actions. This skill is optimized for speed and may produce stale information.
- Fetch the latest state from the filesystem after pulling — never rely on session memory alone
- Always pull and read from the main repo (/c/repos/Hammer-Forge-Studio), not a worktree (may be stale)
- Do not open the Godot editor for game-state info — obtain it from tickets and handoff notes only
- Always end your summary with a bulleted list of agents who are unblocked and ready to take their next steps
- **Output format: plain GitHub-flavored markdown only. Paste the script's pipe table verbatim. NEVER reformat it into a Unicode box-drawing grid table — this generates 5× more tokens and is the primary cause of slow responses.**

# Workflow Steps (Ordered)

  1. Run `bash tools/milestone_status.sh --brief [M#]` (pass `--brief` always; pass the milestone argument if the user specified one, otherwise omit to auto-detect). `--brief` omits DONE rows and keeps output small.
  3. Output your summary using **plain markdown only** — paste the script output verbatim, then append:
     - Bullet-point phase gate status per phase (no table)
     - Bullet-point list of unblocked agents ready to act
  4. Do NOT read milestones.md unless the user specifically asks for the milestone goal text. The script output already contains everything needed for a status summary.

## Examples
/milestone-summary-no-pull
/milestone-summary-no-pull M5
/milestone-summary-no-pull 5
