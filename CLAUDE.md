# CLAUDE.md - Hammer-Forge-Studio Development Guide

## Project Overview
**Hammer-Forge-Studio** is a game development and AI agent team orchestration project built with Godot Engine and GDScript.

## Development Environment

### Primary Tools
- **Game Development**: Godot Editor with GDScript
- **Auxiliary Work**: VS Code with Python or PowerShell

### Project Structure
- **Game Code**: `/game` directory (primary development location)
- **AI Agents**: `/agents` directory
- **Documentation & Design**: `/docs` directory

## Code Style & Standards

Refer to `docs/engineering/coding-standards.md` for all naming conventions, formatting, and comment style guidelines.

## Git Workflow

### Ticket Completion → Commit → Code Review (Separate)

**The sequence depends on where the agent is working:**

#### Working directly on `main`
1. Agent completes ticket implementation
2. Agent commits to `main` (references ticket ID in message)
3. If any new `.gd` scripts were created, follow the **GDScript UID Commit** procedure below
4. Agent pushes to remote
5. Agent marks ticket `DONE` in Activity Log with commit hash
6. Code review happens via separate `REVIEW` ticket (does NOT gate commits)

#### Working in a worktree (separate branch)
1. Agent completes ticket implementation on the worktree branch
2. Agent commits to the worktree branch (references ticket ID in message)
3. Agent pushes the branch to remote
4. Agent creates a PR from the worktree branch targeting `main`
5. Agent self-merges the PR immediately
6. If any new `.gd` scripts were created, follow the **GDScript UID Commit** procedure below
7. Agent marks ticket `DONE` in Activity Log with commit hash and PR link
8. Code review happens post-merge via a separate `REVIEW` ticket (does NOT gate the merge)

This ensures `main` is always in a working, committed state and tickets are closed without waiting on a separate agent.

### GDScript UID Commit

Godot auto-generates a `.gd.uid` sidecar file for every new `.gd` script. These files **must be committed** alongside the scripts. Godot generates them asynchronously after detecting new files in the main repo directory — they will not exist in the worktree, only on the main working tree after the files land there.

**Whenever new `.gd` files are created as part of a ticket**, after those files are on the `main` branch:

1. Pull the latest `main` into the main repository (always required when working from a worktree):
   ```bash
   git -C /c/repos/Hammer-Forge-Studio pull
   ```
2. Trigger Godot's filesystem scan via the MCP `execute_editor_script` tool:
   ```gdscript
   func run():
       EditorInterface.get_resource_filesystem().scan()
   ```
3. Wait for Godot to process the new scripts:
   ```bash
   sleep 5
   ```
4. Check for newly generated UID files in the main repository:
   ```bash
   git -C /c/repos/Hammer-Forge-Studio ls-files --others --exclude-standard -- '*.gd.uid'
   ```
5. If any exist, commit and push them to `main`:
   ```bash
   git -C /c/repos/Hammer-Forge-Studio add -- '*.gd.uid'
   git -C /c/repos/Hammer-Forge-Studio commit -m "chore: commit Godot-generated UIDs (TICKET-XXXX)"
   git -C /c/repos/Hammer-Forge-Studio push
   ```

This step must complete before marking the ticket `DONE`.

### Commits
- Write summarized commit messages that reference the ticket ID (e.g., "TICKET-0003: Feature name")
- Include summary of what was implemented
- Atomic commits where logical (one ticket = one commit, generally)
- Use clear, descriptive language
- Always include: `Co-Authored-By: Claude Haiku 4.5 <noreply@anthropic.com>`

### Pushing
- **Automatically push to remote after every commit**
- Main stable branch: `main`
- Push must happen before marking ticket `DONE`
- When on `main`: push directly — each completed ticket moves `main` forward
- When in a worktree: push the branch, open a PR, and self-merge immediately — do not wait for the Systems Programmer to merge

### Code Review Protocol
- Code review happens via separate `REVIEW` tickets assigned to Systems Programmer
- Review tickets depend on the implementation ticket being `DONE` and committed
- Code review does NOT block commits—commits happen immediately upon implementation completion
- If code review requests changes, create a new `BUGFIX` or `TASK` ticket; do not revert the original commit

## Phase Sequencing via Sign-Off Tickets

### What Is a Phase?

Every milestone is divided into 2–4 named phases (e.g., "Foundation," "Gameplay," "Integration," "Review & QA"). A phase is:

- **Scope-bounded, not time-bounded.** A phase is complete when its tickets are done, not when a clock expires.
- **Named and purposeful.** Names reflect the work being done, not a number.
- **Informational only in the orchestrator.** The `phase` field in tickets is for planning and status display only. The orchestrator does not check phases — it dispatches any ticket whose `depends_on` are all `DONE`, regardless of phase.
- **Defined at milestone kickoff** by the Studio Head (with Producer drafting assistance). Phase definitions are part of the milestone document and require Studio Head approval before agents begin work.

### Phase Sign-Off Tickets

Phase transitions between sequential phases are encoded in the ticket dependency tree via dedicated **sign-off tickets**:

- One sign-off ticket is created per phase boundary that must gate the next phase
- Its `depends_on` lists all implementation tickets in that phase
- Next-phase entry tickets include the sign-off ticket ID in their own `depends_on`
- Owner: `qa-engineer` for phases requiring test validation; `studio-head` for phases requiring human review/approval

**QA Engineer sign-off responsibilities:**
- Run the full test suite and confirm zero failures
- Confirm all phase tickets are `DONE`
- Post a Phase Gate Summary report to `docs/studio/reports/`
- Mark the sign-off ticket `DONE`

