#!/usr/bin/env python3
"""start_milestone.py — Initialize orchestrator state for a new milestone.

Writes a fresh state.json into the instance directory so the conductor starts
clean rather than resuming a previous milestone's state. Run this before
launching the conductor whenever beginning a new milestone.

Usage:
    python orchestrator/start_milestone.py M8
    python orchestrator/start_milestone.py M8 "TDD Foundation"   # specify starting phase
    python orchestrator/start_milestone.py M8 --instance my-run  # custom instance name
    python orchestrator/start_milestone.py M8 --force            # skip confirmation
"""

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

from instance_paths import resolve_instance

REPO_ROOT = Path(__file__).resolve().parent.parent


def now_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S")


def create_initial_state(milestone: str, phase: str) -> dict:
    return {
        "status": "PLANNING",
        "milestone": milestone,
        "phase": phase,
        "wave_number": 0,
        "started_at": now_iso(),
        "active_workers": [],
        "active_ticket_ids": [],
        "completed_waves": [],
        "completed_this_session": [],
        "total_cost_usd": 0.0,
        "retries": {},
    }


def main():
    parser = argparse.ArgumentParser(
        description="Initialize orchestrator state for a new milestone"
    )
    parser.add_argument("milestone", help="Milestone ID (e.g. M8)")
    parser.add_argument(
        "phase",
        nargs="?",
        default="",
        help="Starting phase name (optional — conductor auto-detects if omitted)",
    )
    parser.add_argument(
        "--instance",
        default=None,
        help="Instance name (defaults to the milestone ID)",
    )
    parser.add_argument(
        "--force", action="store_true", help="Skip confirmation prompt"
    )
    args = parser.parse_args()

    milestone = args.milestone.upper()
    phase = args.phase
    instance_name = args.instance if args.instance else milestone

    # Validate that the milestone directory exists under tickets/
    milestone_dir = REPO_ROOT / "tickets" / milestone
    if not milestone_dir.is_dir():
        print(f"Error: milestone directory not found: {milestone_dir}")
        sys.exit(1)

    # Resolve instance paths (creates instance_dir, results/, logs/ automatically)
    paths = resolve_instance(instance_name)
    state_file = paths.state_path

    # Warn if existing state will be overwritten
    if state_file.exists():
        with open(state_file, encoding="utf-8") as f:
            existing = json.load(f)
        existing_milestone = existing.get("milestone", "?")
        existing_status = existing.get("status", "?")

        if existing_milestone == milestone:
            print(f"Warning: state.json already exists for {milestone} (status={existing_status}).")
            print("This will reset all progress for this milestone.")
        else:
            print(f"Existing state: milestone={existing_milestone}, status={existing_status}")
            print(f"Replacing with fresh state for {milestone}.")

        print()

    if not args.force:
        confirm = input(f"Initialize fresh state for {milestone}? [y/N] ").strip().lower()
        if confirm != "y":
            print("Aborted.")
            sys.exit(0)

    state = create_initial_state(milestone, phase)

    with open(state_file, "w", encoding="utf-8") as f:
        json.dump(state, f, indent=2)

    phase_display = f", phase={phase!r}" if phase else " (phase auto-detected by conductor)"
    print(f"State initialized: milestone={milestone}{phase_display}, status=PLANNING")
    print(f"Run the conductor to begin:")
    print(f"    python orchestrator/conductor.py {milestone} --instance {instance_name}")


if __name__ == "__main__":
    main()
