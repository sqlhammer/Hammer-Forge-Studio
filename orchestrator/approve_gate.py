#!/usr/bin/env python3
"""approve_gate.py — Approve or reject a pending phase gate.

Usage:
    python orchestrator/approve_gate.py                          # auto-detect instance
    python orchestrator/approve_gate.py --instance t4            # explicit instance
    python orchestrator/approve_gate.py --reject                 # reject
    python orchestrator/approve_gate.py --comment "LGTM"         # approve with note
"""

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

from instance_paths import resolve_instance

ORCH_DIR = Path(__file__).resolve().parent


def _auto_detect_instance(orch_dir: Path) -> str:
    """Return the sole instance name, or exit if zero or multiple exist."""
    instances_dir = orch_dir / "instances"
    if not instances_dir.is_dir():
        print("Error: No instances directory found. Has the conductor been started?")
        sys.exit(1)

    dirs = [d.name for d in instances_dir.iterdir() if d.is_dir()]
    if len(dirs) == 0:
        print("Error: No instance directories found under orchestrator/instances/.")
        sys.exit(1)
    if len(dirs) == 1:
        return dirs[0]

    print("Error: Multiple instances found. Please specify one with --instance:")
    for name in sorted(dirs):
        print(f"  - {name}")
    sys.exit(1)


def main():
    parser = argparse.ArgumentParser(description="Approve or reject a phase gate")
    parser.add_argument(
        "--instance", type=str, default=None,
        help="Instance name (auto-detected when only one exists)")
    parser.add_argument("--reject", action="store_true", help="Reject the gate")
    parser.add_argument("--comment", type=str, default="", help="Optional comment")
    args = parser.parse_args()

    instance_name = args.instance or _auto_detect_instance(ORCH_DIR)
    paths = resolve_instance(instance_name, ORCH_DIR)

    if not paths.pending_gate_path.exists():
        print(f"No pending gate found ({paths.pending_gate_path} does not exist).")
        sys.exit(1)

    # Show gate info
    with open(paths.pending_gate_path, encoding="utf-8") as f:
        gate = json.load(f)

    print(f"Instance:   {instance_name}")
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

    with open(paths.gate_response_path, "w", encoding="utf-8") as f:
        json.dump(response, f, indent=2)

    print(f"Gate {action.upper()}ED. Response written to {paths.gate_response_path}.")
    print("The conductor will pick this up on its next poll cycle.")


if __name__ == "__main__":
    main()
