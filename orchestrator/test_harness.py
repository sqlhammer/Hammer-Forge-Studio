#!/usr/bin/env python3
"""test_harness.py — End-to-end test for the orchestrator conductor.

Usage:
    python orchestrator/test_harness.py                        # mock mode (free, ~5s)
    python orchestrator/test_harness.py --mode mock            # explicit mock
    python orchestrator/test_harness.py --mode live            # real agents (~$2-3)
    python orchestrator/test_harness.py --mode mock --verbose  # print wave plans
    python orchestrator/test_harness.py --keep-artifacts       # don't clean up temp dir

Additional unit tests:
  - Checkpoint created on abnormal exit (empty stdout)
  - Checkpoint auto-remediated on startup when ticket is DONE on disk
"""

import argparse
import asyncio
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from unittest.mock import patch, MagicMock

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
from orchestrator.instance_paths import InstancePaths, load_config
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
# TestConductor — thin wrapper that records events
# ---------------------------------------------------------------------------

class TestConductor(Conductor):
    """Conductor subclass for testing.

    Overrides:
    - Event recording: tracks waves, worker results for assertions.
    - I/O redirection: uses a temp orch_dir so production files are untouched.
    - Evaluating: skips git merge/pull/UID steps (tests don't produce real branches).
    """

    def __init__(self, orch_dir: Path, repo_root: Path, **kwargs):
        self._test_orch_dir = orch_dir
        self._test_repo_root = repo_root
        self._events: list[dict] = []
        self._waves: list[dict] = []
        self._worker_results: list[dict] = []
        self._verbose = kwargs.pop("verbose", False)
        run_claude_fn = kwargs.pop("run_claude_fn", None)
        config_path = kwargs.pop("config_path", None)

        # Patch module-level path constants used by conductor internals
        import orchestrator.conductor as c
        self._orig_repo_root = c.REPO_ROOT
        self._orig_orch_dir = c.ORCH_DIR
        c.REPO_ROOT = repo_root
        c.ORCH_DIR = orch_dir

        # Build InstancePaths pointing to the temp orch_dir
        paths = InstancePaths(
            orch_dir=orch_dir,
            instance_dir=orch_dir,
            config_path=config_path or (orch_dir / "config.json"),
            config_local_path=orch_dir / "config.local.json",
            state_path=orch_dir / "state.json",
            activity_log=orch_dir / "activity.log",
            pending_gate_path=orch_dir / "pending_gate.json",
            gate_response_path=orch_dir / "gate_response.json",
            godot_mcp_lock_path=orch_dir / "godot_mcp.lock",
            results_dir=orch_dir / "results",
            logs_dir=orch_dir / "logs",
            prompts_dir=orch_dir / "prompts",
            schemas_dir=orch_dir / "schemas",
        )
        config = load_config(paths)

        super().__init__(paths=paths, config=config, run_claude_fn=run_claude_fn)

    def restore_paths(self):
        """Restore original module-level paths after test."""
        import orchestrator.conductor as c
        c.REPO_ROOT = self._orig_repo_root
        c.ORCH_DIR = self._orig_orch_dir

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

        # Record milestone_complete
        if self.state.get("status") == "IDLE":
            completed = self.state.get("completed_waves", [])
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
        for tid, entry in retries.items():
            # entry may be the new dict format {"count": N, "reasons": [...]}
            # or the legacy int format
            count = entry["count"] if isinstance(entry, dict) else entry
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

    # -- Skip git operations in EVALUATING -----------------------------------

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
# Checkpoint unit tests (TICKET-0183)
# ---------------------------------------------------------------------------

def _make_checkpoint_paths(orch_dir: Path) -> InstancePaths:
    """Build InstancePaths pointing at a temp orch_dir for checkpoint tests."""
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


async def test_checkpoint_created_on_abnormal_exit() -> tuple[bool, str]:
    """Worker exits with empty stdout → checkpoint file created with correct schema.

    Scenario: agent exits 0 with empty stdout (usage-limit pattern) and the ticket
    is not DONE on disk.  _write_checkpoint must be called before _queue_retry,
    producing a checkpoint JSON with all required schema fields.
    """
    tmp_dir = Path(tempfile.mkdtemp(prefix="hfs_test_checkpoint_write_"))
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
        paths = _make_checkpoint_paths(orch_dir)
        config = load_config(paths)
        conductor = Conductor(paths=paths, config=config)
        conductor.state = create_initial_state("_test", "Alpha")

        # Build a fake worker (no worktree — skips git probing)
        ticket_id = "TICKET-9997"
        worker = {
            "agent": "gameplay-programmer",
            "ticket": ticket_id,
            "budget_usd": 0.5,
            "needs_worktree": False,
            "needs_godot_mcp": False,
            "worktree_path": None,
            "branch": None,
            "prompt_supplement": "",
            "started_at": "2026-03-01T00:00:00",
        }
        conductor.state["active_workers"] = [worker]
        conductor.state["active_ticket_ids"] = [ticket_id]

        # Mock _run_worker to return exit=0, empty stdout (usage-limit pattern)
        async def mock_run_worker(_worker):
            return (0, "", "", {})

        conductor._run_worker = mock_run_worker

        await conductor._do_working()

        # Verify checkpoint file was created
        checkpoint_path = orch_dir / "checkpoints" / f"{ticket_id}.checkpoint.json"
        if not checkpoint_path.exists():
            return False, "Checkpoint: file not created after empty-stdout exit"

        cp = json.loads(checkpoint_path.read_text(encoding="utf-8"))

        # Validate required schema fields
        required_top = ["ticket", "agent", "milestone", "phase", "wave",
                        "suspended_at", "reason", "progress", "notes"]
        missing_top = [f for f in required_top if f not in cp]
        if missing_top:
            return False, f"Checkpoint: missing top-level fields: {missing_top}"

        required_progress = ["commit_hash", "branch", "pr_url", "pr_merged",
                             "ticket_status_on_disk", "steps_completed"]
        missing_prog = [f for f in required_progress if f not in cp.get("progress", {})]
        if missing_prog:
            return False, f"Checkpoint: missing progress fields: {missing_prog}"

        if cp["ticket"] != ticket_id:
            return False, f"Checkpoint: ticket field mismatch: {cp['ticket']!r}"

        if cp["reason"] != "usage_limit":
            return False, f"Checkpoint: expected reason='usage_limit', got {cp['reason']!r}"

        return True, "Checkpoint: created with correct schema after empty-stdout exit"
    finally:
        c.REPO_ROOT = orig_repo_root
        c.ORCH_DIR = orig_orch_dir
        shutil.rmtree(tmp_dir, ignore_errors=True)


