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
3. Agent pushes to remote
4. Agent marks ticket `DONE` in Activity Log with commit hash
5. Code review happens via separate `REVIEW` ticket (does NOT gate commits)

#### Working in a worktree (separate branch)
1. Agent completes ticket implementation on the worktree branch
2. Agent commits to the worktree branch (references ticket ID in message)
3. Agent pushes the branch to remote
4. Agent creates a PR from the worktree branch targeting `main`
5. Agent self-merges the PR immediately
6. Agent marks ticket `DONE` in Activity Log with commit hash and PR link
7. Code review happens post-merge via a separate `REVIEW` ticket (does NOT gate the merge)

This ensures `main` is always in a working, committed state and tickets are closed without waiting on a separate agent.

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
