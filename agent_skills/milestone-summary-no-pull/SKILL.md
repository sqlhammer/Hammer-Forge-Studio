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
- Always end your summary with a bulleted list of agents who are unblocked and ready to take their next steps. Only list agents whose next ticket has all dependencies DONE — do NOT list agents who are waiting on an incomplete dependency.
- If the milestone is fully complete except for Studio Head sign-off (all tickets DONE, QA gate passed), check for a UAT sign-off file in `docs/studio/reports/` matching the pattern `*-[milestone]-uat-signoff.md`. If found, include its relative path prominently in the summary so the Studio Head can locate it easily.
- **Output format: plain GitHub-flavored markdown only. Paste the script's pipe table verbatim. NEVER reformat it into a Unicode box-drawing grid table — this generates 5× more tokens and is the primary cause of slow responses.**

# Workflow Steps (Ordered)

  1. Run `bash tools/milestone_status.sh --brief [M#]` (pass `--brief` always; pass the milestone argument if the user specified one, otherwise omit to auto-detect). `--brief` omits DONE rows and keeps output small.
  2. Run `python orchestrator/status.py` and include highlight information if it contains relevant updates not present in the milestone status script output. This may include:
     - Unblocked agents and their next steps
     - Updated phase gate statuses
     - Any critical blockers or risks that have emerged since the last milestone summary
  3. Output your summary using **plain markdown only** — paste the script output verbatim, then append:
     - Bullet-point phase gate status per phase (no table)
     - Bullet-point list of truly unblocked agents ready to act (skip any agent whose next ticket still has an open dependency)
  4. Do NOT read milestones.md unless the user specifically asks for the milestone goal text. The script output already contains everything needed for a status summary.

## Examples
/milestone-summary-no-pull
/milestone-summary-no-pull M5
/milestone-summary-no-pull 5
