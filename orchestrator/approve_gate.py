#!/usr/bin/env python3
"""approve_gate.py — Approve or reject a pending phase gate.

Usage:
    python orchestrator/approve_gate.py                   # approve (default)
    python orchestrator/approve_gate.py --reject          # reject
    python orchestrator/approve_gate.py --comment "LGTM"  # approve with note
"""

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

ORCH_DIR = Path(__file__).resolve().parent
PENDING_GATE = ORCH_DIR / "pending_gate.json"
GATE_RESPONSE = ORCH_DIR / "gate_response.json"


def main():
    parser = argparse.ArgumentParser(description="Approve or reject a phase gate")
    parser.add_argument("--reject", action="store_true", help="Reject the gate")
    parser.add_argument("--comment", type=str, default="", help="Optional comment")
    args = parser.parse_args()

    if not PENDING_GATE.exists():
        print("No pending gate found (orchestrator/pending_gate.json does not exist).")
        sys.exit(1)

    # Show gate info
    with open(PENDING_GATE, encoding="utf-8") as f:
        gate = json.load(f)

    print(f"Milestone:  {gate.get('milestone', '?')}")
    print(f"Phase:      {gate.get('phase', '?')}")
    print(f"Next phase: {gate.get('next_phase', '?')}")
    print(f"Summary:    {gate.get('summary', '')}")
    print(f"Requested:  {gate.get('requested_at', '?')}")
    print()

    action = "reject" if args.reject else "approve"
    response = {
        "action": action,
        "comment": args.comment,
        "responded_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S"),
    }

    with open(GATE_RESPONSE, "w", encoding="utf-8") as f:
        json.dump(response, f, indent=2)

    print(f"Gate {action.upper()}ED. Response written to {GATE_RESPONSE}.")
    print("The conductor will pick this up on its next poll cycle.")


if __name__ == "__main__":
    main()
