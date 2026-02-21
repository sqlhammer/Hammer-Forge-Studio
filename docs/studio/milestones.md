# Milestone Roadmap

**Owner:** producer
**Status:** Draft
**Last Updated:** —

> Tracks all project milestones, their target dates, and completion status. Studio Head sets milestone goals; Producer maintains this document.

---

## Format

| Field | Description |
|-------|-------------|
| Milestone | Name and short description |
| Target Date | Planned completion |
| Status | Planning / Active / QA / Complete |
| Tickets | Count of total / open / done tickets in scope |
| QA Sign-off | Date QA Engineer signed off (required to close) |

---

## Milestones

| # | Milestone | Target Date | Status | Total | Open | Done | QA Sign-off |
|---|-----------|-------------|--------|-------|------|------|-------------|
| M0 | Studio Setup — Team infrastructure, ticket system, docs | 2026-02-20 | Active | — | — | — | — |
| M1 | Core Game Architecture — Player controller, input system, view modes | 2026-03-14 | Planning | 7 | 7 | 0 | — |

---

## Milestone Notes

### M0 — Studio Setup

**Goal:** Establish all team infrastructure so the studio can begin game development.

**Scope:**
- Agent CLAUDE.md files for all 14 agents
- Ticket system operational
- Docs directory structure in place
- Root README updated

**Dependencies:** None

**Risks:** None identified

---

### M1 — Core Game Architecture

**Goal:** Build testable first-person and third-person player control systems with a unified input architecture.

**Scope:**
- Input system design and architecture specification
- InputManager autoload for keyboard and gamepad input normalization
- First-person player controller (movement, camera control)
- Third-person orbital camera system (ship/base view)
- Integrated player scene with view-switching
- Code review and QA testing

**Tickets:** TICKET-0001 through TICKET-0007

**Dependencies:** M0 (infrastructure must be in place)

**Risks:**
- Input normalization across gamepad types may require iteration
- Camera control smoothness and responsiveness may need tuning post-review
- View-switching transitions require careful state management to avoid input conflicts
