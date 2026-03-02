# UAT Sign-Off — T1: Project Reporting Dashboard

> **Prepared by:** qa-engineer
> **Date Prepared:** 2026-03-01
> **Milestone:** T1 — Project Reporting Dashboard
>
> **Studio Head:** Review each feature below, follow the How to Test steps, then mark each checkbox.
> When all checkboxes are marked `✅ Approved`, reply to the Producer to grant final milestone sign-off.

---

## Header

| Field | Value |
|-------|-------|
| **Milestone** | T1 — Project Reporting Dashboard |
| **Prepared By** | qa-engineer |
| **Date Prepared** | 2026-03-01 |
| **Test Build** | 5c04139 (main) |
| **Dashboard URL** | https://sqlhammer.github.io/Hammer-Forge-Studio/ |
| **Sign-Off Status** | ⏳ Pending |

---

## How to Use This Document

1. All features in this milestone are **tooling/web dashboard** features — no Godot scene required.
2. For each feature, check the **Verification Method** tag:
   - `integration-test` — Covered by QA build validation (build.py ran clean, JSON output verified)
   - **`manual-playtest`** — **Requires hands-on testing by Studio Head.** Open the dashboard URL in a browser and follow the steps.
3. For `manual-playtest` items, open https://sqlhammer.github.io/Hammer-Forge-Studio/ in Chrome or Firefox.
4. Mark each checkbox:
   - `✅ Approved` — feature works as described, no blocking issues
   - `❌ Rejected` — feature is broken or missing; add a note describing the problem
5. Once all features are marked, sign off at the bottom.

> **Note:** Cross-browser testing should be done in both Chrome (latest) and Firefox (latest). The dashboard uses `fetch()`, `async/await`, and CSS custom properties — all well-supported in modern versions of both browsers. Code review (TICKET-0197) confirmed no XSS vulnerabilities and no global namespace pollution.

---

## Feature Sign-Off Checklist

### Foundation — Data Pipeline & Deployment

---

#### T-Series Milestone Convention (TICKET-0189)

**Verification Method:** `integration-test`

**What changed:** Established the T-series milestone naming convention for tooling milestones (T1, T2, T3, T4). Updated orchestrator docs, `milestones.md`, and process docs to recognize T-series milestones as first-class citizens alongside game milestones. Milestones with IDs starting with "T" are treated identically to "M" milestones in all tooling.

**How to test:** Open the dashboard and verify T1, T2, T3, T4 appear as distinct milestone entries in the sidebar alongside the game milestones (M1–M16, M9).

**Expected result:** T-series milestones display in the sidebar. T1 shows Active, T2 shows Complete, T3 and T4 show their respective statuses.

**Automated coverage:** QA build validation: T1 parsed as 10 tickets, T4 as 9 tickets, T3 as 1 ticket — all correctly identified and grouped by milestone ID.

- [ ] ✅ Approved / ❌ Rejected — _Notes:_

---

#### Dashboard Data Parser (TICKET-0190)

**Verification Method:** `integration-test`

**What changed:** New Python script `dashboard/build.py` reads all ticket markdown files and `docs/studio/milestones.md`, extracts structured data via frontmatter parsing, computes milestone aggregates and phase breakdowns, and writes JSON files to `dashboard/dist/data/`. The script handles malformed ticket files gracefully (no crash on bad YAML or missing fields).

**How to test:** Verify the dashboard displays accurate milestone data.
1. Open the dashboard at https://sqlhammer.github.io/Hammer-Forge-Studio/
2. Click on **M9** in the sidebar — verify it shows 30 total tickets, 7 done, 1 in-progress, 22 open
3. Click on **T1** — verify it shows 10 total tickets

**Expected result:** Milestone counts match the actual ticket files in the repo. M9: 30 total (7 done, 1 in-progress, 22 open). T1: 10 total (9 done, 1 in-progress). Completion percentages are displayed (M9: ~23.3%, T1: 90%).

**Automated coverage:** QA build validation: `python dashboard/build.py` ran cleanly; parsed 51 ticket files, 21 milestones. JSON output verified against actual file counts.

- [ ] ✅ Approved / ❌ Rejected — _Notes:_

---

#### GitHub Actions Workflow — Auto-Build and Deploy (TICKET-0191)

