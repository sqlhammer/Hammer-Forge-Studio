---
id: TICKET-0258
title: "Code Quality: Fix section header mislabeling in M8 data classes"
type: TASK
status: OPEN
priority: P3
owner: systems-programmer
created_by: producer
created_at: 2026-03-01
updated_at: 2026-03-01
milestone: "M9"
phase: "Code Quality"
depends_on: [TICKET-0235]
blocks: []
tags: [code-quality, m8-cleanup, data-classes, biome, coding-standards]
---

## Summary

Four M8 data classes — `TerrainFeatureRequest`, `TerrainGenerationResult`, `TerrainChunk`, and `BiomeArchetypeConfig` — have public member variables (no `_` prefix, accessed externally) grouped under `# ── Private Variables ──` section headers. Per coding standards (`docs/engineering/coding-standards.md`), public members must appear under `# ── Public Variables ──`. This is a cosmetic discrepancy with no functional impact, but it violates the project's naming and layout conventions.

## Acceptance Criteria

- [ ] In each of the four classes, the `# ── Private Variables ──` section header for public members is corrected to `# ── Public Variables ──`
- [ ] No actual member variable names, types, or default values are changed — only section headers
- [ ] All four files compile with zero parse errors
- [ ] Full test suite passes with no new failures

## Implementation Notes

- Files are likely in `game/scripts/systems/` or `game/scripts/data/` — locate via `grep -r "TerrainFeatureRequest" game/`
- Only rename section headers; do not reorder variables or restructure the classes
- This is a one-pass find-and-fix; no logic changes

## Activity Log

- 2026-03-01 [producer] Created — deferred item D-026 from M8 code review (TICKET-0177); scheduled for M9 Code Quality phase
