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

## Phase Gate Protocol

### What Is a Phase?

Every milestone is divided into 2–4 named phases (e.g., "Foundation," "Gameplay," "Integration," "Review & QA"). A phase is:

- **Scope-bounded, not time-bounded.** A phase is complete when its tickets are done, not when a clock expires.
- **Named and purposeful.** Names reflect the work being done, not a number.
- **Defined at milestone kickoff** by the Studio Head (with Producer drafting assistance). Phase definitions are part of the milestone document and require Studio Head approval before agents begin work.
- **Sequential by default.** Agents do not begin Phase N+1 until the Phase N gate passes. Exception: the Studio Head may explicitly mark phases as parallel-eligible in the milestone definition.

### When Does a Gate Fire?

A Phase Gate fires automatically when all tickets in a phase reach `DONE`. The Producer agent is responsible for enforcing it.

### Gate Pass Conditions

A gate **passes** only when ALL of the following are true:

- ✅ Every ticket in the phase has status `DONE`
- ✅ The full test suite passes with zero failures
- ✅ No cross-milestone parse errors or test-runner blockers exist
- ✅ The dependency graph is clean — no ticket was started while a `depends_on` was non-DONE

### On Gate PASS

Producer posts a Phase Gate Summary (see `docs/studio/templates/phase-gate-summary.md`) and opens the next phase automatically. The Studio Head is **not** paged on a gate pass.

### On Gate FAIL

Producer pages the Studio Head immediately with the specific failure condition. No work on the next phase begins until the Studio Head resolves or explicitly overrides the failure.

## Studio Head Touchpoints

The Studio Head is engaged at exactly three points per milestone:

1. **Milestone Kickoff** — approves milestone scope and phase definitions before agents begin work
2. **Phase Gate Failure** — paged for triage; must resolve or override before the next phase opens
3. **Milestone QA Close** — QA sign-off is a hard gate; Studio Head grants final approval

The Studio Head is **not** paged at phase gate passes, individual ticket completions, or code review openings.

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
