# Producer Decision Log

---

## [2026-02-23] [Process] Agent Self-Merge on Worktree PRs

**Context:** During M3 Phase 2 closeout, tickets TICKET-0024 through TICKET-0029 remained `OPEN` despite the gameplay-programmer having committed and pushed all work. The root cause was a hidden dependency in the worktree workflow: agents created PRs but were instructed not to merge them — that responsibility belonged to the systems-programmer as part of code review. Because code review happened via a separate `REVIEW` ticket (TICKET-0030) and was not yet scheduled, the PRs sat unmerged and tickets could not be marked `DONE`. The QA engineer escalated, correctly identifying that TICKET-0031 was still blocked.

**Decision:** Adopted Option A — agents self-merge their own PRs immediately after creation. The updated workflow is: commit → push branch → open PR → self-merge → mark `DONE`. Code review still occurs post-merge via a separate `REVIEW` ticket assigned to the systems-programmer. CLAUDE.md and the worktree section of the git workflow were updated to reflect this. The producer's hard boundary on `/game/` modifications was also codified in `agents/producer/CLAUDE.md` as a related guardrail surfaced during the same session.

**Alternatives considered:**
1. Keep systems-programmer as merge gate — rejected because it contradicts the stated principle that "code review does NOT block commits" and creates an undeclared dependency that stalls ticket closure
2. Auto-merge on PR creation without review — effectively the same as Option A but rejected as a framing; a PR still serves as a visible record of the branch before merge
3. Make the merge step an explicit task within the `REVIEW` ticket — rejected because it still gates `DONE` status on a separate agent completing work, just with a different label

**Rationale:**
- The worktree PR workflow was designed to surface work for review, not to gate progress on a reviewer's availability
- Self-merge preserves the PR audit trail while eliminating the inter-agent blocking dependency
- Post-merge code review via `REVIEW` tickets is already the documented pattern for `main`-based commits; this aligns worktree commits with the same model
- Tickets can now be marked `DONE` as soon as implementation is complete and merged, which is when they should be closed

---

## [2026-02-21] [TICKET-0001 through TICKET-0007] M1 Milestone Kickoff and Sprint Planning

**Context:** Studio Head provided M1 goals: testable player scene with first-person and third-person view systems, plus unified input architecture supporting keyboard and gamepad.

**Decision:** Created 7 sequential tickets (TICKET-0001 to TICKET-0007) with clear dependency chains to establish core game architecture. Structured work as: Design → InputManager → Controllers (parallel) → Integration → Review → QA.

**Alternatives considered:**
1. Flatter structure with all tickets independent — rejected because input system design must precede implementation
2. Single monolithic ticket — rejected because it lacks modularity and prevents parallel work
3. Three separate tickets per agent without review/QA — rejected because coding standards enforcement and QA sign-off are required before milestone close

**Rationale:**
- Sequential design→implementation flow ensures architectural decisions are captured before coding
- InputManager as a central component unblocks both controller implementations in parallel
- Separating code review (TICKET-0006) allows systems-programmer to verify standards compliance before QA testing
- QA testing as final blocker (TICKET-0007) ensures release readiness per producer responsibilities
- 3-week target (2026-03-14) allows 2 weeks of implementation + 1 week of review/QA buffer
- Assignments respect agent specialization (game-designer for design, systems-programmer for architecture/review, gameplay-programmer for mechanics, qa-engineer for testing)
