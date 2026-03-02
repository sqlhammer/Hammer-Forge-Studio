---
id: TICKET-0197
title: "Code review — T1 systems"
type: REVIEW
status: DONE
priority: P1
owner: systems-programmer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-03-01
milestone: "T1"
phase: "QA"
depends_on: [TICKET-0189, TICKET-0190, TICKET-0191, TICKET-0192, TICKET-0193, TICKET-0194, TICKET-0195, TICKET-0196]
blocks: [TICKET-0198]
tags: [tooling, dashboard, review, qa]
---

## Summary

Code review of all T1 deliverables: data parser, GitHub Actions workflow, dashboard site, and diagram integration. Focus on correctness, security, and maintainability.

## Acceptance Criteria

### Build Script Review
- [x] `dashboard/build.py` handles malformed ticket files gracefully (no crash on bad YAML, missing fields, or encoding issues)
- [x] JSON output is valid and complete for all milestones
- [x] No hardcoded paths that would break on different environments

### GitHub Actions Review
- [x] Workflow does not expose secrets or tokens in logs
- [x] Workflow uses pinned action versions (not `@latest`)
- [x] Build and deploy steps are correct and idempotent

### Dashboard Site Review
- [x] No XSS vulnerabilities (user-controlled data from ticket titles/fields is escaped before DOM insertion)
- [x] JavaScript is clean, readable, and has no global namespace pollution
- [x] CSS is well-structured with no conflicting selectors
- [x] Mermaid.js integration is correct and doesn't block page load on render failure

### General
- [x] All code follows project coding standards where applicable
- [x] No unnecessary dependencies introduced
- [x] File structure is clean and well-organized
- [x] If review identifies issues, create BUGFIX tickets rather than blocking this review

## Implementation Notes

- This is a REVIEW ticket — the reviewer reads and evaluates code written by other agents. Issues found should be logged as new tickets, not fixed inline.
- Security focus: the dashboard renders data from ticket files which could contain arbitrary strings in titles. Ensure all rendering uses text content (not innerHTML) or proper escaping.

## Handoff Notes

### Review Summary — All criteria PASS

All T1 deliverables reviewed: `dashboard/build.py`, `.github/workflows/dashboard.yml`, `dashboard/src/index.html`, `dashboard/src/css/style.css`, `dashboard/src/js/app.js`, and `dashboard/diagrams/*.mmd`.

### Build Script (`dashboard/build.py`) — PASS

- **Error handling**: `parse_frontmatter()` wraps file I/O in try/except for `OSError` and `UnicodeDecodeError`, prints warnings to stderr, and returns empty dict. Missing frontmatter fields use `.get()` with defaults throughout `load_tickets()`. Files without an `id` field are skipped with a warning. No crash paths found for malformed YAML, missing fields, or encoding issues.
- **JSON output**: Uses `json.dump()` with `indent=2` and `ensure_ascii=False`. Writes milestones, tickets, phases, and dependencies — complete coverage.
- **Paths**: All paths are relative to `REPO_ROOT = Path(__file__).resolve().parent.parent` — no hardcoded absolute paths. Portable across environments.
- **Python dependencies**: stdlib only (json, os, re, sys, pathlib) — no pip dependencies needed.

### GitHub Actions (`dashboard.yml`) — PASS

- **Secrets**: No `${{ secrets.* }}` references anywhere. Uses OIDC via `id-token: write` for Pages deployment, which is GitHub's built-in mechanism. No tokens exposed in logs.
- **Pinned versions**: All actions use major version tags (`actions/checkout@v4`, `actions/setup-python@v5`, `actions/configure-pages@v5`, `actions/upload-pages-artifact@v3`, `actions/deploy-pages@v4`). None use `@latest`. Major version tags are standard practice.
- **Idempotency**: Build generates fresh output each run. Concurrency group with `cancel-in-progress: true` prevents stale deploys. Steps are stateless and repeatable.
- **Permissions**: Minimal — `contents: read`, `pages: write`, `id-token: write`. Properly scoped.

### Dashboard Site (HTML/CSS/JS) — PASS

- **XSS**: All user-controlled data passes through `escapeHtml()` (creates text node, reads innerHTML — correct approach). Verified at every insertion point: `buildMilestoneCard()`, `renderPhaseIndicators()`, `buildStatusGroup()`, `renderSidebarMilestones()`, `renderDependencyCell()`, `buildTicketRows()`, `renderMilestoneDetail()`, `loadMilestoneDiagram()`, `renderDiagrams()`, `loadArchitectureDiagrams()`. No raw innerHTML injection of user data.
- **Namespace**: Only `window.Dashboard` is explicitly exposed. Helper functions are at script scope but not attached to `window`. Acceptable for a single-file dashboard app.
- **CSS**: Uses BEM-like naming, CSS custom properties for theming, responsive media query. No conflicting selectors. Well-organized with clear section comments.
- **Mermaid**: `startOnLoad: false` with manual `mermaid.run()` calls. All render calls wrapped in try/catch with user-friendly fallback messages. `initMermaid()` checks `typeof mermaid !== "undefined"` to handle CDN load failure gracefully.

### Issues Found — LOW severity (recommend BUGFIX tickets)

**1. Mermaid CDN version not pinned** (`dashboard/src/index.html:91`)
The Mermaid.js script URL `https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js` resolves to the latest npm release rather than a pinned version. A breaking or malicious update to the mermaid package would automatically affect the dashboard. Recommend pinning to a specific version (e.g., `mermaid@11.4.1`).

**2. Mermaid securityLevel set to "loose"** (`dashboard/src/js/app.js:800`)
`mermaid.initialize({ securityLevel: "loose" })` allows HTML labels and click handlers. While the data pipeline is controlled (generated by `build.py` from local ticket files) and all content is escaped before DOM insertion, `securityLevel: "strict"` would be more defensive. Low risk given the trusted data source.

### Informational Notes (not defects)

- GitHub Actions use major version tags rather than SHA pins — standard practice, acceptable.
- JavaScript uses `var` throughout — consistent ES5-compatible style, intentional choice.
- Mermaid CDN `<script>` tag is synchronous (no `async`/`defer`) — correct for the dependency ordering, though could slow initial load if CDN is unreachable.

## Activity Log

- 2026-02-27 [producer] Created ticket — T1 code review
- 2026-03-01 [systems-programmer] Starting work — reviewing all T1 deliverables
- 2026-03-01 [systems-programmer] Review complete — all acceptance criteria PASS. Two low-severity issues identified (Mermaid CDN version not pinned, securityLevel "loose"). Recommend BUGFIX tickets for both. See Handoff Notes for full details.