**Studio Head sign-off:** Edit the ticket file directly (set `status: DONE`, add Activity Log entry), then re-run the conductor. No CLI tool required.

### Orchestrator Behavior

The orchestrator has no `GATE_BLOCKED` state. It dispatches any ticket with all `depends_on` satisfied. When no unblocked work remains, the conductor goes `IDLE`. When a sign-off ticket is marked `DONE`, re-invoking the conductor picks up newly unblocked downstream tickets automatically.

### On Milestone Close (QA Sign-Off Complete)

When the QA phase gate passes **and** the Studio Head has completed the UAT sign-off document (all checkboxes `✅ Approved`), the Producer must complete the following before the milestone is considered closed:

1. ✅ Confirm the UAT sign-off document (`docs/studio/reports/YYYY-MM-DD-[milestone]-uat-signoff.md`) has all features marked `✅ Approved` and the final sign-off section is completed by the Studio Head
2. ✅ Mark all remaining tickets `DONE` and archive them to `tickets/_archive/<milestone>/` (e.g., `tickets/_archive/m4/` for M4 tickets — folder name is the lowercase milestone ID)
3. ✅ Update the milestone row in `docs/studio/milestones.md` — set Status to `Complete` and record the QA sign-off date
4. ✅ Update the **Release Goals** table in `docs/studio/prd.md` — set the milestone row to `Complete`, fill in the QA sign-off date, and confirm the description is accurate
5. ✅ Post the final Phase Gate Summary report to `docs/studio/reports/`
6. ✅ Commit and push all doc updates to `main`
7. ✅ Clean up milestone branches — delete all feature branches used during the milestone (e.g., branches matching `orch/*/TICKET-*`, `feature/m<N>/`, or `feature/t<N>/`) from remote. These are safe to delete once all changes are merged to `main`

## Studio Head Touchpoints

The Studio Head is engaged at exactly three points per milestone:

1. **Milestone Kickoff** — approves milestone scope and phase definitions before agents begin work
2. **P0 Blocker Escalation** — Producer pages Studio Head when a P0 ticket cannot be resolved by the assigned agent
3. **Milestone QA Close** — QA sign-off is a hard gate; Studio Head reviews the UAT sign-off document (`docs/studio/reports/YYYY-MM-DD-[milestone]-uat-signoff.md`), marks each feature checkbox, and grants final approval once all features are `✅ Approved`

The Studio Head is **not** paged at phase transitions, individual ticket completions, or code review openings.

## Process Violation Enforcement Rules

These are hard rules enforced by the Producer. They are not suggestions.

**Rule 1 — Dependency Gate:** An agent may not begin work on a ticket if any ticket listed in its `depends_on` field is not `DONE`. If an agent attempts this, the Producer flags it immediately and halts the ticket.

**Rule 2 — Cross-Milestone Bleed:** If work in milestone M(n+1) introduces parse errors, test failures, or breaking changes that affect M(n)'s test suite, the Producer creates a P1 blocker ticket, assigns it to the responsible agent, and the offending milestone's phase gate cannot pass until it is resolved.

## Testing

- The project uses the **Hammer Forge Tests** framework (`game/addons/hammer_forge_tests/`)
- Unit tests live in `game/tests/` — one file per system, extending `TestSuite`
- **QA Engineer** is responsible for writing unit tests and running the full test suite
- The test suite must pass in full before any milestone can close — this is a hard gate on QA sign-off
- Run tests via `res://addons/hammer_forge_tests/test_runner.tscn` in editor, or headless for CI

### UAT Sign-Off Procedure

During the final QA phase of each milestone, the **QA Engineer** produces a UAT sign-off document before requesting Studio Head approval. This document gives the Studio Head a structured, play-testable checklist of everything that changed in the milestone.

**QA Engineer responsibilities:**
- Populate the template at `docs/studio/templates/uat-signoff.md`
- Save the completed file to `docs/studio/reports/YYYY-MM-DD-[milestone]-uat-signoff.md`
- List every significant feature or change from the milestone, grouped logically
- For each item: write a plain-language description of what changed and step-by-step instructions for how to test it in-game
- Commit and push the document, then notify the Producer it is ready for Studio Head review

**Studio Head responsibilities:**
- Follow each feature's test steps in-game
- Mark each checkbox `✅ Approved` or `❌ Rejected` (with notes on rejections)
- Sign the final sign-off section once all features are approved

**Producer responsibilities:**
- Confirm sign-off by reading the UAT document — all checkboxes must be marked `✅ Approved` and the final sign-off section must be completed
- If any item is `❌ Rejected`, do not close the milestone — triage with QA Engineer and open bug tickets as needed

## Communication Style

- **Be concise and to the point**
- Focus on practical information and outcomes
- No verbose explanations unless specifically requested

### Ticket Status Tables

When reporting ticket statuses, always include **at minimum** these columns in this order:

| Ticket | Title | Status | Owner | Dependencies | Milestone |

Add extra columns (e.g., Notes, Blocked By) only when relevant to the discussion. Never omit the required columns.

## Common Tasks

Assist with:
- Bug fixes
- Feature development
- Documentation updates

## Files & Directories

### Do Not Modify
- System configuration files without explicit permission

### Key Locations
- **Coding Standards**: `docs/engineering/coding-standards.md`
- **Game Code**: `/game`
- **AI Agents**: `/agents`
- **Design & Documentation**: `/docs`

## Notes

- This is an active Godot project with ongoing development
- AI orchestration is a core component alongside game development
- Documentation should be kept current with code changes