async def test_checkpoint_auto_remediated_on_startup() -> tuple[bool, str]:
    """Checkpoint exists on startup with ticket DONE on disk → auto-remediated and deleted.

    Scenario: previous session wrote a checkpoint for TICKET-9996; on restart the
    conductor scans checkpoints/, finds the file, reads the ticket (DONE on disk),
    and auto-remediates: adds to completed_this_session and deletes the checkpoint.
    """
    tmp_dir = Path(tempfile.mkdtemp(prefix="hfs_test_checkpoint_startup_"))
    orch_dir = tmp_dir / "orchestrator"
    orch_dir.mkdir()
    (orch_dir / "results").mkdir()
    (orch_dir / "logs").mkdir()
    repo_root = tmp_dir / "repo"

    import orchestrator.conductor as c
    orig_repo_root = c.REPO_ROOT
    orig_orch_dir = c.ORCH_DIR
    c.REPO_ROOT = repo_root
    c.ORCH_DIR = orch_dir

    try:
        ticket_id = "TICKET-9996"
        milestone = "_test"

        # Create ticket file with status DONE
        ticket_dir = repo_root / "tickets" / milestone
        ticket_dir.mkdir(parents=True)
        (ticket_dir / f"{ticket_id}.md").write_text(
            f"---\nid: {ticket_id}\nstatus: DONE\n---\n", encoding="utf-8"
        )

        # Create checkpoint file
        checkpoints_dir = orch_dir / "checkpoints"
        checkpoints_dir.mkdir()
        checkpoint_path = checkpoints_dir / f"{ticket_id}.checkpoint.json"
        checkpoint_path.write_text(json.dumps({
            "ticket": ticket_id,
            "agent": "gameplay-programmer",
            "milestone": milestone,
            "phase": "Alpha",
            "wave": 3,
            "suspended_at": "2026-03-01T10:00:00",
            "reason": "usage_limit",
            "progress": {
                "steps_completed": ["read_ticket", "marked_in_progress", "committed"],
                "commit_hash": "abc1234",
                "branch": f"orch/gameplay-programmer/{ticket_id}",
                "uncommitted_changes": False,
                "pr_url": None,
                "pr_merged": False,
                "pr_state": None,
                "ticket_status_on_disk": "IN_PROGRESS",
                "files_changed": [],
                "new_gd_scripts": False,
            },
            "notes": "exit_code=0",
        }), encoding="utf-8")

        paths = _make_checkpoint_paths(orch_dir)
        config = load_config(paths)
        conductor = Conductor(paths=paths, config=config)
        conductor.state = create_initial_state(milestone, "Alpha")

        # Simulate a stale active_ticket_id entry from the previous session
        conductor.state["active_ticket_ids"] = [ticket_id]

        conductor._scan_checkpoints_on_startup()

        # Checkpoint file should be deleted
        if checkpoint_path.exists():
            return False, "Checkpoint: file not deleted after auto-remediation on startup"

        # Ticket should be in completed_this_session
        session_done = conductor.state.get("completed_this_session", [])
        if ticket_id not in session_done:
            return False, f"Checkpoint: {ticket_id} not added to completed_this_session"

        # Stale active_ticket_id should be cleared
        active = conductor.state.get("active_ticket_ids", [])
        if ticket_id in active:
            return False, f"Checkpoint: {ticket_id} not cleared from active_ticket_ids"

        return True, "Checkpoint: auto-remediated on startup — file deleted, ticket added to session"
    finally:
        c.REPO_ROOT = orig_repo_root
        c.ORCH_DIR = orig_orch_dir
        shutil.rmtree(tmp_dir, ignore_errors=True)


# ---------------------------------------------------------------------------
# UID commit idempotency unit tests (TICKET-0186)
# ---------------------------------------------------------------------------

async def test_uid_commit_pending_with_staged_files() -> tuple[bool, str]:
    """Conductor restarted with _uid_commit_pending=True and staged .uid files.

    Scenario: previous session staged .gd.uid files but was interrupted before
    commit.  On startup the conductor detects _uid_commit_pending=True and runs
    _handle_uid_commits.  The method should commit and push, then clear the flag.
    """
    tmp_dir = Path(tempfile.mkdtemp(prefix="hfs_test_uid_staged_"))
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
        paths = _make_checkpoint_paths(orch_dir)
        config = load_config(paths)
        conductor = Conductor(paths=paths, config=config)
        conductor.state = create_initial_state("_test", "Alpha")
        conductor.state["_uid_commit_pending"] = True

        git_calls: list[list[str]] = []

        def mock_subprocess_run(args, **kwargs):
            git_calls.append(list(args))
            result = MagicMock()
            result.returncode = 0
            result.stdout = ""
            result.stderr = ""
            cmd = args[1] if len(args) > 1 else ""

            if args[1:4] == ["diff", "--cached", "--name-only"]:
                # Some files already staged
                result.stdout = "game/scripts/foo.gd.uid\n"
            elif args[1:4] == ["ls-files", "--others", "--exclude-standard"]:
                # One more untracked .uid file
                result.stdout = "game/scripts/bar.gd.uid\n"
            elif args[1:3] == ["diff", "--cached"]:
                # Staged changes exist → returncode=1
                result.returncode = 1
            elif args[1:3] == ["rev-list", "--count"]:
                # 1 commit ahead of origin/main
                result.stdout = "1\n"
            return result

        with patch("orchestrator.conductor.subprocess.run", side_effect=mock_subprocess_run):
            await conductor._handle_uid_commits()

        # Flag must be cleared
        if conductor.state.get("_uid_commit_pending") is not False:
            return False, "UID-idempotency: _uid_commit_pending not cleared after staged-file run"

        # Verify git commit and git push were called
        commit_called = any(c[1:3] == ["commit", "-m"] for c in git_calls)
        push_called = any(c[1:3] == ["push", "origin"] for c in git_calls)

        if not commit_called:
            return False, "UID-idempotency: git commit not called when staged changes present"
        if not push_called:
            return False, "UID-idempotency: git push not called when 1 commit ahead"

        return True, "UID-idempotency: staged .uid files — committed, pushed, flag cleared"
    finally:
        c.REPO_ROOT = orig_repo_root
        c.ORCH_DIR = orig_orch_dir
        shutil.rmtree(tmp_dir, ignore_errors=True)


