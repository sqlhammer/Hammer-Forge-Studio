---
id: TICKET-0196
title: "Architecture and game loop diagrams — curated Mermaid source files"
type: TASK
status: DONE
priority: P2
owner: producer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "T1"
phase: "Dashboard"
depends_on: [TICKET-0192]
blocks: []
tags: [tooling, dashboard, diagrams, mermaid, architecture, game-loop]
---

## Summary

Create hand-curated Mermaid diagram source files that visualize the game's architecture, core loop, and agent orchestration flow. These diagrams are maintained as source files in the repo and rendered on a dedicated "Architecture" page of the dashboard.

## Acceptance Criteria

### Diagram Source Files
- [x] Directory at `dashboard/diagrams/` for hand-curated Mermaid `.mmd` files
- [x] At minimum 3 diagrams created:

### Diagram 1: Game Core Loop
- [x] Visualizes the main gameplay loop: Land → Scan → Mine → Return to Ship → Process → Craft → Upgrade → Travel → (repeat)
- [x] Shows branching paths (e.g., mine surface vs. deep nodes, recycle vs. fabricate)
- [x] Labels key systems at each step (Scanner, Hand Drill, Recycler, Fabricator, Tech Tree, Navigation Console)

### Diagram 2: System Architecture Overview
- [x] Shows the autoload/singleton layer (Global, InputManager, ShipState, Inventory, etc.)
- [x] Shows the scene hierarchy (main scene → ship exterior/interior → modules → player)
- [x] Shows data flow between systems (e.g., Inventory ↔ Recycler, ShipState ↔ FuelSystem)

### Diagram 3: Agent Orchestration Flow
- [x] Shows the producer → conductor → agent dispatch → ticket lifecycle flow
- [x] Includes phase gate checkpoints
- [x] Shows agent roles and their primary responsibilities

### Dashboard Integration
- [x] Dedicated "Architecture" section/page in the dashboard navigation
- [x] All diagrams rendered via Mermaid.js
- [x] Each diagram has a title and brief description
- [x] Build script copies diagram files from `dashboard/diagrams/` to the dist output

## Implementation Notes

- These diagrams are manually maintained — they represent high-level architecture that doesn't change on every commit. Update them when major architectural changes land.
- Use Mermaid `flowchart`, `graph`, or `sequenceDiagram` syntax as appropriate for each diagram type.
- The game core loop diagram should reflect the current state of gameplay systems (through M8).
- Reference existing architecture docs in `docs/` for accuracy — don't invent system connections.

## Handoff Notes

Delivered via PR #244 (commit dcdbfb9). Three hand-curated Mermaid diagram source files created in `dashboard/diagrams/`:
- `game-core-loop.mmd` — flowchart of the full gameplay loop with branching paths (surface vs. deep mining, recycle vs. fabricate) and labeled key systems
- `system-architecture.mmd` — graph showing autoload singletons, scene hierarchy, and data flow between game systems
- `agent-orchestration-flow.mmd` — flowchart of the producer → conductor → worker dispatch pipeline with ticket lifecycle and phase gate checkpoints

Dashboard integration added in `dashboard/src/index.html` (Architecture nav group + section) and `dashboard/src/js/app.js` (`loadArchitectureDiagrams()` function, `ARCHITECTURE_DIAGRAMS` registry, Mermaid initialization). Build script `dashboard/build.py` copies `.mmd` files from `dashboard/diagrams/` to `dashboard/dist/data/architecture/` on each build run.

## Activity Log

- 2026-02-27 [producer] Created ticket — hand-curated architecture and game loop diagrams
- 2026-03-01 [producer] Starting work — creating Mermaid diagram source files and dashboard integration
- 2026-03-01 [producer] Marking DONE — all acceptance criteria satisfied by commit dcdbfb9 (PR #244). Ticket file updated to reflect completed state.
