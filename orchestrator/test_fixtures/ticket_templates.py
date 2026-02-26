"""ticket_templates.py — Fake ticket markdown for the orchestrator test harness.

Milestone TEST, IDs 9901-9906 to avoid collision with production tickets.
Two phases: Alpha (9901-9903) and Beta (9904-9906).
"""

TICKETS = {
    "TICKET-9901": """\
---
id: TICKET-9901
title: "Test: Independent docs task A"
status: OPEN
owner: systems-programmer
milestone: "TEST"
phase: "Alpha"
depends_on: []
needs_worktree: false
---

# TICKET-9901 — Test: Independent docs task A

## Acceptance Criteria
- Write "DONE" to the Activity Log section below.

## Activity Log
""",

    "TICKET-9902": """\
---
id: TICKET-9902
title: "Test: Independent task B"
status: OPEN
owner: gameplay-programmer
milestone: "TEST"
phase: "Alpha"
depends_on: []
needs_worktree: false
---

# TICKET-9902 — Test: Independent task B

## Acceptance Criteria
- Write "DONE" to the Activity Log section below.

## Activity Log
""",

    "TICKET-9903": """\
---
id: TICKET-9903
title: "Test: Fan-in gate trigger"
status: OPEN
owner: qa-engineer
milestone: "TEST"
phase: "Alpha"
depends_on: [TICKET-9901, TICKET-9902]
needs_worktree: false
---

# TICKET-9903 — Test: Fan-in gate trigger

## Acceptance Criteria
- Write "DONE" to the Activity Log section below.

## Activity Log
""",

    "TICKET-9904": """\
---
id: TICKET-9904
title: "Test: Post-gate task A"
status: OPEN
owner: gameplay-programmer
milestone: "TEST"
phase: "Beta"
depends_on: [TICKET-9903]
needs_worktree: false
---

# TICKET-9904 — Test: Post-gate task A

## Acceptance Criteria
- Write "DONE" to the Activity Log section below.

## Activity Log
""",

    "TICKET-9905": """\
---
id: TICKET-9905
title: "Test: Post-gate task B"
status: OPEN
owner: systems-programmer
milestone: "TEST"
phase: "Beta"
depends_on: [TICKET-9903]
needs_worktree: false
---

# TICKET-9905 — Test: Post-gate task B

## Acceptance Criteria
- Write "DONE" to the Activity Log section below.

## Activity Log
""",

    "TICKET-9906": """\
---
id: TICKET-9906
title: "Test: Final fan-in"
status: OPEN
owner: qa-engineer
milestone: "TEST"
phase: "Beta"
depends_on: [TICKET-9904, TICKET-9905]
needs_worktree: false
---

# TICKET-9906 — Test: Final fan-in

## Acceptance Criteria
- Write "DONE" to the Activity Log section below.

## Activity Log
""",
}