async def test_uid_commit_pending_already_pushed() -> tuple[bool, str]:
    """Conductor restarted with _uid_commit_pending=True and already-pushed commit.

    Scenario: previous session committed and pushed but crashed before clearing
    the flag.  On startup the conductor detects _uid_commit_pending=True and runs
    _handle_uid_commits.  The method must detect that origin/main is up-to-date
    and skip commit + push without creating an empty commit.
    """
    tmp_dir = Path(tempfile.mkdtemp(prefix="hfs_test_uid_pushed_"))
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
        paths = _make_checkpoint_paths(orch_dir)
        config = load_config(paths)
        conductor = Conductor(paths=paths, config=config)
        conductor.state = create_initial_state("_test", "Alpha")
        conductor.state["_uid_commit_pending"] = True

        git_calls: list[list[str]] = []

        def mock_subprocess_run(args, **kwargs):
            git_calls.append(list(args))
            result = MagicMock()
            result.returncode = 0
            result.stdout = ""
            result.stderr = ""

            if args[1:4] == ["diff", "--cached", "--name-only"]:
                # Nothing staged
                result.stdout = ""
            elif args[1:4] == ["ls-files", "--others", "--exclude-standard"]:
                # No untracked .uid files
                result.stdout = ""
            elif args[1:3] == ["diff", "--cached"]:
                # No staged changes → returncode=0 (nothing to commit)
                result.returncode = 0
            elif args[1:3] == ["rev-list", "--count"]:
                # 0 commits ahead — already pushed
                result.stdout = "0\n"
            return result

        with patch("orchestrator.conductor.subprocess.run", side_effect=mock_subprocess_run):
            await conductor._handle_uid_commits()

        # Flag must be cleared
        if conductor.state.get("_uid_commit_pending") is not False:
            return False, "UID-idempotency: _uid_commit_pending not cleared after already-pushed run"

        # Verify git commit and git push were NOT called
        commit_called = any(c[1:3] == ["commit", "-m"] for c in git_calls)
        push_called = any(c[1:3] == ["push", "origin"] for c in git_calls)

        if commit_called:
            return False, "UID-idempotency: git commit called when no staged changes (empty commit risk)"
        if push_called:
            return False, "UID-idempotency: git push called when already up-to-date with origin/main"

        return True, "UID-idempotency: already-pushed — commit and push skipped, flag cleared"
    finally:
        c.REPO_ROOT = orig_repo_root
        c.ORCH_DIR = orig_orch_dir
        shutil.rmtree(tmp_dir, ignore_errors=True)


# ---------------------------------------------------------------------------
# Merged-PR auto-remediation unit tests (TICKET-0190)
# ---------------------------------------------------------------------------

async def test_merged_pr_auto_remediation_in_do_working() -> tuple[bool, str]:
    """Worker exits abnormally, gh pr list returns merged PR → ticket auto-remediated.

    Scenario: agent exits non-zero (crash), the ticket is IN_PROGRESS on disk,
    and _check_merged_pr returns a merged PR dict.  _do_working must auto-remediate
    the ticket to DONE and NOT queue a retry.
    """
    tmp_dir = Path(tempfile.mkdtemp(prefix="hfs_test_r3_merged_"))
    orch_dir = tmp_dir / "orchestrator"
    orch_dir.mkdir()
    (orch_dir / "results").mkdir()
    (orch_dir / "logs").mkdir()
    repo_root = tmp_dir / "repo"

    import orchestrator.conductor as c
    orig_repo_root = c.REPO_ROOT
    orig_orch_dir = c.ORCH_DIR
    c.REPO_ROOT = repo_root
    c.ORCH_DIR = orch_dir

    try:
        ticket_id = "TICKET-9994"
        milestone = "_test"

        # Create ticket file with status IN_PROGRESS
        ticket_dir = repo_root / "tickets" / milestone
        ticket_dir.mkdir(parents=True)
        ticket_file = ticket_dir / f"{ticket_id}.md"
        ticket_file.write_text(
            f"---\nid: {ticket_id}\nstatus: IN_PROGRESS\nupdated_at: 2026-03-01\n---\n"
            "## Activity Log\n- 2026-03-01 [agent] Starting work\n",
            encoding="utf-8",
        )

        paths = _make_checkpoint_paths(orch_dir)
        config = load_config(paths)
        conductor = c.Conductor(paths=paths, config=config)
        conductor.state = c.create_initial_state(milestone, "Alpha")

        branch = f"orch/gameplay-programmer/{ticket_id}"
        worker = {
            "agent": "gameplay-programmer",
            "ticket": ticket_id,
            "budget_usd": 0.5,
            "needs_worktree": False,
            "needs_godot_mcp": False,
            "worktree_path": None,
            "branch": branch,
            "prompt_supplement": "",
            "started_at": "2026-03-01T00:00:00",
        }
        conductor.state["active_workers"] = [worker]
        conductor.state["active_ticket_ids"] = [ticket_id]

        # Patch _check_merged_pr to return a merged PR
        conductor._check_merged_pr = lambda tid, br: (
            {"number": 42, "url": "https://github.com/test/repo/pull/42",
             "state": "merged", "merged": True}
            if br == branch else None
        )

        # Mock _run_worker to return exit=1, empty output (crash)
        async def mock_run_worker(_worker):
            return (1, "", "", {})

        conductor._run_worker = mock_run_worker

        await conductor._do_working()

        # Ticket file should now read DONE
        ticket_text = ticket_file.read_text(encoding="utf-8")
        if "status: DONE" not in ticket_text:
            return False, "R3: ticket file was not updated to DONE after merged-PR auto-remediation"

        # Ticket should be in completed_this_session
        session_done = conductor.state.get("completed_this_session", [])
        if ticket_id not in session_done:
            return False, f"R3: {ticket_id} not added to completed_this_session"

        # No retry should be queued
        retries = conductor.state.get("retries", {})
        if ticket_id in retries:
            return False, f"R3: retry was queued for auto-remediated ticket {ticket_id}"

        return True, "R3: ticket auto-remediated to DONE after merged PR, no retry queued"
    finally:
        c.REPO_ROOT = orig_repo_root
        c.ORCH_DIR = orig_orch_dir
        shutil.rmtree(tmp_dir, ignore_errors=True)


