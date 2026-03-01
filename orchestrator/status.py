#!/usr/bin/env python3
"""status.py — Display current orchestrator state.

Usage:
    python orchestrator/status.py
    python orchestrator/status.py --json
    python orchestrator/status.py --instance <name>
    python orchestrator/status.py --all
"""

import argparse
import json
import sys
from pathlib import Path

from instance_paths import resolve_instance


ORCH_DIR = Path(__file__).resolve().parent


def format_cost(usd: float) -> str:
    return f"${usd:.2f}"


def _discover_instances() -> list[str]:
    """Return sorted list of instance names that have a state.json file."""
    instances_dir = ORCH_DIR / "instances"
    if not instances_dir.is_dir():
        return []
    return sorted(
        d.name
        for d in instances_dir.iterdir()
        if d.is_dir() and (d / "state.json").exists()
    )


def _load_state(state_path: Path) -> dict | None:
    """Load and return state dict, or None if file missing."""
    if not state_path.exists():
        return None
    with open(state_path, encoding="utf-8") as f:
        return json.load(f)


def _print_one_line_summary(instance_name: str, state: dict) -> None:
    """Print a single-line summary for --all output."""
    milestone = state.get("milestone", "?")
    phase = state.get("phase", "?")
    wave = state.get("wave_number", 0)

    # Count tickets from completed waves + active workers
    completed_tickets = sum(
        len(w.get("tickets", []))
        for w in state.get("completed_waves", [])
    )
    active_tickets = len(state.get("active_workers", []))
    total_tickets = completed_tickets + active_tickets

    print(
        f"  {instance_name:<12}  {milestone:<6}|  Phase: {phase:<16}|"
        f"  Wave: {wave:<4}|  Tickets: {completed_tickets}/{total_tickets} done"
    )


def _print_full_status(instance_name: str, paths, state: dict, args) -> None:
    """Print full status display for a single instance (preserves original format)."""
    if args.as_json:
        print(json.dumps(state, indent=2))
        return

    print("=" * 50)
    print("  Hammer Forge Studio — Orchestrator Status")
    print("=" * 50)
    print()
    print(f"  Instance:   {instance_name}")
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
    if paths.pending_gate_path.exists():
        with open(paths.pending_gate_path, encoding="utf-8") as f:
            gate = json.load(f)
        print("  ** PENDING GATE **")
        print(f"    Phase:      {gate.get('phase', '?')}")
        print(f"    Next phase: {gate.get('next_phase', '?')}")
        print(f"    Summary:    {gate.get('summary', '')}")
        print(f"    Run: python orchestrator/approve_gate.py")
        print()

    # Activity log tail
    if args.log > 0 and paths.activity_log.exists():
        print(f"  Last {args.log} log entries:")
        lines = paths.activity_log.read_text(encoding="utf-8").splitlines()
        for line in lines[-args.log:]:
            print(f"    {line}")
        print()


def main():
    parser = argparse.ArgumentParser(description="Show orchestrator status")
    parser.add_argument("--json", action="store_true", dest="as_json",
        help="Output raw JSON state")
    parser.add_argument("--log", type=int, default=0, metavar="N",
        help="Show last N lines of activity log")
    parser.add_argument("--instance", type=str, default=None, metavar="NAME",
        help="Target a specific instance by name")
    parser.add_argument("--all", action="store_true", dest="show_all",
        help="List all instances with a one-line summary each")
    args = parser.parse_args()

    # --all mode: list every instance with a summary line
    if args.show_all:
        instances = _discover_instances()
        if not instances:
            print("No instances found. Run start_milestone.py first.")
            sys.exit(0)
        print("=" * 50)
        print("  Hammer Forge Studio — All Instances")
        print("=" * 50)
        print()
        for name in instances:
            paths = resolve_instance(name, orch_dir=ORCH_DIR)
            state = _load_state(paths.state_path)
            if state:
                _print_one_line_summary(name, state)
        print()
        return

    # Determine which instance to show
    if args.instance:
        instance_name = args.instance
    else:
        # Auto-detect
        instances = _discover_instances()
        if len(instances) == 0:
            print("No instances found. Run start_milestone.py first.")
            sys.exit(0)
        elif len(instances) == 1:
            instance_name = instances[0]
        else:
            print(f"Multiple instances found ({len(instances)}):")
            for name in instances:
                print(f"  - {name}")
            print()
            print("Specify one with --instance <name>, or use --all for a summary.")
            sys.exit(0)

    # Single-instance view
    paths = resolve_instance(instance_name, orch_dir=ORCH_DIR)
    state = _load_state(paths.state_path)
    if state is None:
        print(f"No orchestrator state found for instance '{instance_name}'.")
        print("The conductor has not been started for this instance.")
        sys.exit(0)

    _print_full_status(instance_name, paths, state, args)


if __name__ == "__main__":
    main()
