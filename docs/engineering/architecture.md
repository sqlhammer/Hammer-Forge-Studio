# System Architecture

**Owner:** systems-programmer
**Status:** Draft
**Last Updated:** —

> Living document of all core engine systems. Updated whenever a new autoload or core system is added. Every public API must be documented here.

---

## Autoload Registry

| Autoload Name | Script Path | Purpose |
|---------------|-------------|---------|
| _[None yet]_ | | |

---

## Core Systems

_[Document each system as it is implemented: purpose, public API, signals emitted, dependencies]_

---

## Architecture Principles

- All cross-system communication goes through signals on the `EventBus` autoload
- Data containers use `Resource` subclasses — not raw `Dictionary`
- State machines use the shared `StateMachine` class from `game/scripts/core/state_machine.gd`
- No system calls methods on another system's autoload directly — use signals

---

## Physics Layer Assignments

See `docs/engineering/physics-layers.md`.
