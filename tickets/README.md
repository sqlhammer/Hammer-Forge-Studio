# Ticket System — Hammer Forge Studio

This directory contains all active work tickets for the Hammer Forge Studio project. Closed tickets are moved to `_archive/`.

---

## Ticket File Naming

```
tickets/TICKET-NNNN.md
```

IDs are zero-padded sequential integers starting at `0001`. Never reuse an ID. The Producer agent is responsible for assigning new IDs.

---

## Ticket Schema

Every ticket is a markdown file with YAML frontmatter followed by required body sections.

### Frontmatter

```yaml
---
id: TICKET-0001
title: "Short imperative description of the work"
type: FEATURE | BUG | TASK | DESIGN | SPIKE | BLOCKER | REVIEW
status: OPEN | IN_PROGRESS | BLOCKED | IN_REVIEW | DONE | CANCELLED
priority: P0 | P1 | P2 | P3
owner: <agent-slug>
created_by: <agent-slug> | studio-head
created_at: YYYY-MM-DD
updated_at: YYYY-MM-DD
milestone: ""
milestone_gate: ""
depends_on: []
blocks: []
tags: []
---
```

### `milestone_gate` Semantics

**If `milestone_gate` is set, the named milestone must have `status: Complete` in `docs/studio/milestones.md` before any agent may set this ticket to `IN_PROGRESS`.**

This is a hard gate — individual ticket dependencies do not override it. An agent must not begin work on a gated ticket, even if all `depends_on` entries are `DONE`, until the milestone gate is cleared.

If a milestone gate is blocking you, do not create a BLOCKER ticket — the gate is by design. Wait for the milestone to close.

---

### `depends_on` Semantics

**Every ticket listed in `depends_on` must have `status: DONE` before you may set your ticket to `IN_PROGRESS`.**

- `IN_REVIEW` is NOT done — the work is awaiting approval or decision. Do not start.
- `IN_PROGRESS` is NOT done — the upstream work is still being executed. Do not start.
- `OPEN` is NOT done — the upstream work has not been started. Do not start.
- Only `DONE` clears a dependency.

If a ticket you depend on is `IN_REVIEW` and you are ready to begin, do not proceed. Create a `BLOCKER` ticket with `owner: producer` explaining what approval or sign-off is needed to clear the dependency.

### Body Sections (required in this order)

```markdown
## Summary
One paragraph describing the work to be done and why.

## Acceptance Criteria
- [ ] Criterion one
- [ ] Criterion two
- [ ] Criterion three

## Implementation Notes
Relevant context, links to design docs, prior decisions, file paths, constraints.

## Handoff Notes
What the next owner needs to know when this ticket is transferred to them.
(Leave blank until a handoff occurs.)

## Activity Log
- YYYY-MM-DD [agent-slug] Created ticket
- YYYY-MM-DD [agent-slug] Status changed to IN_PROGRESS
- YYYY-MM-DD [agent-slug] BLOCKED — see TICKET-NNNN
```

---

## Ticket Types

| Type | When to Use |
|------|-------------|
| `FEATURE` | A new capability being added to the game (user-visible) |
| `BUG` | A defect in existing functionality that needs fixing |
| `TASK` | Concrete implementation work with well-defined scope |
| `DESIGN` | A design document, system spec, or architectural decision record that must be authored before implementation begins |
| `SPIKE` | Time-boxed research or exploration to answer a specific question; produces a finding doc, not shipped code |
| `BLOCKER` | Created when an agent cannot proceed; owned by Producer; references the blocked ticket in `blocks:` |
| `REVIEW` | A completed artifact (code, asset, doc) that requires review or approval before the work is considered done |

---

## Status Definitions

| Status | Meaning |
|--------|---------|
| `OPEN` | Ready to be picked up by the owner |
| `IN_PROGRESS` | Owner is actively working on it right now |
| `BLOCKED` | Owner cannot proceed; a corresponding BLOCKER ticket exists |
| `IN_REVIEW` | Work complete; awaiting review or QA verification |
| `DONE` | All acceptance criteria met and verified |
| `CANCELLED` | No longer needed; reason documented in Activity Log |

---

## Priority Definitions

| Priority | Meaning |
|----------|---------|
| `P0` | Critical — blocks release or causes data loss/crashes; escalate to Studio Head immediately |
| `P1` | High — blocks meaningful gameplay; must be resolved in current sprint |
| `P2` | Normal — defect or feature that should be addressed this milestone |
| `P3` | Low — polish, nice-to-have; addressed when higher priority work is clear |

---

## Ownership Rules

1. **Exactly one `owner`** at all times. If an agent is unsure who owns a ticket, assign it to `producer`.
2. **Changing owners** requires updating the `owner` field AND adding an Activity Log entry explaining the transfer.
3. **Starting work** — before setting `status: IN_PROGRESS`, read every ticket listed in `depends_on` and confirm each one has `status: DONE`. If any dependency is not `DONE`, do not begin. Create a `BLOCKER` ticket with `owner: producer` describing what must be resolved first.
4. **When blocked** — do NOT change the current ticket's status. Instead:
   - Create a new `BLOCKER` ticket with `owner: producer` and `blocks: [this-ticket-id]`
   - Add an Activity Log entry: `YYYY-MM-DD [slug] BLOCKED — see TICKET-NNNN`
5. **Producer** is the default fallback owner for any ticket with no clear owner.
6. **QA sign-off** is required before any milestone is marked complete. QA Engineer must verify and close all `BUG` tickets in scope.

---

## Archiving

### Producer Responsibility: Regular Archival Sweeps

The **Producer** is responsible for archiving completed tickets. This is an explicit workflow step:

1. **Schedule:** Perform archival sweeps at the end of each sprint or daily during active development
2. **Trigger:** When a ticket reaches `status: DONE` or `CANCELLED`, it becomes eligible for archival
3. **Process:**
   - Review all tickets in `tickets/` with `status: DONE` or `CANCELLED`
   - For each eligible ticket:
     - Move the file to `tickets/_archive/TICKET-NNNN.md`
     - Add a final Activity Log entry: `YYYY-MM-DD [producer] Archived`
   - Commit the archival batch as a single commit: `"Archive: Move completed tickets to _archive (TICKET-NNNN, TICKET-NNNN, ...)"`

### Archival Checklist

Before archiving a ticket, verify:
- ✅ `status: DONE` or `CANCELLED` (no other statuses should be archived)
- ✅ Code committed to `main` (if applicable — DONE tickets with repo changes must be committed)
- ✅ All acceptance criteria met (checked in ticket)
- ✅ No blocked dependencies (if tickets depend on it, do not archive yet)

---

## Agent Slugs Reference

| Slug | Role |
|------|------|
| `producer` | Producer |
| `game-designer` | Game Designer |
| `narrative-designer` | Narrative Designer |
| `systems-programmer` | Systems Programmer |
| `gameplay-programmer` | Gameplay Programmer |
| `tools-devops-engineer` | Tools & DevOps Engineer |
| `technical-artist` | Technical Artist |
| `environment-artist` | Environment Artist |
| `character-animator` | Character Animator |
| `ui-ux-designer` | UI/UX Designer |
| `audio-engineer` | Audio Engineer |
| `vfx-artist` | VFX Artist |
| `qa-engineer` | QA Engineer |
| `technical-writer` | Technical Writer |
| `studio-head` | Human — Derik Hammer |
