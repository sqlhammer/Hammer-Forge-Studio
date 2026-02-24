---
id: TICKET-0071
title: "Third-person scan/mine gameplay"
type: FEATURE
status: DONE
priority: P1
owner: gameplay-programmer
created_by: producer
created_at: 2026-02-24
updated_at: 2026-02-24
milestone: "M5"
milestone_gate: "M4"
phase: "Gameplay"
depends_on: [TICKET-0065, TICKET-0083]
blocks: [TICKET-0075]
tags: [third-person, scanner, mining, gameplay, camera]
---

## Summary
Enable scanning and mining in third-person camera mode. M3 implemented scan/mine in first-person only. This ticket brings third-person camera (M1) to full parity for the core scan/mine loop — the player can switch to third-person view and perform Phase 1 scan, Phase 2 analysis, and extraction without switching back to first-person. Implements deferred item D-014.

## Acceptance Criteria
- [ ] Phase 1 scanner ping (radial resource type selection + compass markers) functional in third-person view
- [ ] Phase 2 analysis (hold-to-analyze, deposit readout) functional in third-person view
- [ ] Mining extraction (hold-to-extract, battery drain, inventory collection, deposit depletion) functional in third-person view
- [ ] Mining minigame (TICKET-0070) functional in third-person view
- [ ] HUD elements (compass markers, battery bar, mining progress, pickup notifications) correctly positioned and visible in third-person perspective
- [ ] Camera does not conflict with scanner or mining reticle in third-person mode
- [ ] View-switch between first-person and third-person mid-session does not break active scan or mine state
- [ ] All code follows `docs/engineering/coding-standards.md`

## Implementation Notes
- Reference deferred item D-014 in `docs/studio/deferred-items.md`
- Reference TICKET-0065 wireframes for third-person HUD layout
- The underlying scanner and mining systems (M3) are unchanged — this ticket adapts their inputs and HUD presentation to third-person camera
- Third-person camera controller exists from M1; do not modify its core — only add scan/mine input routing and HUD positioning adjustments
- Test all scan/mine interactions in both camera modes before marking DONE

## Handoff Notes
(Leave blank until handoff occurs.)

## Activity Log
- 2026-02-24 [producer] Created ticket
- 2026-02-25 [gameplay-programmer] DONE — commit cb51338, PR #48 merged. Proximity targeting in third-person, camera swap on view switch, crosshair toggle.
