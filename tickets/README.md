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
depends_on: []
blocks: []
tags: []
---
```

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
3. **Starting work** — update `status: IN_PROGRESS` and add an Activity Log entry before beginning.
4. **When blocked** — do NOT change the current ticket's status. Instead:
   - Create a new `BLOCKER` ticket with `owner: producer` and `blocks: [this-ticket-id]`
   - Add an Activity Log entry: `YYYY-MM-DD [slug] BLOCKED — see TICKET-NNNN`
5. **Producer** is the default fallback owner for any ticket with no clear owner.
6. **QA sign-off** is required before any milestone is marked complete. QA Engineer must verify and close all `BUG` tickets in scope.

---

## Archiving

When a ticket reaches `status: DONE` or `CANCELLED`:
1. Move the file to `tickets/_archive/TICKET-NNNN.md`
2. Add a final Activity Log entry: `YYYY-MM-DD [slug] Archived`

Only the Producer archives tickets.

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
