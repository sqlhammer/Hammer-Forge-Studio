#!/usr/bin/env python3
"""resume_planning.py — Reset an IDLE orchestrator back to PLANNING so it picks up new tickets.

Usage:
    python orchestrator/resume_planning.py
    python orchestrator/resume_planning.py --force   # skip confirmation prompt
"""

import argparse
import json
import sys
from pathlib import Path

ORCH_DIR = Path(__file__).resolve().parent
STATE_FILE = ORCH_DIR / "state.json"


def main():
    parser = argparse.ArgumentParser(
        description="Reset an IDLE orchestrator to PLANNING so it detects new tickets"
    )
    parser.add_argument(
        "--force", action="store_true", help="Skip confirmation prompt"
    )
    args = parser.parse_args()

    if not STATE_FILE.exists():
        print("Error: orchestrator/state.json not found — has the conductor been run yet?")
        sys.exit(1)

    with open(STATE_FILE, encoding="utf-8") as f:
        state = json.load(f)

    current_status = state.get("status", "UNKNOWN")
    milestone = state.get("milestone", "?")
    phase = state.get("phase", "?")

    print(f"Milestone:      {milestone}")
    print(f"Phase:          {phase}")
    print(f"Current status: {current_status}")
    print()

    if current_status != "IDLE":
        print(f"Orchestrator is not IDLE (status={current_status}) — no change needed.")
        sys.exit(0)

    if not args.force:
        confirm = input("Reset status IDLE → PLANNING? [y/N] ").strip().lower()
        if confirm != "y":
            print("Aborted.")
            sys.exit(0)

    state["status"] = "PLANNING"

    with open(STATE_FILE, "w", encoding="utf-8") as f:
        json.dump(state, f, indent=2)

    print("Status set to PLANNING. Run the conductor to pick up new tickets:")
    print(f"    python orchestrator/conductor.py {milestone}")


if __name__ == "__main__":
    main()
