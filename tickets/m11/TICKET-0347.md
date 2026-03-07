---
id: TICKET-0347
title: "BLOCKER — TICKET-0320 visual verification requires Godot MCP tools"
type: BLOCKER
status: OPEN
priority: P1
owner: producer
created_by: play-tester
created_at: 2026-03-07
updated_at: 2026-03-07
milestone: "M11"
phase: "QA"
depends_on: []
blocks: [TICKET-0320]
tags: [blocker, play-tester, godot-mcp]
---

## Summary

TICKET-0320 is blocked on visual and interactive verification that requires Godot MCP tools
(`play_scene`, `simulate_input`, `get_running_scene_screenshot`, `get_godot_errors`).
These tools are not available in the current Claude Code session.

The play-tester has completed:
- Static structural analysis of all three refactored panel scripts and scenes — PASS
- Headless unit test run: 1009/1009 passed, 0 failed

The following acceptance criteria remain unverified:
- Visual verification: Recycler panel opens with grid and controls visible (screenshot required)
- Visual verification: Fabricator panel opens with populated recipe list (screenshot required)
- Visual verification: Automation Hub panel opens without errors (screenshot required)
- State dump: No ERROR lines in console during panel open/close for any panel
- No runtime errors during any verification scenario

## Resolution

Re-dispatch TICKET-0320 through the orchestrator so the play-tester agent runs with
Godot MCP tools configured (Tier 3). The orchestrator config at
`orchestrator/config.json` registers play-tester with Tier 3 access — those tools
must be active in the agent session for visual verification to proceed.

---

## Activity Log

- 2026-03-07 [play-tester] Created — visual/interactive verification of TICKET-0320 requires Godot MCP tools not available in this session
