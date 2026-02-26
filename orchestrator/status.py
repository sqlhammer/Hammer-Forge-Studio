#!/usr/bin/env python3
"""status.py — Display current orchestrator state.

Usage:
    python orchestrator/status.py
    python orchestrator/status.py --json
"""

import argparse
import json
import sys
from pathlib import Path

ORCH_DIR = Path(__file__).resolve().parent
STATE_PATH = ORCH_DIR / "state.json"
PENDING_GATE = ORCH_DIR / "pending_gate.json"
ACTIVITY_LOG = ORCH_DIR / "activity.log"


def format_cost(usd: float) -> str:
    return f"${usd:.2f}"


def main():
    parser = argparse.ArgumentParser(description="Show orchestrator status")
    parser.add_argument("--json", action="store_true", dest="as_json",
        help="Output raw JSON state")
    parser.add_argument("--log", type=int, default=0, metavar="N",
        help="Show last N lines of activity log")
    args = parser.parse_args()

    if not STATE_PATH.exists():
        print("No orchestrator state found. The conductor has not been started.")
        sys.exit(0)

    with open(STATE_PATH, encoding="utf-8") as f:
        state = json.load(f)

    if args.as_json:
        print(json.dumps(state, indent=2))
        return

    # Pretty print
    print("=" * 50)
    print("  Hammer Forge Studio — Orchestrator Status")
    print("=" * 50)
    print()
    print(f"  Status:     {state.get('status', '?')}")
    print(f"  Milestone:  {state.get('milestone', '?')}")
    print(f"  Phase:      {state.get('phase', '?')}")
    print(f"  Wave:       {state.get('wave_number', 0)}")
    print(f"  Started:    {state.get('started_at', '?')}")
    print(f"  Total cost: {format_cost(state.get('total_cost_usd', 0))}")
    print()

    # Active workers
    workers = state.get("active_workers", [])
    if workers:
        print(f"  Active workers ({len(workers)}):")
        for w in workers:
            print(f"    - {w.get('agent', '?')} -> {w.get('ticket', '?')}"
                  f" (budget={format_cost(w.get('budget_usd', 0))})")
        print()

    # Completed waves
    waves = state.get("completed_waves", [])
    if waves:
        print(f"  Completed waves ({len(waves)}):")
        for w in waves:
            tickets = ", ".join(w.get("tickets", []))
            print(f"    Wave {w.get('wave', '?')}: [{tickets}]"
                  f" at {w.get('completed_at', '?')}")
        print()

    # Retries
    retries = state.get("retries", {})
    if retries:
        print("  Retries:")
        for tid, count in retries.items():
            print(f"    {tid}: {count} attempt(s)")
        print()

    # Pending gate
    if PENDING_GATE.exists():
        with open(PENDING_GATE, encoding="utf-8") as f:
            gate = json.load(f)
        print("  ** PENDING GATE **")
        print(f"    Phase:      {gate.get('phase', '?')}")
        print(f"    Next phase: {gate.get('next_phase', '?')}")
        print(f"    Summary:    {gate.get('summary', '')}")
        print(f"    Run: python orchestrator/approve_gate.py")
        print()

    # Activity log tail
    if args.log > 0 and ACTIVITY_LOG.exists():
        print(f"  Last {args.log} log entries:")
        lines = ACTIVITY_LOG.read_text(encoding="utf-8").splitlines()
        for line in lines[-args.log:]:
            print(f"    {line}")
        print()


if __name__ == "__main__":
    main()