**Verification Method:** `integration-test`

**What changed:** New GitHub Actions workflow (`.github/workflows/dashboard.yml`) triggers on every push to `main` and on manual dispatch. It runs `dashboard/build.py`, assembles the static site, and deploys to GitHub Pages via artifact upload. No secrets or tokens are exposed; OIDC is used for Pages deployment.

**How to test:** The auto-update test was verified during this QA session.
1. A ticket status change was pushed to `main` as the test change
2. The dashboard.yml workflow was observed to trigger automatically
3. Confirm at https://github.com/sqlhammer/Hammer-Forge-Studio/actions that recent runs show "completed: success"
4. Confirm the deployed dashboard at https://sqlhammer.github.io/Hammer-Forge-Studio/ reflects current repo state

**Expected result:** Every push to `main` triggers a build+deploy completing in ~30 seconds. The dashboard reflects the latest ticket data within 1 minute of push.

**Automated coverage:** QA validation: 5 most recent workflow runs all completed with status "success" in 28–32 seconds. Workflow concurrency group prevents stale deploys. No secrets exposed in logs.

- [ ] ✅ Approved / ❌ Rejected — _Notes:_

---

#### Dashboard Site Scaffold (TICKET-0192)

**Verification Method:** `manual-playtest`

**What changed:** Static site foundation: `dashboard/src/index.html` (single-page app), `dashboard/src/css/style.css` (dark theme, responsive layout), `dashboard/src/js/app.js` (data loading, rendering). Mermaid.js integrated via CDN for diagram rendering. Site architecture: sidebar (milestone list) + main content area (overview/detail views).

**How to test:**
1. Open https://sqlhammer.github.io/Hammer-Forge-Studio/ in Chrome and Firefox
2. Verify the page loads with a dark-themed sidebar and main content area
3. Open browser DevTools → Console — confirm zero JavaScript errors on page load
4. Resize the browser window to a narrow width (≤768px) — verify layout adapts responsively

**Expected result:** Dashboard loads successfully in both browsers with no console errors. Dark theme renders correctly. Layout is responsive on narrow viewports. Mermaid.js loads from CDN without blocking page render.

**Automated coverage:** Code review (TICKET-0197) confirmed: no XSS vulnerabilities, clean JavaScript, CSS with no conflicting selectors, Mermaid.js integration non-blocking.

- [ ] ✅ Approved / ❌ Rejected — _Notes:_

---

### Dashboard Features — Milestone Views

---

#### Milestone Overview Page — Progress Bars and Phase Gates (TICKET-0193)

**Verification Method:** `manual-playtest`

**What changed:** Main dashboard view shows all milestones with completion progress bars, ticket count breakdown (done/in-progress/open), status badge (Active/Planning/Complete), and phase gate indicators showing which phases are passing. Completed milestones (M1–M8, T2, T4) are visually distinguished.

**How to test:**
1. Open https://sqlhammer.github.io/Hammer-Forge-Studio/
2. Verify the overview shows milestone cards or a table with progress bars
3. Select a completed milestone (e.g., M8 or T4) — verify it shows a "Complete" status and 100% or appropriate completion indicator
4. Select M9 (Active) — verify it shows the correct phase breakdown with which phases have passed their gates and which have not

**Expected result:** Milestone overview shows accurate progress bars and phase gate status. Completed milestones have their QA sign-off date displayed. Phase gates show correct pass/fail state (T1 Foundation: ✓ passed, T1 Dashboard: ✓ passed, T1 QA: not yet passed while TICKET-0198 is in progress).

**Automated coverage:** QA build validation: phases.json verified — T1 Foundation gate_passed=true, T1 Dashboard gate_passed=true, T1 QA gate_passed=false (correctly reflects active TICKET-0198).

- [ ] ✅ Approved / ❌ Rejected — _Notes:_

---

#### Ticket Detail Views — Per-Milestone Tables (TICKET-0194)

**Verification Method:** `manual-playtest`

**What changed:** Clicking a milestone in the sidebar shows a detail view with a table of all tickets for that milestone. Each row shows: ticket ID, title, type, status (colored badge), priority, owner, and phase. Long ticket titles display with ellipsis (no layout breakage).

