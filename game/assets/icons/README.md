# Game Icons

This directory contains all icon assets used in the shipped game.

## Structure

```
icons/
├── <approved icons>   — permanent, production-ready icons that ship with the game
└── temp/              — integration-test assets under review; not referenced by released code
```

## Lifecycle

- **Root (`icons/`):** Icons placed here are approved and permanent. They are referenced directly by UI scenes and scripts.
- **`temp/`:** During TICKET-0099/0100 integration, icons land here first for visual testing. After QA sign-off, passing icons are promoted to the root; failing icons are deleted. Nothing in `temp/` should be referenced by code that ships to players.

## Icon Categories

| Category | Size | Usage |
|----------|------|-------|
| Item Icons | 48×48px | Inventory slots, tech tree nodes, machine panels |
| HUD/Functional Icons | 16–32px | HUD elements, ship global status, notifications, tech tree locks |

## Source

Approved icons are produced from the winning experiment method selected in TICKET-0096. Originals and alternatives live in `docs/art/icon-experiments/`.
