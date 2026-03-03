#!/usr/bin/env python3
"""approve_gate.py — Approve a phase gate by writing gate_response.json.

Usage:
    python orchestrator/approve_gate.py                  # auto-detect instance, confirm first
    python orchestrator/approve_gate.py --force          # skip confirmation prompt
    python orchestrator/approve_gate.py --instance M11  # target a specific instance

Reads pending_gate.json from the instance directory, displays gate details,
and writes gate_response.json with the next_phase value. The conductor polls
for gate_response.json every 30 seconds and advances to PLANNING once found.
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
        description="Approve a phase gate by writing gate_response.json"
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

    if not paths.pending_gate_path.exists():
        print(f"Error: {paths.pending_gate_path} not found — instance is not GATE_BLOCKED.")
        sys.exit(1)

    with open(paths.pending_gate_path, encoding="utf-8") as f:
        gate = json.load(f)

    milestone = gate.get("milestone", "?")
    phase = gate.get("phase", "?")
    next_phase = gate.get("next_phase", "?")
    requested_at = gate.get("requested_at", "?")

    print(f"Instance:       {instance_name}")
    print(f"Milestone:      {milestone}")
    print(f"Current phase:  {phase}")
    print(f"Next phase:     {next_phase}")
    print(f"Gate requested: {requested_at}")
    print()

    if not args.force:
        confirm = input(f"Approve gate and advance to '{next_phase}'? [y/N] ").strip().lower()
        if confirm != "y":
            print("Aborted.")
            sys.exit(0)

    with open(paths.gate_response_path, "w", encoding="utf-8") as f:
        json.dump({"next_phase": next_phase}, f)

    print(f"gate_response.json written. Conductor will advance to '{next_phase}' within 30 seconds.")


if __name__ == "__main__":
    main()