**How to test:**
1. Open https://sqlhammer.github.io/Hammer-Forge-Studio/
2. Click on **T1** in the sidebar
3. Verify a ticket table appears showing all 10 T1 tickets (TICKET-0189 through TICKET-0198)
4. Verify statuses are correct: TICKET-0197 shows DONE (green), TICKET-0198 shows IN_PROGRESS (yellow)
5. Verify ticket titles display cleanly without overflow

**Expected result:** Ticket table shows all 10 T1 tickets with correct status, owner, phase, and priority. Status badges are color-coded. Long titles truncate with ellipsis without breaking the table layout.

**Automated coverage:** QA build validation: tickets.json verified — all 10 T1 tickets present with correct fields. CSS confirmed: max-width + text-overflow:ellipsis on table cells prevents overflow.

- [ ] ✅ Approved / ❌ Rejected — _Notes:_

---

#### Dependency Graph Diagrams — Auto-Generated from Ticket Frontmatter (TICKET-0195)

**Verification Method:** `manual-playtest`

**What changed:** The build script generates a Mermaid flowchart for each milestone's dependency graph by reading `depends_on` fields from ticket frontmatter. Nodes are colored by status (green=DONE, yellow=IN_PROGRESS, grey=OPEN). Cross-milestone dependencies are shown as dashed edges. Circular dependencies are detected and highlighted with red borders.

**How to test:**
1. Open https://sqlhammer.github.io/Hammer-Forge-Studio/
2. Click on **T1** in the sidebar
3. Navigate to the T1 dependency graph diagram
4. Verify TICKET-0197 appears as a green node with 8 incoming edges (from TICKET-0189 through TICKET-0196)
5. Verify TICKET-0198 appears as a yellow (IN_PROGRESS) node with one incoming edge from TICKET-0197
6. Click on **M9** and verify its dependency diagram renders without errors

**Expected result:** T1 dependency graph renders correctly. All dependency edges match the `depends_on` fields in ticket frontmatter (spot-checked: TICKET-0191 has edges from TICKET-0190 and TICKET-0192; TICKET-0198 has one edge from TICKET-0197). No Mermaid rendering errors.

**Automated coverage:** QA build validation: T1.mmd generated with 17 edges — all verified against ticket frontmatter. build.py ran with zero warnings or errors.

- [ ] ✅ Approved / ❌ Rejected — _Notes:_

---

#### Architecture and Game Loop Diagrams — Curated Mermaid Files (TICKET-0196)

**Verification Method:** `manual-playtest`

**What changed:** Three hand-curated Mermaid diagrams added to `dashboard/diagrams/`: `system-architecture.mmd` (Godot autoloads and scene hierarchy), `game-core-loop.mmd` (player action flow), and `agent-orchestration-flow.mmd` (conductor/producer/worker pipeline). These are copied to `dashboard/dist/data/architecture/` at build time and rendered in a dedicated "Architecture" section of the dashboard.

**How to test:**
1. Open https://sqlhammer.github.io/Hammer-Forge-Studio/
2. Navigate to the Architecture section of the dashboard
3. Verify three diagrams render: System Architecture, Game Core Loop, Agent Orchestration Flow
4. Verify each diagram is readable and shows the correct structure

**Expected result:** All three architecture diagrams render without Mermaid errors. System Architecture shows Godot autoload singletons and scene hierarchy. Game Core Loop shows the player action flowchart. Agent Orchestration Flow shows the conductor → producer → worker pipeline.

**Automated coverage:** QA build validation: all 3 `.mmd` files copied cleanly to `dashboard/dist/data/architecture/`. Mermaid syntax validated — each file uses valid `graph TD` or `flowchart TD` declarations.

- [ ] ✅ Approved / ❌ Rejected — _Notes:_

---

### Edge Cases & Robustness

---

#### Milestones with No Tickets (M10–M16) (edge case — TICKET-0193)

**Verification Method:** `integration-test`

**What changed:** The dashboard must handle milestones that are in Planning status with no ticket files yet (M10 through M16).

**How to test:**
1. Open the dashboard and select any planning-stage milestone (e.g., M10, M11, or M15)
2. Verify the milestone displays without errors — should show 0 tickets, "Planning" status, and no crash

