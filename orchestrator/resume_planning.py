#!/usr/bin/env python3
"""resume_planning.py — Reset an IDLE orchestrator back to PLANNING so it picks up new tickets.

Usage:
    python orchestrator/resume_planning.py --instance <name>
    python orchestrator/resume_planning.py --force   # skip confirmation prompt

If only one instance exists under orchestrator/instances/, it is selected
automatically.  When multiple instances exist, --instance is required.
"""

import argparse
import json
import sys
from pathlib import Path

from instance_paths import resolve_instance

ORCH_DIR = Path(__file__).resolve().parent
INSTANCES_DIR = ORCH_DIR / "instances"


def _detect_instance(explicit: str | None) -> str:
    """Return the instance name to use, or exit with an error message."""
    if explicit:
        return explicit

    if not INSTANCES_DIR.is_dir():
        print("Error: No instances directory found. Has the conductor been run yet?")
        sys.exit(1)

    instances = [d.name for d in INSTANCES_DIR.iterdir() if d.is_dir()]

    if len(instances) == 0:
        print("Error: No instance directories found under orchestrator/instances/.")
        sys.exit(1)

    if len(instances) == 1:
        return instances[0]

    print("Error: Multiple instances found. Specify one with --instance <name>:")
    for name in sorted(instances):
        print(f"  - {name}")
    sys.exit(1)


def main():
    parser = argparse.ArgumentParser(
        description="Reset an IDLE orchestrator to PLANNING so it detects new tickets"
    )
    parser.add_argument(
        "--instance", type=str, default=None,
        help="Instance name (auto-detected when only one exists)"
    )
    parser.add_argument(
        "--force", action="store_true", help="Skip confirmation prompt"
    )
    args = parser.parse_args()

    instance_name = _detect_instance(args.instance)
    paths = resolve_instance(instance_name)

    if not paths.state_path.exists():
        print(f"Error: {paths.state_path} not found — has the conductor been run yet?")
        sys.exit(1)

    with open(paths.state_path, encoding="utf-8") as f:
        state = json.load(f)

    current_status = state.get("status", "UNKNOWN")
    milestone = state.get("milestone", "?")
    phase = state.get("phase", "?")

    print(f"Instance:       {instance_name}")
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

    with open(paths.state_path, "w", encoding="utf-8") as f:
        json.dump(state, f, indent=2)

    print("Status set to PLANNING. Run the conductor to pick up new tickets:")
    print(f"    python orchestrator/conductor.py {milestone}")


if __name__ == "__main__":
    main()
