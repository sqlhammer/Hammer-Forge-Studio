# Studio Onboarding Guide

**Owner:** technical-writer
**Status:** Draft
**Last Updated:** 2026-02-23

> Start here. This guide is for any new agent or human contributor joining Hammer Forge Studio.

---

## What Is This Project?

Hammer Forge Studio is an AI agent-powered game development studio. The project at `C:\repos\Hammer-Forge-Studio\` is the workspace where a team of 14 specialized Claude Code agents collaborate to build games in Godot 4.

The **Studio Head** (Derik Hammer) sets creative direction and milestones. Agents execute the work.

---

## Project Structure

```
Hammer-Forge-Studio/
├── agents/          # Agent CLAUDE.md files (one per team member)
├── docs/            # Internal wiki (design, engineering, art, audio, QA docs)
├── game/            # The active Godot 4.5 project
├── tickets/         # All work items (the team's task queue)
└── README.md        # Project overview
```

---

## The Ticket System

Work flows through markdown files in `tickets/`. Start here: [`tickets/README.md`](../../tickets/README.md)

Key rules:
- Every piece of work has a ticket
- Tickets have exactly one owner at a time
- When blocked: create a new BLOCKER ticket, don't just change status
- Producer routes all blockers

---

## How Work Is Organized: Milestones and Phases

The project is organized into **Milestones** — goal containers that define what gets built and when. Every milestone is divided into **Phases**.

**Phases** are scope-bounded work containers within a milestone. Examples: "Foundation," "Gameplay," "Integration," "Review & QA." A phase is complete when all its tickets reach `DONE` — not when a clock expires.

**Phase Gates** are checkpoints that fire when all tickets in a phase are done. The Producer manages phase transitions. When a gate passes, the next phase opens automatically. When a gate fails, the Studio Head is paged.

**What this means for you as an agent:**
- You will be assigned tickets that belong to a phase
- Do not begin a ticket until all its `depends_on` entries are `DONE`
- Do not begin work on a ticket in Phase N+1 if the Phase N gate has not passed
- The Producer manages phase transitions — you do not need to track this yourself
- If you are unsure whether you can start a ticket, check with the Producer

Phase definitions and gate status are maintained in `docs/studio/milestones.md`.

---

## The Agent Team

See [`agents/README.md`](../../agents/README.md) for the full roster and links to each agent's CLAUDE.md.

---

## How Agents Operate

Each agent is a Claude Code instance started in the project root. The agent reads its `CLAUDE.md` to understand its role, then scans `tickets/` for open tickets assigned to its slug.

Agents do NOT coordinate in real-time — they work asynchronously through the ticket system.

---

## Key Documents to Read First

1. [`tickets/README.md`](../../tickets/README.md) — Ticket schema and ownership rules
2. [`agents/README.md`](../../agents/README.md) — Team roster
3. [`agents/<your-slug>/CLAUDE.md`](../../agents/) — Your role definition
4. [`docs/engineering/coding-standards.md`](../engineering/coding-standards.md) — Required reading for all engineering agents
5. [`docs/glossary.md`](../glossary.md) — Project terminology

---

## Getting Started as an Agent

1. Read your `CLAUDE.md` fully before taking any action
2. Read `tickets/README.md` to understand the ticket system
3. Scan `tickets/` for open tickets with `owner: <your-slug>`
4. If no tickets are assigned, check with the Producer (create a TASK ticket for yourself to get oriented)
5. Never start work without a corresponding ticket

---

## Getting Started as a Human Contributor

1. Review this doc and the agent roster
2. Create tickets via the format in `tickets/README.md`
3. Assign tickets to the appropriate agent slug
4. Monitor `docs/studio/reports/` for Phase Gate Summaries and milestone status
