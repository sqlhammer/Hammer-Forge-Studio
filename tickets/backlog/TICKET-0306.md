---
id: TICKET-0306
title: "Orchestrator — add approve_gate.py helper script to replace manual gate_response.json writing"
type: TASK
status: DONE
priority: P2
owner: systems-programmer
created_by: producer
created_at: 2026-03-03
updated_at: 2026-03-03
closed_at: 2026-03-03
milestone: ""
phase: ""
depends_on: []
blocks: []
tags: [orchestrator, tooling, producer-ux]
---

## Summary

The README currently requires the operator to manually construct and write a `gate_response.json` file to approve a phase gate. This is error-prone (typos in `next_phase`, wrong instance directory) and requires the operator to open `pending_gate.json` themselves to read the expected next phase value. Add a `approve_gate.py` script to the orchestrator directory that wraps this flow end-to-end.

---

## Acceptance Criteria

- [x] Script lives at `orchestrator/approve_gate.py`
- [x] Auto-detects the active instance (single running instance) or accepts `--instance <name>` to target a specific one
- [x] Reads `pending_gate.json` from the instance directory and displays:
  - Current milestone and phase
  - The `next_phase` value that will be written
  - The timestamp the gate was requested
- [x] Prompts the operator for confirmation before writing (default behavior)
- [x] Accepts `--force` flag to skip the confirmation prompt (for scripted/conductor use)
- [x] Writes `gate_response.json` with `{"next_phase": "<value>"}` using the value from `pending_gate.json`
- [x] Exits with a non-zero code and clear error message if:
  - No instance directory exists
  - `pending_gate.json` does not exist (instance is not `GATE_BLOCKED`)
  - Multiple instances exist and `--instance` was not provided
- [x] Update `orchestrator/README.md` — replace the manual `echo` example under "Approve a Phase Gate" with the new script usage

## Usage (target UX)

```bash
python orchestrator/approve_gate.py                  # auto-detect instance, confirm first
python orchestrator/approve_gate.py --force          # no prompt
python orchestrator/approve_gate.py --instance M11  # target a specific instance
```

---

## Implementation Notes

- Follow the same CLI pattern as `orchestrator/resume_planning.py` (`--instance`, `--force`, confirmation prompt)
- Read `next_phase` directly from `pending_gate.json` — do not ask the operator to supply it
- The conductor polls for `gate_response.json` every 30 seconds; the script only needs to write the file and exit cleanly
- No new dependencies — use stdlib only (`json`, `argparse`, `pathlib`, `sys`)

---

## Handoff Notes

(Leave blank until handoff occurs.)

---

## Activity Log

- 2026-03-03 [producer] Created ticket — manual gate_response.json flow in README is error-prone; script should mirror resume_planning.py UX
- 2026-03-03 [systems-programmer] DONE — implemented orchestrator/approve_gate.py; updated README.md "Approve a Phase Gate" section. Commit f833918.