**Expected result:** Planning milestones render a clean "no tickets" or empty state without JavaScript errors or layout breakage.

**Automated coverage:** QA build validation: milestones.json confirmed M10–M16 all show total=0, completion_pct=0.0, status="Planning". Build ran cleanly with no warnings for empty milestones.

- [ ] ✅ Approved / ❌ Rejected — _Notes:_

---

#### Archived Milestone Handling (M1–M7) (edge case — TICKET-0190)

**Verification Method:** `integration-test`

**What changed:** Milestones M1–M7 are complete with their tickets archived in `tickets/_archive/`. The build script skips the archive folder by design — archived tickets are not counted in live aggregates.

**How to test:**
1. Open the dashboard and select a completed archived milestone (e.g., M1, M3, or M7)
2. Verify the milestone displays with "Complete" status and the correct QA sign-off date
3. Verify no crash or error occurs even though ticket counts show 0 (archived)

**Expected result:** Completed archived milestones display with "Complete" status and QA sign-off date. Ticket counts show 0 (by design — archived tickets are not scanned). The dashboard renders cleanly.

**Automated coverage:** QA build validation: M1–M7 confirmed in milestones.json with status="Complete" and correct qa_signoff dates. Total=0 is expected behavior for archived milestones.

- [ ] ✅ Approved / ❌ Rejected — _Notes:_

---

## QA Findings

### Findings from TICKET-0198 Validation Session (2026-03-01)

All validation executed by qa-engineer against commit `5c04139` on `main`. Build script (`dashboard/build.py`) ran against the live repo with no warnings or errors.

| Finding | Severity | System | Observation | Disposition |
|---------|----------|--------|-------------|-------------|
| F-001 | P2 | Ticket ID numbering | TICKET-0189, TICKET-0190, and TICKET-0191 each exist in **two** directories: `tickets/t1/` and `tickets/m9/`, with completely different content and different milestones. The build.py loads both, resulting in 51 files parsed with 3 IDs appearing twice. The `all_ticket_map` dict in `generate_mermaid_diagram()` retains only the last-loaded version per ID, which could cause incorrect cross-milestone dependency rendering. T1 milestone data is unaffected (T1 diagrams and counts are correct). | Known issue, acceptable for T1 sign-off — file a follow-up BUG ticket to rename M9 TICKET-0189/0190/0191 to unique IDs |
| F-002 | P3 | build.py / archived milestones | Archived milestones (M1–M8) show `total=0` ticket counts on the dashboard because `build.py` skips the `_archive/` folder by design. The milestones.md already uses "—" for these counts, so the dashboard is consistent with the source of truth. No incorrect data displayed. | Known behavior, acceptable — design decision to only show active ticket data |
| F-003 | P3 | Mermaid CDN | Mermaid.js is loaded from an unpinned CDN URL (`https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js`). A breaking mermaid npm release could break diagram rendering without warning. Already identified in code review TICKET-0197. | Deferred — recommend follow-up BUGFIX ticket to pin mermaid to a specific version (e.g., mermaid@11.4.1) |
| F-004 | P3 | Mermaid security | `securityLevel: "loose"` in Mermaid initialization allows HTML labels. Low risk given trusted data source (build.py from local ticket files). Already identified in code review TICKET-0197. | Known issue, acceptable — data pipeline is trusted; low risk |

### Bugs Filed

- F-001 (P2 — duplicate ticket IDs): BUG ticket to be filed against the ticket numbering system. M9 tickets TICKET-0189/0190/0191 should be renumbered to unique IDs to eliminate the data integrity issue.
- F-003 and F-004: Follow-up BUGFIX tickets recommended for pinning Mermaid CDN and tightening securityLevel.

---

## Rejection Notes

| Feature | Ticket | Issue Description |
|---------|--------|-------------------|
| — | — | None |

---

## Final Sign-Off

**Total Features:** 8
**Approved:** 8 (pending Studio Head review)
**Rejected:** 0

**Gate Condition:** All features must be `✅ Approved` for sign-off to be granted.

---

**Studio Head Sign-Off:**

- [ ] All features approved — milestone is cleared for close

**Signed off by:** _(Studio Head — Derik Hammer)_
**Date:** _(pending)_
