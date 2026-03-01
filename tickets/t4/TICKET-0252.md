---
id: TICKET-0252
title: "Update start_milestone.py for instance directories"
type: FEATURE
status: OPEN
priority: P1
owner: systems-programmer
created_by: producer
created_at: 2026-03-01
updated_at: 2026-03-01
milestone: "T4"
phase: "Foundation"
depends_on: ["TICKET-0249"]
blocks: ["TICKET-0256"]
tags: [orchestrator, start-milestone, instance-paths, t4-foundation]
---

## Summary

Update `orchestrator/start_milestone.py` to write fresh state into the instance directory
rather than the flat `orchestrator/state.json`. Add `--instance <name>` so the user can
specify a custom instance name (defaults to the milestone ID).

---

## Acceptance Criteria

- [ ] `--instance <name>` argument added (defaults to milestone positional arg value)
- [ ] Calls `resolve_instance(instance_name)` → `paths`; writes fresh `state.json` to `paths.state_path`
- [ ] Printed launch command at end of script updated to include `--instance <name>`
  so the user can copy-paste the correct `conductor.py` invocation
- [ ] Old hardcoded flat path (`orchestrator/state.json`) fully removed
- [ ] `resolve_instance()` creates `instance_dir`, `results/`, and `logs/` automatically —
  no manual `mkdir` needed in this script
- [ ] Script still validates that the specified milestone directory exists under `tickets/`
  before writing state

---

## Implementation Notes

- Import `resolve_instance`, `load_config` from `instance_paths`
- The printed launch command should look like:
  `python orchestrator/conductor.py M8 --instance M8`

---

## Handoff Notes

(Leave blank until handoff occurs.)

---

## Activity Log

- 2026-03-01 [producer] Created — T4 Foundation phase
