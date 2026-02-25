# Icon Experiments Archive

This directory stores all icon generation experiment outputs from M6.

## Structure

Each experiment method gets its own subfolder, created by the technical-artist during the corresponding experiment ticket (TICKET-0092–0094):

```
icon-experiments/
├── method-a/
│   ├── item-icons/
│   ├── hud-icons/
│   └── iteration-log.md
├── method-b/
│   ├── item-icons/
│   ├── hud-icons/
│   └── iteration-log.md
└── method-c/
    ├── item-icons/
    ├── hud-icons/
    └── iteration-log.md
```

## Contents

- **`item-icons/`** — Generated item icons for inventory, tech tree, and machine panels (48×48px target)
- **`hud-icons/`** — Generated HUD/functional icons for HUD elements, notifications, and status indicators (16–32px target)
- **`iteration-log.md`** — Per-method log of prompts used, settings, iteration attempts, and notes for reproducibility

## Lifecycle

After TICKET-0095 evaluation and Studio Head method selection (TICKET-0096):
- The **winning method's** output is promoted to `game/assets/icons/` by the technical-artist (TICKET-0097)
- **Non-winning method** outputs remain here as a permanent reference archive
- Nothing in this directory is referenced by shipped game code
