"""mock_agents.py — Mock run_claude for the orchestrator test harness.

Replaces the real `run_claude` subprocess call with canned JSON responses.
The mock Producer reads actual ticket frontmatter to compute wave plans.
The mock Worker marks tickets DONE and returns worker_result JSON.
"""

import json
import re
from pathlib import Path

from .generate_tickets import mark_ticket_done


# ---------------------------------------------------------------------------
# Ticket parsing (mirrors tools/milestone_status.py logic)
# ---------------------------------------------------------------------------

def _parse_frontmatter(path: Path) -> dict:
    fields = {}
    dashes = 0
    with path.open(encoding="utf-8") as f:
        for raw in f:
            line = raw.rstrip("\r\n")
            if line == "---":
                dashes += 1
                if dashes == 2:
                    break
                continue
            if dashes < 1:
                continue
            if ":" not in line:
                continue
            key, _, val = line.partition(":")
            fields[key.strip()] = val.strip()
    return fields


def _parse_depends(raw: str) -> list[str]:
    raw = raw.strip().strip("[]")
    if not raw:
        return []
    return [t.strip() for t in raw.split(",") if t.strip()]


def _get_test_tickets(repo_root: Path) -> dict:
    """Return {ticket_id: frontmatter_dict} for all tickets in _test/."""
    test_dir = repo_root / "tickets" / "_test"
    tickets = {}
    if not test_dir.exists():
        return tickets
    for path in sorted(test_dir.glob("TICKET-*.md")):
        fm = _parse_frontmatter(path)
        tid = fm.get("id", "")
        if tid:
            tickets[tid] = fm
    return tickets


# ---------------------------------------------------------------------------
# Failure injection state
# ---------------------------------------------------------------------------

class FailureInjector:
    """Tracks which tickets should fail on their first attempt."""

    def __init__(self, fail_once: set[str] | None = None):
        # ticket IDs that fail on first attempt, succeed on retry
        self._fail_once = fail_once or set()
        self._attempt_counts: dict[str, int] = {}

    def should_fail(self, ticket_id: str) -> bool:
        count = self._attempt_counts.get(ticket_id, 0)
        self._attempt_counts[ticket_id] = count + 1
        if ticket_id in self._fail_once and count == 0:
            return True
        return False


# ---------------------------------------------------------------------------
# Mock run_claude
# ---------------------------------------------------------------------------

def create_mock_run_claude(repo_root: Path, injector: FailureInjector | None = None,
                           verbose: bool = False):
    """Return an async function matching the run_claude signature.

    It inspects the prompt to decide whether this is a Producer or Worker call,
    then returns the appropriate canned JSON.
    """
    if injector is None:
        injector = FailureInjector()

    async def mock_run_claude(
        prompt: str,
        model: str,
        budget: float,
        blocked_tools: list[str],
        agent_claude_md=None,
        output_json: bool = True,
        json_schema=None,
        cwd=None,
        timeout_minutes: int = 30,
        log_path=None,
        on_proc_start=None,
    ) -> tuple[int, str, str, dict]:
        # Determine if this is a Producer or Worker call based on prompt content
        is_producer = "wave" in prompt.lower() and "plan" in prompt.lower()

        if is_producer:
            return _mock_producer(prompt, repo_root, verbose)
        else:
            return _mock_worker(prompt, repo_root, injector, verbose)

    return mock_run_claude


def _mock_producer(prompt: str, repo_root: Path,
                   verbose: bool) -> tuple[int, str, str, dict]:
    """Simulate the Producer: read ticket statuses, return a wave plan."""
    tickets = _get_test_tickets(repo_root)

    # Extract milestone from prompt
    milestone_match = re.search(r"milestone[=:]\s*(\S+)", prompt, re.IGNORECASE)
    milestone = milestone_match.group(1) if milestone_match else "_test"

    # Build status map
    done_ids = {tid for tid, fm in tickets.items() if fm.get("status") == "DONE"}
    open_ids = {tid for tid, fm in tickets.items() if fm.get("status") != "DONE"}

    # Check for milestone_complete
    if not open_ids:
        plan = {
            "action": "milestone_complete",
            "summary": "All TEST tickets are DONE.",
        }
        if verbose:
            print(f"  [MOCK-PRODUCER] milestone_complete")
        return (0, json.dumps(plan), "", {})

    # Find dispatchable tickets — any phase, deps met
    dispatchable = []
    for tid, fm in tickets.items():
        if fm.get("status") == "DONE":
            continue
        deps = _parse_depends(fm.get("depends_on", "[]"))
        if all(d in done_ids for d in deps):
            dispatchable.append((tid, fm))

    if not dispatchable:
        # No work available — waiting on deps
        plan = {
            "action": "no_work",
            "summary": "No dispatchable tickets.",
        }
        if verbose:
            print(f"  [MOCK-PRODUCER] no_work")
        return (0, json.dumps(plan), "", {})

    # Build wave
    wave = []
    for tid, fm in sorted(dispatchable, key=lambda x: x[0]):
        owner = fm.get("owner", "systems-programmer")
        wave.append({
            "agent": owner,
            "ticket": tid,
            "budget_usd": 0.50,
            "needs_worktree": fm.get("needs_worktree", "false").lower() == "true",
            "needs_godot_mcp": False,
        })

    plan = {
        "action": "spawn_agents",
        "summary": f"Dispatching {len(wave)} tickets.",
        "wave": wave,
    }
    if verbose:
        tids = ", ".join(w["ticket"] for w in wave)
        print(f"  [MOCK-PRODUCER] spawn_agents: [{tids}]")
    return (0, json.dumps(plan), "", {})


def _mock_worker(prompt: str, repo_root: Path, injector: FailureInjector,
                 verbose: bool) -> tuple[int, str, str, dict]:
    """Simulate a Worker: mark ticket DONE, return worker_result JSON."""
    # Extract ticket ID from the prompt
    ticket_match = re.search(r"(TICKET-\d+)", prompt)
    if not ticket_match:
        return (1, "", "No ticket ID found in prompt", {})
    ticket_id = ticket_match.group(1)

    # Check failure injection
    if injector.should_fail(ticket_id):
        result = {
            "ticket": ticket_id,
            "outcome": "failed",
            "summary": f"Injected failure for {ticket_id} (will succeed on retry).",
            "blockers": ["Injected test failure"],
        }
        if verbose:
            print(f"  [MOCK-WORKER] {ticket_id}: FAILED (injected)")
        return (0, json.dumps(result), "", {})

    # Mark ticket DONE in the file
    mark_ticket_done(repo_root, ticket_id)

    result = {
        "ticket": ticket_id,
        "outcome": "done",
        "summary": f"Test ticket {ticket_id} completed successfully.",
        "commit_hash": "abc1234",
        "files_changed": [f"tickets/_test/{ticket_id}.md"],
        "new_gd_scripts": False,
        "blockers": [],
    }
    if verbose:
        print(f"  [MOCK-WORKER] {ticket_id}: DONE")
    return (0, json.dumps(result), "", {})
