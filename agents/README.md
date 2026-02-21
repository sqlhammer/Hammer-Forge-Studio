# Agent Roster — Hammer Forge Studio

This directory defines the complete AI agent team for Hammer Forge Studio. Each agent is a Claude Code instance operating from its own `CLAUDE.md` file. The **Studio Head** (Derik Hammer) is the human executive — no AI agent holds that role.

For the ticket system that connects all agents, see [`tickets/README.md`](../tickets/README.md).

---

## How Agents Work

- Each agent is activated by opening Claude Code in the project root with the relevant `agents/<slug>/CLAUDE.md` as the active context
- Agents pick up work by reading `tickets/` for open tickets assigned to their slug
- Agents communicate asynchronously via tickets — they do not call each other directly
- The **Producer** is the routing hub: all blockers go to the Producer; all sprint assignments come from the Producer
- The **Studio Head** sets milestones, creative direction, and resolves escalated decisions

---

## Team Roster

### Production

| Agent | Slug | CLAUDE.md |
|-------|------|-----------|
| Producer | `producer` | [agents/producer/CLAUDE.md](producer/CLAUDE.md) |

### Game Design + Narrative

| Agent | Slug | CLAUDE.md |
|-------|------|-----------|
| Game Designer | `game-designer` | [agents/game-designer/CLAUDE.md](game-designer/CLAUDE.md) |
| Narrative Designer | `narrative-designer` | [agents/narrative-designer/CLAUDE.md](narrative-designer/CLAUDE.md) |

### Engineering + DevOps

| Agent | Slug | CLAUDE.md |
|-------|------|-----------|
| Systems Programmer | `systems-programmer` | [agents/systems-programmer/CLAUDE.md](systems-programmer/CLAUDE.md) |
| Gameplay Programmer | `gameplay-programmer` | [agents/gameplay-programmer/CLAUDE.md](gameplay-programmer/CLAUDE.md) |
| Tools & DevOps Engineer | `tools-devops-engineer` | [agents/tools-devops-engineer/CLAUDE.md](tools-devops-engineer/CLAUDE.md) |

### Art, Audio + QA

| Agent | Slug | CLAUDE.md |
|-------|------|-----------|
| Technical Artist | `technical-artist` | [agents/technical-artist/CLAUDE.md](technical-artist/CLAUDE.md) |
| Environment Artist | `environment-artist` | [agents/environment-artist/CLAUDE.md](environment-artist/CLAUDE.md) |
| Character Animator | `character-animator` | [agents/character-animator/CLAUDE.md](character-animator/CLAUDE.md) |
| UI/UX Designer | `ui-ux-designer` | [agents/ui-ux-designer/CLAUDE.md](ui-ux-designer/CLAUDE.md) |
| Audio Engineer | `audio-engineer` | [agents/audio-engineer/CLAUDE.md](audio-engineer/CLAUDE.md) |
| VFX Artist | `vfx-artist` | [agents/vfx-artist/CLAUDE.md](vfx-artist/CLAUDE.md) |
| QA Engineer | `qa-engineer` | [agents/qa-engineer/CLAUDE.md](qa-engineer/CLAUDE.md) |
| Technical Writer | `technical-writer` | [agents/technical-writer/CLAUDE.md](technical-writer/CLAUDE.md) |

---

## Godot MCP Permission Tiers

Agents are assigned a tier that defines which Godot MCP tools they may use. These are enforced by each agent's Guardrails section.

| Tier | Tools Included | Agents |
|------|---------------|--------|
| **Tier 1** — Read + Observe | `get_*`, `search_files`, `view_script`, `get_editor_screenshot`, `get_running_scene_screenshot` | Producer (none), Game Designer, Narrative Designer, Technical Writer |
| **Tier 2** — + Scene Construction | All Tier 1 + `create_scene`, `add_node`, `add_resource`, `update_property`, `delete_node`, `duplicate_node`, `move_node`, `play_scene`, `stop_running_scene`, `simulate_input`, `set_anchor_preset`, `set_anchor_values` | Environment Artist, Character Animator, UI/UX Designer, Audio Engineer, VFX Artist, QA Engineer |
| **Tier 3** — + Full Engine Access | All Tier 2 + `create_script`, `attach_script`, `edit_file`, `execute_editor_script`, `get_godot_errors`, `clear_output_logs` | Systems Programmer, Gameplay Programmer, Tools & DevOps Engineer, Technical Artist |

---

## Agent Template

All agent CLAUDE.md files follow the structure defined in [`agents/_template/CLAUDE.md`](_template/CLAUDE.md). When onboarding a new agent or role, copy the template and fill in all bracketed placeholders.

---

## Studio Layer (Future)

This roster defines the **Project Layer** — agents scoped to the current active game. As the studio ships multiple titles, shared standards, pipelines, and knowledge will be extracted into a **Studio Layer** living under `studio/`. The Project Layer agents will remain game-specific.
