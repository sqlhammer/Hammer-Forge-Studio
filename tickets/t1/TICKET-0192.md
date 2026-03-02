---
id: TICKET-0192
title: "Dashboard site scaffold — HTML/CSS/JS structure with Mermaid.js"
type: TASK
status: IN_PROGRESS
priority: P1
owner: systems-programmer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "T1"
phase: "Foundation"
depends_on: [TICKET-0190]
blocks: [TICKET-0193, TICKET-0194, TICKET-0195, TICKET-0196]
tags: [tooling, dashboard, frontend, html, mermaid]
---

## Summary

Create the static site scaffold for the project reporting dashboard. This establishes the HTML structure, CSS styling, JavaScript data loading module, and Mermaid.js integration. The scaffold provides the framework that subsequent Dashboard phase tickets will build on.

## Acceptance Criteria

### File Structure
- [ ] Source files at `dashboard/src/`
- [ ] `dashboard/src/index.html` — main entry point with navigation structure
- [ ] `dashboard/src/css/style.css` — dashboard stylesheet
- [ ] `dashboard/src/js/app.js` — JavaScript module for loading and rendering data
- [ ] `dashboard/src/js/mermaid.min.js` or CDN link for Mermaid.js library
- [ ] `dashboard/dist/` added to `.gitignore` (build output, not committed)

### HTML Structure
- [ ] Responsive layout with sidebar navigation and main content area
- [ ] Navigation links for: Dashboard (overview), each milestone, Diagrams (architecture)
- [ ] Header with project name "Hammer Forge Studio" and last-build timestamp
- [ ] Footer with "Auto-generated from project data" note

### Styling
- [ ] Dark theme (dark background, light text) to match developer tool aesthetics
- [ ] Clean, readable typography (system font stack or monospace)
- [ ] Status badges with color coding: green (DONE/Complete), yellow (IN_PROGRESS/Active), grey (OPEN/Planning)
- [ ] Progress bars styled for milestone completion
- [ ] Responsive: usable on screens from 768px to 1920px wide

### JavaScript Data Loading
- [ ] `app.js` fetches pre-baked JSON files from `data/` directory (relative path)
- [ ] Renders data into DOM elements using vanilla JS (no framework dependency)
- [ ] Mermaid.js initialized and rendering a test diagram on page load
- [ ] Error handling: displays "No data available" message if JSON files are missing or malformed

### Mermaid.js Integration
- [ ] Mermaid.js loaded (CDN or bundled — CDN preferred for simplicity)
- [ ] Test diagram renders correctly on the page
- [ ] Mermaid theme set to `dark` to match site styling

## Implementation Notes

- Keep the site purely static — no build tools, no npm, no bundler. Plain HTML/CSS/JS that can be served from any static file server.
- Mermaid.js CDN: `https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js` (latest stable)
- The JavaScript module should be structured so that Dashboard phase tickets can add rendering functions without modifying the core loading logic.
- Navigation can be simple anchor links within a single page (SPA-style with sections) or separate HTML files per view. Single page with sections is simpler.

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created ticket — static site scaffold for dashboard
- 2026-03-01 [systems-programmer] Starting work — building HTML/CSS/JS scaffold with Mermaid.js