async def test_open_pr_no_auto_remediation() -> tuple[bool, str]:
    """Worker exits abnormally, gh pr list returns open (not merged) PR → NOT auto-remediated.

    Scenario: agent exits non-zero, the ticket is IN_PROGRESS on disk, but the PR
    is open (not merged).  _do_working must NOT auto-remediate and must queue a retry.
    """
    tmp_dir = Path(tempfile.mkdtemp(prefix="hfs_test_r3_open_"))
    orch_dir = tmp_dir / "orchestrator"
    orch_dir.mkdir()
    (orch_dir / "results").mkdir()
    (orch_dir / "logs").mkdir()
    repo_root = tmp_dir / "repo"

    import orchestrator.conductor as c
    orig_repo_root = c.REPO_ROOT
    orig_orch_dir = c.ORCH_DIR
    c.REPO_ROOT = repo_root
    c.ORCH_DIR = orch_dir

    try:
        ticket_id = "TICKET-9993"
        milestone = "_test"

        # Create ticket file with status IN_PROGRESS
        ticket_dir = repo_root / "tickets" / milestone
        ticket_dir.mkdir(parents=True)
        ticket_file = ticket_dir / f"{ticket_id}.md"
        ticket_file.write_text(
            f"---\nid: {ticket_id}\nstatus: IN_PROGRESS\nupdated_at: 2026-03-01\n---\n",
            encoding="utf-8",
        )

        paths = _make_checkpoint_paths(orch_dir)
        config = load_config(paths)
        conductor = c.Conductor(paths=paths, config=config)
        conductor.state = c.create_initial_state(milestone, "Alpha")

        branch = f"orch/gameplay-programmer/{ticket_id}"
        worker = {
            "agent": "gameplay-programmer",
            "ticket": ticket_id,
            "budget_usd": 0.5,
            "needs_worktree": False,
            "needs_godot_mcp": False,
            "worktree_path": None,
            "branch": branch,
            "prompt_supplement": "",
            "started_at": "2026-03-01T00:00:00",
        }
        conductor.state["active_workers"] = [worker]
        conductor.state["active_ticket_ids"] = [ticket_id]

        # Patch _check_merged_pr to return None (no merged PR found)
        conductor._check_merged_pr = lambda tid, br: None

        # Mock _run_worker to return exit=1, empty output (crash)
        async def mock_run_worker(_worker):
            return (1, "", "", {})

        conductor._run_worker = mock_run_worker

        await conductor._do_working()

        # Ticket file should still read IN_PROGRESS
        ticket_text = ticket_file.read_text(encoding="utf-8")
        if "status: DONE" in ticket_text:
            return False, "R3: ticket incorrectly updated to DONE when PR was not merged"

        # Retry should be queued
        retries = conductor.state.get("retries", {})
        if ticket_id not in retries:
            return False, f"R3: retry was not queued for non-merged PR crash case"

        return True, "R3: open PR correctly skipped auto-remediation, retry queued"
    finally:
        c.REPO_ROOT = orig_repo_root
        c.ORCH_DIR = orig_orch_dir
        shutil.rmtree(tmp_dir, ignore_errors=True)


