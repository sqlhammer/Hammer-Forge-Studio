#!/usr/bin/env python3
"""test_usage_limit.py — Unit tests for usage-limit detection and LIMIT_WAIT state.

Tests:
  1. _detect_usage_limit returns True when stderr contains "rate limit"
  2. When >= mass_threshold_pct% of workers fail with usage limit, conductor
     enters LIMIT_WAIT instead of queuing individual implementation_failure retries.

Usage:
    python orchestrator/test_usage_limit.py
"""

import asyncio
import json
import os
import shutil
import sys
import tempfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO_ROOT))

from orchestrator.conductor import Conductor, ActivityLogger, create_initial_state, save_state
from orchestrator.instance_paths import InstancePaths, load_config
from orchestrator.test_fixtures.generate_tickets import create_test_tickets, cleanup_test_tickets


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _make_paths(orch_dir: Path) -> InstancePaths:
    return InstancePaths(
        orch_dir=orch_dir,
        instance_dir=orch_dir,
        config_path=REPO_ROOT / "orchestrator" / "test_config.json",
        config_local_path=orch_dir / "config.local.json",
        state_path=orch_dir / "state.json",
        activity_log=orch_dir / "activity.log",
        pending_gate_path=orch_dir / "pending_gate.json",
        gate_response_path=orch_dir / "gate_response.json",
        godot_mcp_lock_path=orch_dir / "godot_mcp.lock",
        results_dir=orch_dir / "results",
        logs_dir=orch_dir / "logs",
        prompts_dir=REPO_ROOT / "orchestrator" / "prompts",
        schemas_dir=REPO_ROOT / "orchestrator" / "schemas",
    )


def _make_conductor(orch_dir: Path) -> Conductor:
    paths = _make_paths(orch_dir)
    config = load_config(paths)
    conductor = Conductor(paths=paths, config=config)
    conductor.state = create_initial_state("_test", "Alpha")
    return conductor


# ---------------------------------------------------------------------------
# Test 1 — _detect_usage_limit keyword detection
# ---------------------------------------------------------------------------

def test_detect_usage_limit_rate_limit_in_stderr() -> tuple[bool, str]:
    """_detect_usage_limit returns True when stderr contains 'rate limit'."""
    result = Conductor._detect_usage_limit(
        exit_code=1,
        stdout="",
        stderr="Error: rate limit exceeded for your account.",
    )
    if result:
        return True, "_detect_usage_limit: 'rate limit' in stderr ->True"
    return False, "_detect_usage_limit: 'rate limit' in stderr returned False (expected True)"


def test_detect_usage_limit_various_keywords() -> tuple[bool, str]:
    """_detect_usage_limit returns True for all specified keywords."""
    keywords_and_text = [
        ("rate_limit", "rate_limit hit"),
        ("usage limit", "You have hit your usage limit."),
        ("usage_limit", "usage_limit=exceeded"),
        ("capacity", "Over capacity, please try again"),
        ("exceeded", "quota exceeded"),
        ("too many requests", "Too many requests from your IP"),
        ("429", "HTTP 429 Too Many Requests"),
        ("quota", "Your quota has been used up"),
    ]
    for keyword, text in keywords_and_text:
        result = Conductor._detect_usage_limit(exit_code=1, stdout="", stderr=text)
        if not result:
            return False, f"_detect_usage_limit: keyword '{keyword}' not detected in '{text}'"
    return True, f"_detect_usage_limit: all {len(keywords_and_text)} keywords detected correctly"


def test_detect_usage_limit_empty_stdout_exit0() -> tuple[bool, str]:
    """_detect_usage_limit returns True for exit_code=0 with empty stdout."""
    result = Conductor._detect_usage_limit(exit_code=0, stdout="", stderr="")
    if result:
        return True, "_detect_usage_limit: exit=0 + empty stdout ->True"
    return False, "_detect_usage_limit: exit=0 + empty stdout returned False (expected True)"


def test_detect_usage_limit_normal_failure() -> tuple[bool, str]:
    """_detect_usage_limit returns False for normal non-limit failures."""
    result = Conductor._detect_usage_limit(
        exit_code=1,
        stdout="",
        stderr="FileNotFoundError: /some/path not found",
    )
    if not result:
        return True, "_detect_usage_limit: normal failure ->False (correct)"
    return False, "_detect_usage_limit: normal failure incorrectly returned True"


# ---------------------------------------------------------------------------
# Test 2 — Mass usage-limit threshold triggers LIMIT_WAIT
# ---------------------------------------------------------------------------

