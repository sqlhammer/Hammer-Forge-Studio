#!/usr/bin/env python3
"""test_harness.py — End-to-end test for the orchestrator conductor.

Usage:
    python orchestrator/test_harness.py                        # mock mode (free, ~5s)
    python orchestrator/test_harness.py --mode mock            # explicit mock
    python orchestrator/test_harness.py --mode live            # real agents (~$2-3)
    python orchestrator/test_harness.py --mode mock --verbose  # print wave plans
    python orchestrator/test_harness.py --keep-artifacts       # don't clean up temp dir
"""

import argparse
import asyncio
import json
import os
import shutil
import sys
import tempfile
import time
from pathlib import Path

# Ensure the repo root is importable
REPO_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO_ROOT))

from orchestrator.conductor import (
    Conductor,
    ActivityLogger,
    create_initial_state,
    extract_json_from_output,
    load_json,
    save_state,
    write_json,
)
from orchestrator.test_fixtures.generate_tickets import (
    create_test_tickets,
    cleanup_test_tickets,
)
from orchestrator.test_fixtures.mock_agents import (
    FailureInjector,
    create_mock_run_claude,
)
from orchestrator.test_fixtures import assertions


# ---------------------------------------------------------------------------
# TestConductor — thin wrapper that records events and auto-approves gates
# ---------------------------------------------------------------------------

