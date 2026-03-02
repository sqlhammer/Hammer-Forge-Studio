---
id: TICKET-0196
title: "Architecture and game loop diagrams — curated Mermaid source files"
type: TASK
status: IN_PROGRESS
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
- [ ] Directory at `dashboard/diagrams/` for hand-curated Mermaid `.mmd` files
- [ ] At minimum 3 diagrams created:

### Diagram 1: Game Core Loop
- [ ] Visualizes the main gameplay loop: Land → Scan → Mine → Return to Ship → Process → Craft → Upgrade → Travel → (repeat)
- [ ] Shows branching paths (e.g., mine surface vs. deep nodes, recycle vs. fabricate)
- [ ] Labels key systems at each step (Scanner, Hand Drill, Recycler, Fabricator, Tech Tree, Navigation Console)

### Diagram 2: System Architecture Overview
- [ ] Shows the autoload/singleton layer (Global, InputManager, ShipState, Inventory, etc.)
- [ ] Shows the scene hierarchy (main scene → ship exterior/interior → modules → player)
- [ ] Shows data flow between systems (e.g., Inventory ↔ Recycler, ShipState ↔ FuelSystem)

### Diagram 3: Agent Orchestration Flow
- [ ] Shows the producer → conductor → agent dispatch → ticket lifecycle flow
- [ ] Includes phase gate checkpoints
- [ ] Shows agent roles and their primary responsibilities

### Dashboard Integration
- [ ] Dedicated "Architecture" section/page in the dashboard navigation
- [ ] All diagrams rendered via Mermaid.js
- [ ] Each diagram has a title and brief description
- [ ] Build script copies diagram files from `dashboard/diagrams/` to the dist output

## Implementation Notes

- These diagrams are manually maintained — they represent high-level architecture that doesn't change on every commit. Update them when major architectural changes land.
- Use Mermaid `flowchart`, `graph`, or `sequenceDiagram` syntax as appropriate for each diagram type.
- The game core loop diagram should reflect the current state of gameplay systems (through M8).
- Reference existing architecture docs in `docs/` for accuracy — don't invent system connections.

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created ticket — hand-curated architecture and game loop diagrams
- 2026-03-01 [producer] Starting work — creating Mermaid diagram source files and dashboard integration