async def test_merged_pr_auto_remediation_on_startup() -> tuple[bool, str]:
    """Checkpoint exists on startup with IN_PROGRESS ticket and merged PR → auto-remediated.

    Scenario: previous session wrote a checkpoint for TICKET-9992 with status
    IN_PROGRESS.  On restart, _scan_checkpoints_on_startup must call _check_merged_pr,
    find the merged PR, and auto-remediate: update ticket to DONE, add to
    completed_this_session, delete checkpoint.
    """
    tmp_dir = Path(tempfile.mkdtemp(prefix="hfs_test_r3_startup_"))
    orch_dir = tmp_dir / "orchestrator"
    orch_dir.mkdir()
    (orch_dir / "results").mkdir()
    (orch_dir / "logs").mkdir()
    repo_root = tmp_dir / "repo"

    import orchestrator.conductor as c
    orig_repo_root = c.REPO_ROOT
    orig_orch_dir = c.ORCH_DIR
    c.REPO_ROOT = repo_root
    c.ORCH_DIR = orch_dir

    try:
        ticket_id = "TICKET-9992"
        milestone = "_test"
        branch = f"orch/gameplay-programmer/{ticket_id}"

        # Create ticket file with status IN_PROGRESS
        ticket_dir = repo_root / "tickets" / milestone
        ticket_dir.mkdir(parents=True)
        ticket_file = ticket_dir / f"{ticket_id}.md"
        ticket_file.write_text(
            f"---\nid: {ticket_id}\nstatus: IN_PROGRESS\nupdated_at: 2026-03-01\n---\n"
            "## Activity Log\n- 2026-03-01 [agent] Starting work\n",
            encoding="utf-8",
        )

        # Create checkpoint file with IN_PROGRESS branch info
        checkpoints_dir = orch_dir / "checkpoints"
        checkpoints_dir.mkdir()
        checkpoint_path = checkpoints_dir / f"{ticket_id}.checkpoint.json"
        checkpoint_path.write_text(json.dumps({
            "ticket": ticket_id,
            "agent": "gameplay-programmer",
            "milestone": milestone,
            "phase": "Alpha",
            "wave": 5,
            "suspended_at": "2026-03-01T10:00:00",
            "reason": "usage_limit",
            "progress": {
                "steps_completed": ["read_ticket", "marked_in_progress", "committed", "merged_pr"],
                "commit_hash": "def5678",
                "branch": branch,
                "uncommitted_changes": False,
                "pr_url": "https://github.com/test/repo/pull/55",
                "pr_merged": False,
                "pr_state": "MERGED",
                "ticket_status_on_disk": "IN_PROGRESS",
                "files_changed": [],
                "new_gd_scripts": False,
            },
            "notes": "exit_code=0",
        }), encoding="utf-8")

        paths = _make_checkpoint_paths(orch_dir)
        config = load_config(paths)
        conductor = c.Conductor(paths=paths, config=config)
        conductor.state = c.create_initial_state(milestone, "Alpha")
        conductor.state["active_ticket_ids"] = [ticket_id]

        # Patch _check_merged_pr to return a merged PR for this branch
        conductor._check_merged_pr = lambda tid, br: (
            {"number": 55, "url": "https://github.com/test/repo/pull/55",
             "state": "merged", "merged": True}
            if br == branch else None
        )

        conductor._scan_checkpoints_on_startup()

        # Checkpoint file should be deleted
        if checkpoint_path.exists():
            return False, "R3 startup: checkpoint not deleted after auto-remediation"

        # Ticket should be in completed_this_session
        session_done = conductor.state.get("completed_this_session", [])
        if ticket_id not in session_done:
            return False, f"R3 startup: {ticket_id} not added to completed_this_session"

        # Ticket file should read DONE
        ticket_text = ticket_file.read_text(encoding="utf-8")
        if "status: DONE" not in ticket_text:
            return False, "R3 startup: ticket file was not updated to DONE"

        return True, "R3 startup: IN_PROGRESS checkpoint with merged PR auto-remediated on startup"
    finally:
        c.REPO_ROOT = orig_repo_root
        c.ORCH_DIR = orig_orch_dir
        shutil.rmtree(tmp_dir, ignore_errors=True)


# ---------------------------------------------------------------------------
# Gate detection unit tests (TICKET-0189)
# ---------------------------------------------------------------------------

async def test_gate_emitted_when_all_done_and_producer_fails() -> tuple[bool, str]:
    """All phase tickets DONE on disk + Producer unavailable → conductor emits gate.

    Scenario: a milestone has two tickets in the same phase, both DONE on disk.
    The conductor's _do_evaluating call (with Producer already failed) should
    detect completion and write pending_gate.json, transitioning to GATE_BLOCKED.
    """
    tmp_dir = Path(tempfile.mkdtemp(prefix="hfs_test_gate_emit_"))
    orch_dir = tmp_dir / "orchestrator"
    orch_dir.mkdir()
    (orch_dir / "results").mkdir()
    (orch_dir / "logs").mkdir()
    repo_root = tmp_dir / "repo"

    import orchestrator.conductor as c
    orig_repo_root = c.REPO_ROOT
    orig_orch_dir = c.ORCH_DIR
    c.REPO_ROOT = repo_root
    c.ORCH_DIR = orch_dir

    try:
        milestone = "_gtest"
        phase = "Alpha"

        # Create ticket files — both DONE in the same phase
        ticket_dir = repo_root / "tickets" / milestone
        ticket_dir.mkdir(parents=True)
        for tid in ("TICKET-8801", "TICKET-8802"):
            (ticket_dir / f"{tid}.md").write_text(
                f"---\nid: {tid}\nstatus: DONE\nphase: {phase}\n---\n",
                encoding="utf-8",
            )

        paths = _make_checkpoint_paths(orch_dir)
        config = load_config(paths)
        conductor = Conductor(paths=paths, config=config)
        conductor.state = create_initial_state(milestone, phase)
        # Mark at least one completed wave so _do_evaluating doesn't short-circuit
        conductor.state["completed_waves"] = [{"wave": 1, "tickets": ["TICKET-8801"]}]

        # Patch out git operations — not relevant for this unit test
        async def _noop_merge():
            pass
        conductor._merge_pending_branches = _noop_merge

        await conductor._do_evaluating()

        status = conductor.state.get("status")
        gate_path = paths.pending_gate_path

        if status != "GATE_BLOCKED":
            return False, (
                f"Gate fallback: expected status=GATE_BLOCKED, got {status!r}"
            )
        if not gate_path.exists():
            return False, "Gate fallback: pending_gate.json was not written"

        gate_data = json.loads(gate_path.read_text(encoding="utf-8"))
        required = ["milestone", "phase", "next_phase", "summary", "requested_at"]
        missing = [f for f in required if f not in gate_data]
        if missing:
            return False, f"Gate fallback: pending_gate.json missing fields: {missing}"
        if "Conductor fallback" not in gate_data.get("summary", ""):
            return False, (
                f"Gate fallback: unexpected summary: {gate_data.get('summary')!r}"
            )

        return True, "Gate fallback: pending_gate.json written with correct schema"
    finally:
        c.REPO_ROOT = orig_repo_root
        c.ORCH_DIR = orig_orch_dir
        shutil.rmtree(tmp_dir, ignore_errors=True)


