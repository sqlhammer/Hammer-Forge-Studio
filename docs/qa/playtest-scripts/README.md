# Playtest Scripts

Declarative playthrough scripts for core gameplay loops. Each YAML file describes a step-by-step test flow that is:

- **Human-readable** for the Studio Head to follow manually during UAT
- **Machine-executable** when the playtest-agent has access to Godot MCP tools (post-T3)

## Script Format

Each script contains:

- `name` — descriptive title
- `scene` — Godot scene to launch
- `preconditions` — state that must be true before starting
- `steps` — ordered actions with inputs, expected outcomes, and optional assertions
- `on_failure` — auto-bug-filing configuration (severity, owner, tags)

## Available Scripts

| Script | Core Loop | Coverage |
|--------|-----------|----------|
| `mine-resource.yaml` | Mine | Deposit interaction, mining progress, inventory update |
| `navigate-to-biome.yaml` | Travel | Navigation console, fuel consumption, biome swap, input restore |
| `craft-fuel-cells.yaml` | Craft | Fabricator interaction, recipe selection, inventory update |

## Bug Ticket Template (Auto-Filed)

When the playtest-agent detects a failure, it auto-files a BUG ticket:

```markdown
---
id: TICKET-NNNN
title: "[PLAYTEST] {failure_message}"
type: BUG
status: OPEN
priority: {on_failure.severity}
owner: {on_failure.owner}
created_by: playtest-agent
milestone: {current_milestone}
tags: {on_failure.tags}
---

## Summary
Automated playthrough "{script_name}" failed at step {step_index}.

## Reproduction Steps
{steps 1..step_index rendered as numbered list}

## Expected Behavior
{step.expected}

## Actual Behavior
{actual_value_or_error}

## Evidence
- Screenshot: {screenshot_path}
- Godot errors: {error_log}
- Playthrough script: {script_file_path}

## Activity Log
- {timestamp} -- playtest-agent -- Filed automatically from playthrough failure
```

## Execution

### Manual (Pre-T3)
Studio Head follows the steps in each YAML file during UAT sign-off.

### Automated (Post-T3)
The `playtest-agent` uses Godot MCP tools (`play_scene`, `simulate_input`, `get_scene_tree`, `execute_editor_script`) to execute each step and assert outcomes.
