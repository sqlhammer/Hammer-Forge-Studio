# Hammer Forge Studio

Where our cross-functional video game design, development, and management team is defined and created.

---

## What Is This?

This repository is the workspace for Hammer Forge Studio — a game development studio operated by a team of 14 specialized AI agents working in Godot 4, coordinated through a markdown-based ticket system.

**Studio Head:** Derik Hammer (human — executive direction and final decisions)
**Engine:** Godot 4.5 (`game/`)
**Team:** 14 Claude Code agents (`agents/`)
**Work queue:** Markdown ticket system (`tickets/`)
**Knowledge base:** Internal wiki (`docs/`)

---

## Where to Start

| If you are... | Start here |
|---|---|
| A new agent or contributor | [`docs/studio/onboarding.md`](docs/studio/onboarding.md) |
| Looking for the team roster | [`agents/README.md`](agents/README.md) |
| Managing work / sprint planning | [`tickets/README.md`](tickets/README.md) |
| Looking for design specs | [`docs/design/gdd.md`](docs/design/gdd.md) |
| Looking for engineering standards | [`docs/engineering/coding-standards.md`](docs/engineering/coding-standards.md) |
| Checking milestone status | [`docs/studio/milestones.md`](docs/studio/milestones.md) |

---

## Repository Structure

```
Hammer-Forge-Studio/
├── README.md                  # This file
├── agents/                    # AI agent definitions (one CLAUDE.md per agent)
│   ├── README.md              # Roster index
│   ├── _template/CLAUDE.md    # Base template for all agent files
│   └── <slug>/CLAUDE.md       # 14 agent definitions
├── docs/                      # Internal wiki
│   ├── design/                # GDD, system specs, UI style guide
│   ├── narrative/             # Narrative bible, voice guide, dialogue scripts
│   ├── engineering/           # Coding standards, architecture, tooling, physics layers
│   ├── art/                   # Art tech specs, VFX catalog, animation API docs
│   ├── audio/                 # Audio tech specs, bus architecture, Audio Manager API
│   ├── qa/                    # Test cases, regression checklist, QA reports
│   ├── studio/                # Milestones, status reports, onboarding
│   └── glossary.md            # Project-wide terminology
├── game/                      # Godot 4.5 game project
│   └── addons/gdai-mcp-plugin-godot/   # MCP plugin for AI-assisted development
└── tickets/                   # Work item queue
    ├── README.md              # Ticket schema and ownership rules
    └── _archive/              # Closed tickets
```

---

## The Agent Team

14 Claude Code agents, each with a defined role, MCP tool tier, and CLAUDE.md. See [`agents/README.md`](agents/README.md) for the full roster.

The team covers: Production, Game Design, Narrative, Engineering, DevOps, Art, Audio, VFX, QA, and Technical Writing.

---

## License

Copyright (c) 2026 Derik Hammer — All rights reserved.