async def test_mass_usage_limit_enters_limit_wait() -> tuple[bool, str]:
    """5 of 8 workers fail with usage limit ->conductor enters LIMIT_WAIT."""
    tmp_dir = Path(tempfile.mkdtemp(prefix="hfs_test_limit_wait_"))
    orch_dir = tmp_dir / "orchestrator"
    orch_dir.mkdir()
    (orch_dir / "results").mkdir()
    (orch_dir / "logs").mkdir()

    import orchestrator.conductor as c
    orig_repo_root = c.REPO_ROOT
    orig_orch_dir = c.ORCH_DIR
    c.REPO_ROOT = REPO_ROOT
    c.ORCH_DIR = orch_dir

    try:
        conductor = _make_conductor(orch_dir)

        # Simulate 8 workers: 5 fail with usage limit, 3 fail normally
        # We call _do_working indirectly by populating active_workers and
        # injecting a mock _run_worker that returns preset results.

        rate_limit_stderr = "Error: rate limit exceeded"
        normal_stderr = "Script error: something went wrong"

        # Build fake workers
        workers = [{"agent": f"agent-{i}", "ticket": f"TICKET-900{i}",
                    "budget_usd": 0.5, "needs_worktree": False, "needs_godot_mcp": False}
                   for i in range(8)]
        conductor.state["active_workers"] = workers
        conductor.state["active_ticket_ids"] = [w["ticket"] for w in workers]

        # Override _run_worker to return controlled results
        async def mock_run_worker(worker):
            idx = int(worker["agent"].split("-")[1])
            if idx < 5:
                # Usage-limit failure (exit=0, empty stdout — the silent exit pattern)
                return (0, "", "", {})
            else:
                # Normal failure (exit=1, non-limit stderr)
                return (1, "", normal_stderr, {})

        conductor._run_worker = mock_run_worker

        await conductor._do_working()

        if conductor.state.get("status") == "LIMIT_WAIT":
            return True, "Mass usage-limit (5/8 = 62.5% >= 50%): conductor entered LIMIT_WAIT"
        else:
            status = conductor.state.get("status", "?")
            return False, f"Mass usage-limit: expected LIMIT_WAIT, got {status}"
    finally:
        c.REPO_ROOT = orig_repo_root
        c.ORCH_DIR = orig_orch_dir
        shutil.rmtree(tmp_dir, ignore_errors=True)


async def test_below_threshold_does_not_enter_limit_wait() -> tuple[bool, str]:
    """3 of 8 workers fail with usage limit (below 50%) ->stays in EVALUATING."""
    tmp_dir = Path(tempfile.mkdtemp(prefix="hfs_test_no_limit_wait_"))
    orch_dir = tmp_dir / "orchestrator"
    orch_dir.mkdir()
    (orch_dir / "results").mkdir()
    (orch_dir / "logs").mkdir()

    import orchestrator.conductor as c
    orig_repo_root = c.REPO_ROOT
    orig_orch_dir = c.ORCH_DIR
    c.REPO_ROOT = REPO_ROOT
    c.ORCH_DIR = orch_dir

    try:
        conductor = _make_conductor(orch_dir)

        workers = [{"agent": f"agent-{i}", "ticket": f"TICKET-910{i}",
                    "budget_usd": 0.5, "needs_worktree": False, "needs_godot_mcp": False}
                   for i in range(8)]
        conductor.state["active_workers"] = workers
        conductor.state["active_ticket_ids"] = [w["ticket"] for w in workers]

        async def mock_run_worker(worker):
            idx = int(worker["agent"].split("-")[1])
            if idx < 3:
                # Usage-limit failure (3/8 = 37.5% < 50%)
                return (0, "", "", {})
            else:
                return (1, "", "script error: normal failure", {})

        conductor._run_worker = mock_run_worker

        await conductor._do_working()

        status = conductor.state.get("status", "?")
        if status == "EVALUATING":
            return True, "Below threshold (3/8 = 37.5% < 50%): stays in EVALUATING (correct)"
        elif status == "LIMIT_WAIT":
            return False, "Below threshold: incorrectly entered LIMIT_WAIT"
        else:
            return True, f"Below threshold: status={status} (retries queued, not LIMIT_WAIT)"
    finally:
        c.REPO_ROOT = orig_repo_root
        c.ORCH_DIR = orig_orch_dir
        shutil.rmtree(tmp_dir, ignore_errors=True)


# ---------------------------------------------------------------------------
# Runner
# ---------------------------------------------------------------------------

def main() -> int:
    print()
    print("=" * 60)
    print("  Usage-Limit Detection Tests")
    print("=" * 60)

    # Synchronous tests
    sync_checks = [
        test_detect_usage_limit_rate_limit_in_stderr(),
        test_detect_usage_limit_various_keywords(),
        test_detect_usage_limit_empty_stdout_exit0(),
        test_detect_usage_limit_normal_failure(),
    ]

    # Async tests
    async_checks = asyncio.run(_run_async_tests())

    checks = sync_checks + async_checks

    for ok, msg in checks:
        tag = "PASS" if ok else "FAIL"
        print(f"  [{tag}] {msg}")

    passed = sum(1 for ok, _ in checks if ok)
    total = len(checks)
    print()
    if passed == total:
        print(f"  Result: {passed}/{total} PASSED")
    else:
        print(f"  Result: {passed}/{total} PASSED, {total - passed} FAILED")
    print("=" * 60)
    return 0 if passed == total else 1


async def _run_async_tests():
    return [
        await test_mass_usage_limit_enters_limit_wait(),
        await test_below_threshold_does_not_enter_limit_wait(),
    ]


if __name__ == "__main__":
    sys.exit(main())