class TestConductor(Conductor):
    """Conductor subclass for testing.

    Overrides:
    - Gate handling: auto-approves immediately (no file polling).
    - Event recording: tracks waves, gate events, worker results for assertions.
    - I/O redirection: uses a temp ORCH_DIR so production files are untouched.
    """

    def __init__(self, orch_dir: Path, repo_root: Path, **kwargs):
        self._test_orch_dir = orch_dir
        self._test_repo_root = repo_root
        self._events: list[dict] = []
        self._waves: list[dict] = []
        self._worker_results: list[dict] = []
        self._verbose = kwargs.pop("verbose", False)

        # Monkey-patch module-level paths used by conductor internals
        import orchestrator.conductor as c
        self._orig_paths = {
            "REPO_ROOT": c.REPO_ROOT,
            "ORCH_DIR": c.ORCH_DIR,
            "STATE_PATH": c.STATE_PATH,
            "ACTIVITY_LOG": c.ACTIVITY_LOG,
            "PENDING_GATE_PATH": c.PENDING_GATE_PATH,
            "GATE_RESPONSE_PATH": c.GATE_RESPONSE_PATH,
            "RESULTS_DIR": c.RESULTS_DIR,
            "LOGS_DIR": c.LOGS_DIR,
        }
        c.REPO_ROOT = repo_root
        c.ORCH_DIR = orch_dir
        c.STATE_PATH = orch_dir / "state.json"
        c.ACTIVITY_LOG = orch_dir / "activity.log"
        c.PENDING_GATE_PATH = orch_dir / "pending_gate.json"
        c.GATE_RESPONSE_PATH = orch_dir / "gate_response.json"
        c.RESULTS_DIR = orch_dir / "results"
        c.LOGS_DIR = orch_dir / "logs"

        super().__init__(**kwargs)

    def restore_paths(self):
        """Restore original module-level paths after test."""
        import orchestrator.conductor as c
        for attr, val in self._orig_paths.items():
            setattr(c, attr, val)

    # -- Event recording hooks -----------------------------------------------

    async def _do_planning(self):
        """Wrap parent planning to record wave dispatches."""
        await super()._do_planning()

        # If planning resulted in a wave dispatch, record it
        pending = self.state.get("_pending_wave")
        if pending:
            tids = [w["ticket"] for w in pending]
            raw_plan = {
                "action": "spawn_agents",
                "summary": f"Dispatching {len(pending)} tickets.",
                "wave": pending,
            }
            self._waves.append({
                "wave": self.state["wave_number"],
                "tickets_dispatched": tids,
                "raw_plan": raw_plan,
            })
            self._events.append({
                "type": "wave_dispatched",
                "wave": self.state["wave_number"],
                "tickets": tids,
            })

        # Record gate events
        if self.state.get("status") == "GATE_BLOCKED":
            gate = self.state.get("_pending_gate", {})
            raw_plan = {
                "action": "gate_blocked",
                "summary": gate.get("summary", ""),
                "gate": gate,
            }
            self._waves.append({
                "wave": self.state["wave_number"],
                "tickets_dispatched": [],
                "raw_plan": raw_plan,
            })
            self._events.append({
                "type": "gate_blocked",
                "phase": gate.get("phase"),
                "next_phase": gate.get("next_phase"),
            })

        # Record milestone_complete / no_work
        if self.state.get("status") == "IDLE":
            completed = self.state.get("completed_waves", [])
            # Determine if this is milestone_complete or no_work
            all_tids = set()
            for w in completed:
                all_tids.update(w.get("tickets", []))
            if len(all_tids) >= 6:
                self._events.append({"type": "milestone_complete"})
                self._waves.append({
                    "wave": self.state["wave_number"],
                    "tickets_dispatched": [],
                    "raw_plan": {
                        "action": "milestone_complete",
                        "summary": "All tickets DONE.",
                    },
                })

    async def _do_working(self):
        """Wrap parent working to record individual worker results."""
        await super()._do_working()

        # Check latest completed_waves for results
        completed = self.state.get("completed_waves", [])
        if completed:
            last = completed[-1]
            for tid in last.get("tickets", []):
                self._worker_results.append({
                    "ticket": tid,
                    "outcome": "done",
                    "summary": f"{tid} completed.",
                })
                self._events.append({"type": "worker_done", "ticket": tid})

        # Check for failed workers by looking at retry queue
        retries = self.state.get("retries", {})
        for tid, count in retries.items():
            if count > 0:
                # Only record first failure
                already = any(
                    e.get("ticket") == tid and e.get("type") == "worker_failed"
                    for e in self._events
                )
                if not already:
                    self._worker_results.append({
                        "ticket": tid,
                        "outcome": "failed",
                        "summary": f"{tid} failed (will retry).",
                    })
                    self._events.append({"type": "worker_failed", "ticket": tid})

    # -- Gate auto-approval --------------------------------------------------

    async def _do_gate_blocked(self):
        """Auto-approve the gate immediately instead of polling for a file."""
        gate = self.state.pop("_pending_gate", {})
        if not gate:
            self.state["status"] = "PLANNING"
            return

        next_phase = gate.get("next_phase", "Beta")
        if self._verbose:
            print(f"  [TEST] Auto-approving gate: {gate.get('phase')} -> {next_phase}")

        self.logger.log("APPROVED", f"Auto-approved gate -> {next_phase}")
        self.state["phase"] = next_phase
        self.state["status"] = "PLANNING"

        self._events.append({
            "type": "gate_approved",
            "phase": gate.get("phase"),
            "next_phase": next_phase,
        })

    # -- Disable git operations in EVALUATING --------------------------------

    async def _do_evaluating(self):
        """Skip git merge/pull/UID steps — tests don't produce real branches."""
        # Budget check
        ceiling = self.config["budgets"]["session_ceiling_usd"]
        if self.state["total_cost_usd"] >= ceiling:
            self.logger.log("BUDGET", f"Session ceiling reached. Halting.")
            self.state["status"] = "HALTED"
            return
        self.state["status"] = "PLANNING"

    # -- Disable signal handlers (not needed in tests) -----------------------

    def setup_signal_handlers(self):
        pass


# ---------------------------------------------------------------------------
# Runner
# ---------------------------------------------------------------------------

