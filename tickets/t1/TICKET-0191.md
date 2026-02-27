---
id: TICKET-0191
title: "GitHub Actions workflow — build pipeline and GitHub Pages deployment"
type: TASK
status: OPEN
priority: P1
owner: tools-devops-engineer
created_by: producer
created_at: 2026-02-27
updated_at: 2026-02-27
milestone: "T1"
phase: "Foundation"
depends_on: [TICKET-0190, TICKET-0192]
blocks: []
tags: [tooling, dashboard, ci-cd, github-actions, github-pages]
---

## Summary

Create a GitHub Actions workflow that triggers on every push to `main`, runs the dashboard data parser, assembles the static site, and deploys to GitHub Pages.

## Acceptance Criteria

### Workflow File
- [ ] Workflow at `.github/workflows/dashboard.yml`
- [ ] Triggers on push to `main` branch
- [ ] Also supports manual trigger via `workflow_dispatch` for on-demand rebuilds
- [ ] Uses `actions/checkout@v4` to check out the full repo
- [ ] Sets up Python (version 3.11+) for the build script

### Build Step
- [ ] Runs `python dashboard/build.py` to generate JSON data files
- [ ] Copies `dashboard/src/` static files to the build output directory
- [ ] Copies generated data files to the correct location within the output
- [ ] Build completes in under 60 seconds

### Deployment
- [ ] Deploys the assembled output to GitHub Pages using `actions/deploy-pages@v4` (or `peaceiris/actions-gh-pages@v4`)
- [ ] GitHub Pages is enabled on the repo (may require initial manual setup — document this)
- [ ] Dashboard is accessible at the GitHub Pages URL after deployment
- [ ] Deployment does not affect the `main` branch (uses the Pages artifact method, not a `gh-pages` branch, unless the artifact method is unavailable)

### Robustness
- [ ] Workflow does not fail if no ticket files exist (empty dashboard is valid)
- [ ] Workflow does not expose any secrets or tokens in logs
- [ ] Build output is minimal (no unnecessary files deployed)

## Implementation Notes

- The GitHub Pages deployment method depends on repo settings. The `actions/deploy-pages` approach (artifact-based) is preferred as it avoids creating a `gh-pages` branch. If the repo is not eligible for this method, fall back to `peaceiris/actions-gh-pages` which pushes to a `gh-pages` branch.
- GitHub Pages may need to be enabled in repo settings (Settings → Pages → Source: GitHub Actions). Document this as a one-time setup step.
- No secrets should be needed — the workflow reads from the repo checkout, not the GitHub API.
- Consider adding a `paths` filter to only trigger on changes to `tickets/`, `docs/studio/`, or `dashboard/` to avoid unnecessary builds on game-only changes. However, start without the filter for simplicity.

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-27 [producer] Created ticket — GitHub Actions CI/CD for dashboard
