"""assertions.py — Validation functions for the orchestrator test harness.

Each function returns (passed: bool, message: str).
"""

import json
from pathlib import Path


def check_terminal_state(state: dict) -> tuple[bool, str]:
    """1. Terminal state is IDLE (milestone completed)."""
    status = state.get("status", "?")
    ok = status == "IDLE"
    return ok, f"Terminal state: {status}"


def check_wave1_parallel(waves: list[dict]) -> tuple[bool, str]:
    """2. Wave 1 dispatches TICKET-9901 + TICKET-9902 in parallel."""
    if not waves:
        return False, "No waves recorded"
    w1 = waves[0]
    tids = set(w1.get("tickets_dispatched", []))
    ok = {"TICKET-9901", "TICKET-9902"}.issubset(tids)
    return ok, f"Wave 1: parallel dispatch ({', '.join(sorted(tids))})"


def check_wave1_no_9903(waves: list[dict]) -> tuple[bool, str]:
    """3. Wave 1 does NOT dispatch TICKET-9903 (deps unmet)."""
    if not waves:
        return False, "No waves recorded"
    w1 = waves[0]
    tids = set(w1.get("tickets_dispatched", []))
    ok = "TICKET-9903" not in tids
    return ok, f"Wave 1: 9903 not dispatched (deps unmet)"


def check_9903_dispatched(waves: list[dict]) -> tuple[bool, str]:
    """4. Some wave dispatches TICKET-9903 after deps satisfied."""
    for w in waves:
        if "TICKET-9903" in w.get("tickets_dispatched", []):
            return True, f"Wave {w['wave']}: 9903 dispatched"
    return False, "TICKET-9903 never dispatched"


def check_gate_fired(events: list[dict]) -> tuple[bool, str]:
    """5. Phase gate fires after all Alpha tickets DONE."""
    for e in events:
        if e.get("type") == "gate_blocked":
            return True, f"Phase gate: GATE_BLOCKED after Alpha"
    return False, "No gate_blocked event found"


def check_gate_approved(events: list[dict]) -> tuple[bool, str]:
    """6. Gate auto-approved, state transitions to Beta phase."""
    for e in events:
        if e.get("type") == "gate_approved":
            return True, f"Gate auto-approved -> Beta"
    return False, "No gate_approved event found"


def check_beta_parallel(waves: list[dict]) -> tuple[bool, str]:
    """7. Some wave dispatches TICKET-9904 + TICKET-9905 in parallel."""
    for w in waves:
        tids = set(w.get("tickets_dispatched", []))
        if {"TICKET-9904", "TICKET-9905"}.issubset(tids):
            return True, f"Wave {w['wave']}: parallel dispatch (9904, 9905)"
    return False, "TICKET-9904 + 9905 never dispatched together"


def check_9906_dispatched(waves: list[dict]) -> tuple[bool, str]:
    """8. Some wave dispatches TICKET-9906 (final fan-in)."""
    for w in waves:
        if "TICKET-9906" in w.get("tickets_dispatched", []):
            return True, f"Wave {w['wave']}: 9906 dispatched"
    return False, "TICKET-9906 never dispatched"


def check_milestone_complete(events: list[dict]) -> tuple[bool, str]:
    """9. Final wave returns milestone_complete."""
    for e in events:
        if e.get("type") == "milestone_complete":
            return True, "Final wave: milestone_complete"
    return False, "No milestone_complete event found"


def check_producer_schema(waves: list[dict], schema: dict) -> tuple[bool, str]:
    """10. All producer outputs validate against wave_plan.json schema."""
    # Lightweight validation: check required fields exist and action is valid
    valid_actions = set(schema["properties"]["action"]["enum"])
    for w in waves:
        raw = w.get("raw_plan", {})
        action = raw.get("action")
        if action not in valid_actions:
            return False, f"Invalid producer action: {action}"
        if "summary" not in raw:
            return False, f"Producer output missing 'summary'"
        if action == "spawn_agents":
            wave_items = raw.get("wave", [])
            for item in wave_items:
                for key in ("agent", "ticket", "budget_usd", "needs_worktree", "needs_godot_mcp"):
                    if key not in item:
                        return False, f"Wave item missing '{key}'"
        if action == "gate_blocked":
            gate = raw.get("gate", {})
            for key in ("milestone", "phase", "next_phase", "summary"):
                if key not in gate:
                    return False, f"Gate missing '{key}'"
    return True, "Schema: producer outputs valid"


def check_worker_schema(results: list[dict], schema: dict) -> tuple[bool, str]:
    """11. All worker results validate against worker_result.json schema."""
    valid_outcomes = set(schema["properties"]["outcome"]["enum"])
    for r in results:
        if "ticket" not in r:
            return False, f"Worker result missing 'ticket'"
        if "outcome" not in r:
            return False, f"Worker result missing 'outcome'"
        if r["outcome"] not in valid_outcomes:
            return False, f"Invalid worker outcome: {r['outcome']}"
        if "summary" not in r:
            return False, f"Worker result missing 'summary'"
    return True, "Schema: worker results valid"


def check_retry(events: list[dict], ticket_id: str = "TICKET-9902") -> tuple[bool, str]:
    """12. Retry logic: ticket fails then succeeds (mock mode)."""
    failed = False
    succeeded = False
    for e in events:
        if e.get("ticket") == ticket_id:
            if e.get("type") == "worker_failed":
                failed = True
            elif e.get("type") == "worker_done" and failed:
                succeeded = True
    if failed and succeeded:
        return True, f"Retry: {ticket_id} failed then succeeded"
    if not failed:
        return False, f"Retry: {ticket_id} never failed (injection may not be active)"
    return False, f"Retry: {ticket_id} failed but never succeeded"


def check_budget(state: dict, ceiling: float) -> tuple[bool, str]:
    """13. Budget tracking: total_cost_usd within ceiling."""
    cost = state.get("total_cost_usd", 0.0)
    ok = cost <= ceiling
    return ok, f"Budget within ceiling (${cost:.2f} <= ${ceiling:.2f})"


def check_cleanup(repo_root: Path) -> tuple[bool, str]:
    """14. Cleanup: no orphan state files after teardown."""
    test_dir = repo_root / "tickets" / "_test"
    if test_dir.exists():
        return False, f"Cleanup: tickets/_test/ still exists"
    return True, "Cleanup: no orphan files"
