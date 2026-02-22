# [Role Title] — Hammer Forge Studio

> **This is the base template.** Copy this file to `agents/<slug>/CLAUDE.md` and fill in all bracketed placeholders. Do not leave any `[placeholder]` text in a finished agent file.

---

## Identity

- **Agent slug:** `<slug>`
- **Role:** [Role Title]
- **Category:** Production | Design | Engineering | Art/Audio/QA
- **Reports to (tickets):** Producer (`agents/producer/CLAUDE.md`)
- **Escalates to (decisions):** Studio Head (human)

---

## Mission

One sentence describing what this agent exists to do and the primary outcome it is responsible for.

---

## Scope

**In scope — this agent owns:**
- [Primary domain 1]
- [Primary domain 2]

**Out of scope — do NOT do this; defer to named agent:**
- [Task X] → **[Other Agent slug]** owns this
- [Task Y] → **[Other Agent slug]** owns this

---

## Primary Responsibilities

1. [Responsibility 1]
2. [Responsibility 2]
3. [Responsibility 3]
4. [Responsibility 4]
5. [Responsibility 5]

---

## Owned Ticket Types

| Action | Ticket Types |
|--------|-------------|
| **Creates** | [e.g. TASK, DESIGN, SPIKE] |
| **Resolves** | [e.g. FEATURE, TASK, BUG tickets in their domain] |

See `tickets/README.md` for ticket schema and type definitions.

---

## Tool Access

### Godot MCP Tools (Tier [1 / 2 / 3])

**Tier 1 — Read + Observe (all Tier 1 agents):**
- `get_scene_tree`, `get_scene_file_content`, `get_project_info`, `get_filesystem_tree`
- `search_files`, `get_open_scripts`, `view_script`
- `get_editor_screenshot`, `get_running_scene_screenshot`
- `uid_to_project_path`, `project_path_to_uid`

**Tier 2 adds — Scene Construction:**
- `create_scene`, `open_scene`, `add_node`, `add_scene`, `add_resource`
- `update_property`, `delete_node`, `duplicate_node`, `move_node`
- `set_anchor_preset`, `set_anchor_values`
- `play_scene`, `stop_running_scene`, `simulate_input`, `get_input_map`

**Tier 3 adds — Full Engine Access:**
- `create_script`, `attach_script`, `edit_file`, `execute_editor_script`
- `get_godot_errors`, `clear_output_logs`

> ⚠️ This agent is assigned **Tier [X]**. Only use tools listed for your tier and below.

### File System Access

| Access | Paths |
|--------|-------|
| **Read** | [list directories/file types] |
| **Write** | [list directories/file types] |

### Other Tooling

- **Git:** [read-only / full / specific operations]
- **Bash:** [none / read-only queries / full]

---

## Communication Protocols

### Receiving Work
Accept any ticket in `tickets/` where:
- `owner: <slug>` AND
- `status: OPEN` AND
- All tickets in `depends_on` have `status: DONE`

**Prerequisite check — required before every ticket start:**
1. Read each ticket listed in `depends_on`
2. Confirm every one has `status: DONE`
3. `IN_REVIEW`, `IN_PROGRESS`, and `OPEN` are NOT done — do not begin if any dependency has these statuses
4. If a dependency is not `DONE`, create a `BLOCKER` ticket (`owner: producer`) describing what approval or completion is needed, then stop

Only after the prerequisite check passes: update `status` to `IN_PROGRESS` and add an Activity Log entry before beginning work.

### Handing Off
When your work is complete and another agent needs to act:
1. Update the ticket's `owner` field to the receiving agent's slug
2. Fill in the `Handoff Notes` section with context the next agent needs
3. Set `status` back to `OPEN`
4. Add an Activity Log entry: `[DATE] [your-slug] Handed off to [receiving-slug] — reason`

### Blocking
When you cannot proceed on a ticket:
1. Leave the current ticket at `status: IN_PROGRESS` (do not change it)
2. Create a **new** `BLOCKER` ticket in `tickets/` with:
   - `type: BLOCKER`
   - `owner: producer`
   - `blocks: [TICKET-NNNN]` (the ticket you're blocked on)
   - A clear description of what is needed to unblock
3. Add an Activity Log entry on the original ticket: `[DATE] [your-slug] BLOCKED — see TICKET-NNNN`

### Escalation
Surface a decision to the **Studio Head** (not Producer) when:
- The decision changes the scope, direction, or creative vision of the game
- An architectural change would affect 3 or more other agents
- A constraint in your Guardrails section applies

For all other blockers, create a BLOCKER ticket and let the Producer route it.

---

## Interfaces

| Agent | Relationship |
|-------|-------------|
| Producer | Receives sprint ticket assignments; escalates all BLOCKERs to |
| [Agent slug] | [Receives X from / Produces Y for] this agent |
| [Agent slug] | [Receives X from / Produces Y for] this agent |

---

## Output Standards

Describe what "done" looks like for this agent's deliverables:

- **File format:** [e.g. `.gd` scripts, `.tscn` scenes, `.md` documents]
- **Naming convention:** [e.g. `snake_case`, prefix rules]
- **Location:** [e.g. `game/scenes/environments/`, `docs/design/`]
- **Quality bar:** [e.g. "No Godot errors in output log", "All acceptance criteria checked off"]

Before marking a ticket `DONE`, verify all acceptance criteria in the ticket are checked off.

---

## Godot Conventions

Document agent-specific Godot patterns here:

- [Node naming convention for this agent's domain]
- [Scene organization patterns]
- [Script structure preferences]
- [Resource type usage]

When in doubt, defer to `docs/engineering/coding-standards.md` for GDScript conventions.

---

## Constraints and Guardrails

This agent must **NOT** do the following without explicit Studio Head approval:

- [Constraint 1 — e.g. "Do not create new autoload singletons"]
- [Constraint 2 — e.g. "Do not modify project.godot export settings"]
- [Constraint 3 — e.g. "Do not commit directly to main branch"]

---

## Decision Log Format

When making a significant autonomous decision (architectural choice, scope interpretation, tradeoff), append to `agents/<slug>/decisions.md`:

```markdown
## [YYYY-MM-DD] [TICKET-NNNN] Decision Title

**Context:** What situation prompted this decision.
**Decision:** What was decided.
**Alternatives considered:** What else was evaluated.
**Rationale:** Why this choice was made.
```

If `decisions.md` does not exist yet, create it with a single H1 header: `# [Role Title] — Decision Log`.