async def test_gate_not_double_emitted() -> tuple[bool, str]:
    """When _gate_emitted_this_wave is True, conductor does not re-emit the gate.

    Scenario: pending_gate.json already exists (Producer or a prior cycle already
    emitted).  _gate_emitted_this_wave should be set True in _do_planning,
    preventing _check_fallback_gate from firing again in _do_evaluating.
    """
    tmp_dir = Path(tempfile.mkdtemp(prefix="hfs_test_gate_no_double_"))
    orch_dir = tmp_dir / "orchestrator"
    orch_dir.mkdir()
    (orch_dir / "results").mkdir()
    (orch_dir / "logs").mkdir()
    repo_root = tmp_dir / "repo"

    import orchestrator.conductor as c
    orig_repo_root = c.REPO_ROOT
    orig_orch_dir = c.ORCH_DIR
    c.REPO_ROOT = repo_root
    c.ORCH_DIR = orch_dir

    try:
        milestone = "_gtest2"
        phase = "Beta"

        ticket_dir = repo_root / "tickets" / milestone
        ticket_dir.mkdir(parents=True)
        for tid in ("TICKET-8803", "TICKET-8804"):
            (ticket_dir / f"{tid}.md").write_text(
                f"---\nid: {tid}\nstatus: DONE\nphase: {phase}\n---\n",
                encoding="utf-8",
            )

        paths = _make_checkpoint_paths(orch_dir)
        config = load_config(paths)
        conductor = Conductor(paths=paths, config=config)
        conductor.state = create_initial_state(milestone, phase)
        conductor.state["completed_waves"] = [{"wave": 1, "tickets": ["TICKET-8803"]}]

        # Pre-write pending_gate.json (simulating Producer already emitted)
        write_json(paths.pending_gate_path, {
            "milestone": milestone,
            "phase": phase,
            "next_phase": "",
            "summary": "Producer emitted gate",
            "requested_at": "2026-03-02T00:00:00",
        })

        # Simulate what _do_planning does: detect existing gate → set flag
        conductor._gate_emitted_this_wave = paths.pending_gate_path.exists()

        async def _noop_merge():
            pass
        conductor._merge_pending_branches = _noop_merge

        # Capture the mtime of pending_gate.json before evaluating
        mtime_before = paths.pending_gate_path.stat().st_mtime

        await conductor._do_evaluating()

        # File should not have been rewritten (mtime unchanged)
        mtime_after = paths.pending_gate_path.stat().st_mtime
        if mtime_before != mtime_after:
            return False, (
                "Gate no-double-emit: pending_gate.json was rewritten even though "
                "_gate_emitted_this_wave was True"
            )

        # Status should be PLANNING (gate already handled — conductor skips fallback)
        status = conductor.state.get("status")
        if status not in ("PLANNING", "GATE_BLOCKED"):
            return False, f"Gate no-double-emit: unexpected status {status!r}"

        return True, "Gate no-double-emit: pending_gate.json not rewritten when flag set"
    finally:
        c.REPO_ROOT = orig_repo_root
        c.ORCH_DIR = orig_orch_dir
        shutil.rmtree(tmp_dir, ignore_errors=True)


# ---------------------------------------------------------------------------
# Resume dispatch unit tests (TICKET-0185)
# ---------------------------------------------------------------------------

async def test_checkpoint_context_injected_in_dispatch() -> tuple[bool, str]:
    """Checkpoint exists for ticket → dispatch prompt includes checkpoint context.

    Scenario: a checkpoint file exists for TICKET-9995 before _run_worker is called.
    The conductor reads the checkpoint and builds a resume briefing, which is injected
    into the prompt passed to _run_claude.  The [RESUME ] dispatch log is also emitted.
    """
    tmp_dir = Path(tempfile.mkdtemp(prefix="hfs_test_resume_dispatch_"))
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
        ticket_id = "TICKET-9995"

        # Create checkpoint file for the ticket
        checkpoints_dir = orch_dir / "checkpoints"
        checkpoints_dir.mkdir()
        checkpoint_path = checkpoints_dir / f"{ticket_id}.checkpoint.json"
        checkpoint_path.write_text(json.dumps({
            "ticket": ticket_id,
            "agent": "gameplay-programmer",
            "milestone": "_test",
            "phase": "Alpha",
            "wave": 2,
            "suspended_at": "2026-03-02T10:00:00",
            "reason": "timeout",
            "progress": {
                "steps_completed": ["read_ticket", "verified_deps", "marked_in_progress", "committed"],
                "commit_hash": "deadbeef",
                "branch": f"orch/gameplay-programmer/{ticket_id}",
                "uncommitted_changes": False,
                "pr_url": None,
                "pr_merged": False,
                "pr_state": None,
                "ticket_status_on_disk": "IN_PROGRESS",
                "files_changed": [],
                "new_gd_scripts": False,
            },
            "notes": "exit_code=-1",
        }), encoding="utf-8")

        paths = _make_checkpoint_paths(orch_dir)
        config = load_config(paths)
        conductor = Conductor(paths=paths, config=config)
        conductor.state = create_initial_state("_test", "Alpha")

        # Capture the prompt passed to _run_claude
        captured_prompts: list[str] = []
        resume_logs: list[str] = []

        async def mock_run_claude(prompt, **kwargs):
            captured_prompts.append(prompt)
            return (0, "", "", {})

        conductor._run_claude = mock_run_claude

        # Capture RESUME log events
        original_log = conductor.logger.log
        def capturing_log(level, msg):
            if level == "RESUME":
                resume_logs.append(msg)
            original_log(level, msg)
        conductor.logger.log = capturing_log

        worker = {
            "agent": "gameplay-programmer",
            "ticket": ticket_id,
            "budget_usd": 0.5,
            "needs_worktree": False,
            "needs_godot_mcp": False,
            "worktree_path": None,
            "branch": None,
            "prompt_supplement": "",
            "started_at": "2026-03-02T10:00:00",
        }

        await conductor._run_worker(worker)

        # Verify the prompt contains resume briefing content
        if not captured_prompts:
            return False, "Resume dispatch: _run_claude was not called"

        prompt = captured_prompts[0]
        if "Resume Context" not in prompt:
            return False, f"Resume dispatch: prompt missing 'Resume Context' section"
        if ticket_id not in prompt:
            return False, f"Resume dispatch: prompt missing ticket ID {ticket_id}"
        if "deadbeef" not in prompt:
            return False, f"Resume dispatch: prompt missing commit hash from checkpoint"

        # Verify [RESUME ] dispatch log was emitted
        dispatch_logs = [m for m in resume_logs if "Dispatching" in m and ticket_id in m]
        if not dispatch_logs:
            return False, "Resume dispatch: [RESUME ] dispatch log not emitted"

        # Verify worker was flagged as resumed
        if not worker.get("_was_resumed"):
            return False, "Resume dispatch: worker['_was_resumed'] not set"

        return True, "Resume dispatch: checkpoint context injected in prompt, [RESUME ] logged"
    finally:
        c.REPO_ROOT = orig_repo_root
        c.ORCH_DIR = orig_orch_dir
        shutil.rmtree(tmp_dir, ignore_errors=True)