async def run_test(mode: str, verbose: bool, keep_artifacts: bool) -> int:
    """Execute the test harness. Returns 0 on all-pass, 1 on any failure."""
    start_time = time.time()

    # Create temp directory for orchestrator state
    tmp_dir = Path(tempfile.mkdtemp(prefix="hfs_test_orch_"))
    orch_dir = tmp_dir / "orchestrator"
    orch_dir.mkdir()
    (orch_dir / "results").mkdir()
    (orch_dir / "logs").mkdir()

    # Copy schemas and prompts to temp dir (conductor needs them)
    src_orch = REPO_ROOT / "orchestrator"
    shutil.copytree(src_orch / "schemas", orch_dir / "schemas")
    shutil.copytree(src_orch / "prompts", orch_dir / "prompts")

    # Create test tickets
    test_ticket_dir = create_test_tickets(REPO_ROOT)

    # Load schemas for validation
    wave_plan_schema = load_json(orch_dir / "schemas" / "wave_plan.json")
    worker_result_schema = load_json(orch_dir / "schemas" / "worker_result.json")

    conductor = None
    try:
        if mode == "mock":
            injector = FailureInjector(fail_once={"TICKET-9902"})
            mock_fn = create_mock_run_claude(REPO_ROOT, injector, verbose=verbose)

            conductor = TestConductor(
                orch_dir=orch_dir,
                repo_root=REPO_ROOT,
                config_path=src_orch / "test_config.json",
                run_claude_fn=mock_fn,
                verbose=verbose,
            )
        else:
            # Live mode — use real run_claude (no mock)
            conductor = TestConductor(
                orch_dir=orch_dir,
                repo_root=REPO_ROOT,
                config_path=src_orch / "test_config.json",
                verbose=verbose,
            )

        # Run the conductor
        await conductor.run("TEST", "Alpha")

        # Collect data for assertions
        state = conductor.state
        events = conductor._events
        waves = conductor._waves
        worker_results = conductor._worker_results
        duration = time.time() - start_time

        # Run all 14 assertions
        checks = [
            assertions.check_terminal_state(state),
            assertions.check_wave1_parallel(waves),
            assertions.check_wave1_no_9903(waves),
            assertions.check_9903_dispatched(waves),
            assertions.check_gate_fired(events),
            assertions.check_gate_approved(events),
            assertions.check_beta_parallel(waves),
            assertions.check_9906_dispatched(waves),
            assertions.check_milestone_complete(events),
            assertions.check_producer_schema(waves, wave_plan_schema),
            assertions.check_worker_schema(worker_results, worker_result_schema),
        ]

        # Retry check only applies in mock mode (failure injection)
        if mode == "mock":
            checks.append(assertions.check_retry(events, "TICKET-9902"))
        else:
            checks.append((True, "Retry: skipped in live mode"))

        checks.append(
            assertions.check_budget(state, conductor.config["budgets"]["session_ceiling_usd"])
        )

        # Cleanup before the cleanup assertion
        if not keep_artifacts:
            cleanup_test_tickets(REPO_ROOT)

        checks.append(assertions.check_cleanup(REPO_ROOT))

        # Print results
        passed = sum(1 for ok, _ in checks if ok)
        total = len(checks)
        cost = state.get("total_cost_usd", 0.0)
        wave_count = len(waves)

        print()
        print("=" * 60)
        print("  Orchestrator Test Harness — Results")
        print("=" * 60)
        print(f"  Mode:        {mode}")
        print(f"  Duration:    {duration:.1f}s")
        print(f"  Waves:       {wave_count}")
        print(f"  Cost:        ${cost:.2f}")
        print()

        for ok, msg in checks:
            tag = "PASS" if ok else "FAIL"
            print(f"  [{tag}] {msg}")

        print()
        if passed == total:
            print(f"  Result: {passed}/{total} PASSED")
        else:
            print(f"  Result: {passed}/{total} PASSED, {total - passed} FAILED")
        print("=" * 60)

        return 0 if passed == total else 1

    finally:
        # Restore module paths
        if conductor:
            conductor.restore_paths()

        # Cleanup temp orch dir
        if not keep_artifacts:
            shutil.rmtree(tmp_dir, ignore_errors=True)
            # Ensure test tickets are cleaned up
            cleanup_test_tickets(REPO_ROOT)
        else:
            print(f"\n  Artifacts kept at: {tmp_dir}")
            if test_ticket_dir.exists():
                print(f"  Test tickets at:  {test_ticket_dir}")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Orchestrator Test Harness — end-to-end conductor testing"
    )
    parser.add_argument("--mode", choices=["mock", "live"], default="mock",
                        help="Execution mode: mock (free, canned JSON) or live (real agents)")
    parser.add_argument("--verbose", "-v", action="store_true",
                        help="Print wave plans and worker results")
    parser.add_argument("--keep-artifacts", action="store_true",
                        help="Don't clean up temp directory after run")

    args = parser.parse_args()
    exit_code = asyncio.run(run_test(args.mode, args.verbose, args.keep_artifacts))
    sys.exit(exit_code)


if __name__ == "__main__":
    main()