async def test_resumed_worker_done_clears_checkpoint() -> tuple[bool, str]:
    """Resumed worker reports done → checkpoint file deleted, [RESUME ] success logged.

    Scenario: a checkpoint file exists for TICKET-9994 (worker was previously resumed).
    The worker reports outcome=done and the ticket file is DONE on disk.
    _do_working should delete the checkpoint and emit [RESUME ] {ticket} resumed successfully.
    """
    tmp_dir = Path(tempfile.mkdtemp(prefix="hfs_test_resume_done_"))
    orch_dir = tmp_dir / "orchestrator"
    orch_dir.mkdir()
    (orch_dir / "results").mkdir()
    (orch_dir / "logs").mkdir()
    repo_root = tmp_dir / "repo"

    import orchestrator.conductor as c
    orig_repo_root = c.REPO_ROOT
    orig_orch_dir = c.ORCH_DIR
    c.REPO_ROOT = repo_root
    c.ORCH_DIR = orch_dir

    try:
        ticket_id = "TICKET-9994"
        milestone = "_test"

        # Create ticket file with status DONE
        ticket_dir = repo_root / "tickets" / milestone
        ticket_dir.mkdir(parents=True)
        (ticket_dir / f"{ticket_id}.md").write_text(
            f"---\nid: {ticket_id}\nstatus: DONE\n---\n", encoding="utf-8"
        )

        # Create checkpoint file (simulates an existing suspended checkpoint)
        checkpoints_dir = orch_dir / "checkpoints"
        checkpoints_dir.mkdir()
        checkpoint_path = checkpoints_dir / f"{ticket_id}.checkpoint.json"
        checkpoint_path.write_text(json.dumps({
            "ticket": ticket_id,
            "agent": "gameplay-programmer",
            "milestone": milestone,
            "phase": "Alpha",
            "wave": 2,
            "suspended_at": "2026-03-02T09:00:00",
            "reason": "usage_limit",
            "progress": {
                "steps_completed": ["read_ticket", "verified_deps", "marked_in_progress"],
                "commit_hash": None,
                "branch": f"orch/gameplay-programmer/{ticket_id}",
                "uncommitted_changes": False,
                "pr_url": None,
                "pr_merged": False,
                "pr_state": None,
                "ticket_status_on_disk": "IN_PROGRESS",
                "files_changed": [],
                "new_gd_scripts": False,
            },
            "notes": "exit_code=0",
        }), encoding="utf-8")

        paths = _make_checkpoint_paths(orch_dir)
        config = load_config(paths)
        conductor = Conductor(paths=paths, config=config)
        conductor.state = create_initial_state(milestone, "Alpha")

        # Build a worker pre-flagged as resumed (as _run_worker would set it)
        worker = {
            "agent": "gameplay-programmer",
            "ticket": ticket_id,
            "budget_usd": 0.5,
            "needs_worktree": False,
            "needs_godot_mcp": False,
            "worktree_path": None,
            "branch": None,
            "prompt_supplement": "",
            "started_at": "2026-03-02T09:30:00",
            "_was_resumed": True,
        }
        conductor.state["active_workers"] = [worker]
        conductor.state["active_ticket_ids"] = [ticket_id]

        # Capture RESUME log events
        resume_logs: list[str] = []
        original_log = conductor.logger.log
        def capturing_log(level, msg):
            if level == "RESUME":
                resume_logs.append(msg)
            original_log(level, msg)
        conductor.logger.log = capturing_log

        # Mock _run_worker to return done outcome
        done_json = json.dumps({
            "ticket": ticket_id,
            "outcome": "done",
            "summary": "Resumed and completed successfully.",
        })
        async def mock_run_worker(_worker):
            return (0, done_json, "", {})
        conductor._run_worker = mock_run_worker

        await conductor._do_working()

        # Checkpoint file should be deleted
        if checkpoint_path.exists():
            return False, "Resume done: checkpoint file not deleted after successful resume"

        # [RESUME ] success log should have been emitted
        success_logs = [m for m in resume_logs if "resumed successfully" in m and ticket_id in m]
        if not success_logs:
            return False, "Resume done: [RESUME ] 'resumed successfully' log not emitted"

        return True, "Resume done: checkpoint cleared, [RESUME ] resumed successfully logged"
    finally:
        c.REPO_ROOT = orig_repo_root
        c.ORCH_DIR = orig_orch_dir
        shutil.rmtree(tmp_dir, ignore_errors=True)


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

        # Run the conductor — use "_test" milestone so read_ticket_status
        # can find tickets in tickets/_test/ by lowercasing the milestone name.
        await conductor.run("_test", "Alpha")

        # Collect data for assertions
        state = conductor.state
        events = conductor._events
        waves = conductor._waves
        worker_results = conductor._worker_results
        duration = time.time() - start_time

        # Run all 13 assertions
        checks = [
            assertions.check_terminal_state(state),
            assertions.check_wave1_parallel(waves),
            assertions.check_wave1_no_9903(waves),
            assertions.check_9903_dispatched(waves),
            assertions.check_no_premature_beta(waves),
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

    # Run the end-to-end harness
    harness_exit = asyncio.run(run_test(args.mode, args.verbose, args.keep_artifacts))

    # Run checkpoint unit tests (TICKET-0183)
    async def _run_checkpoint_tests():
        return [
            await test_checkpoint_created_on_abnormal_exit(),
            await test_checkpoint_auto_remediated_on_startup(),
        ]

    checkpoint_checks = asyncio.run(_run_checkpoint_tests())

    print()
    print("=" * 60)
    print("  Checkpoint Unit Tests (TICKET-0183)")
    print("=" * 60)
    for ok, msg in checkpoint_checks:
        tag = "PASS" if ok else "FAIL"
        print(f"  [{tag}] {msg}")
    cp_passed = sum(1 for ok, _ in checkpoint_checks if ok)
    cp_total = len(checkpoint_checks)
    print()
    if cp_passed == cp_total:
        print(f"  Result: {cp_passed}/{cp_total} PASSED")
    else:
        print(f"  Result: {cp_passed}/{cp_total} PASSED, {cp_total - cp_passed} FAILED")
    print("=" * 60)

    # Run UID commit idempotency unit tests (TICKET-0186)
    async def _run_uid_tests():
        return [
            await test_uid_commit_pending_with_staged_files(),
            await test_uid_commit_pending_already_pushed(),
        ]

    uid_checks = asyncio.run(_run_uid_tests())

    print()
    print("=" * 60)
    print("  UID Commit Idempotency Unit Tests (TICKET-0186)")
    print("=" * 60)
    for ok, msg in uid_checks:
        tag = "PASS" if ok else "FAIL"
        print(f"  [{tag}] {msg}")
    uid_passed = sum(1 for ok, _ in uid_checks if ok)
    uid_total = len(uid_checks)
    print()
    if uid_passed == uid_total:
        print(f"  Result: {uid_passed}/{uid_total} PASSED")
    else:
        print(f"  Result: {uid_passed}/{uid_total} PASSED, {uid_total - uid_passed} FAILED")
    print("=" * 60)

    # Run merged-PR auto-remediation unit tests (TICKET-0190)
    async def _run_r3_tests():
        return [
            await test_merged_pr_auto_remediation_in_do_working(),
            await test_open_pr_no_auto_remediation(),
            await test_merged_pr_auto_remediation_on_startup(),
        ]

    r3_checks = asyncio.run(_run_r3_tests())

    print()
    print("=" * 60)
    print("  Merged-PR Auto-Remediation Tests (TICKET-0190)")
    print("=" * 60)
    for ok, msg in r3_checks:
        tag = "PASS" if ok else "FAIL"
        print(f"  [{tag}] {msg}")
    r3_passed = sum(1 for ok, _ in r3_checks if ok)
    r3_total = len(r3_checks)
    print()
    if r3_passed == r3_total:
        print(f"  Result: {r3_passed}/{r3_total} PASSED")
    else:
        print(f"  Result: {r3_passed}/{r3_total} PASSED, {r3_total - r3_passed} FAILED")
    print("=" * 60)

    # Run gate detection unit tests (TICKET-0189)
    async def _run_gate_tests():
        return [
            await test_gate_emitted_when_all_done_and_producer_fails(),
            await test_gate_not_double_emitted(),
        ]

    gate_checks = asyncio.run(_run_gate_tests())

    print()
    print("=" * 60)
    print("  Gate Detection Unit Tests (TICKET-0189)")
    print("=" * 60)
    for ok, msg in gate_checks:
        tag = "PASS" if ok else "FAIL"
        print(f"  [{tag}] {msg}")
    gate_passed = sum(1 for ok, _ in gate_checks if ok)
    gate_total = len(gate_checks)
    print()
    if gate_passed == gate_total:
        print(f"  Result: {gate_passed}/{gate_total} PASSED")
    else:
        print(f"  Result: {gate_passed}/{gate_total} PASSED, {gate_total - gate_passed} FAILED")
    print("=" * 60)

    # Run resume dispatch unit tests (TICKET-0185)
    async def _run_resume_tests():
        return [
            await test_checkpoint_context_injected_in_dispatch(),
            await test_resumed_worker_done_clears_checkpoint(),
        ]

    resume_checks = asyncio.run(_run_resume_tests())

    print()
    print("=" * 60)
    print("  Resume Dispatch Unit Tests (TICKET-0185)")
    print("=" * 60)
    for ok, msg in resume_checks:
        tag = "PASS" if ok else "FAIL"
        print(f"  [{tag}] {msg}")
    res_passed = sum(1 for ok, _ in resume_checks if ok)
    res_total = len(resume_checks)
    print()
    if res_passed == res_total:
        print(f"  Result: {res_passed}/{res_total} PASSED")
    else:
        print(f"  Result: {res_passed}/{res_total} PASSED, {res_total - res_passed} FAILED")
    print("=" * 60)

    # Exit non-zero if any test suite failed
    all_passed = (
        harness_exit == 0
        and cp_passed == cp_total
        and uid_passed == uid_total
        and r3_passed == r3_total
        and gate_passed == gate_total
        and res_passed == res_total
    )
    sys.exit(0 if all_passed else 1)


if __name__ == "__main__":
    main()
