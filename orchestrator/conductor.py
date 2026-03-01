#!/usr/bin/env python3
"""conductor.py — Orchestration loop for Hammer Forge Studio.

Usage:
    python orchestrator/conductor.py <milestone>
    python orchestrator/conductor.py <milestone> --instance <name>
    python orchestrator/conductor.py --status --instance <name>

Behaviour:
  - If state.json exists, resumes automatically from saved state.
  - If no state.json, starts fresh and auto-detects the starting phase
    from the milestone's ticket files (first non-DONE ticket by ID order).

The Conductor is a dumb executor. The Producer (Claude) is the intelligent
scheduler. The Conductor never decides which agent to spawn or which ticket
to assign — it only executes what the Producer outputs.
"""

import argparse
import asyncio
import json
import os
import platform
import re
import signal
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

from instance_paths import InstancePaths, load_config, resolve_instance

# ---------------------------------------------------------------------------
# Paths — only repo-level constants that are needed before arg parsing
# ---------------------------------------------------------------------------

REPO_ROOT = Path(os.environ.get("HFS_REPO_ROOT", Path(__file__).resolve().parent.parent))
ORCH_DIR = Path(os.environ.get("HFS_ORCH_DIR", REPO_ROOT / "orchestrator"))
AGENTS_DIR = REPO_ROOT / "agents"
WORKTREES_DIR = REPO_ROOT / ".claude" / "worktrees"

# ---------------------------------------------------------------------------
# Godot MCP tool names by tier
# ---------------------------------------------------------------------------

# Tier 3 only (full engine access beyond scene construction)
TIER_3_TOOLS = [
    "mcp__godot-mcp__create_script",
    "mcp__godot-mcp__attach_script",
    "mcp__godot-mcp__edit_file",
    "mcp__godot-mcp__execute_editor_script",
    "mcp__godot-mcp__get_godot_errors",
    "mcp__godot-mcp__clear_output_logs",
]

# Tier 2 only (scene construction beyond read/observe)
TIER_2_TOOLS = [
    "mcp__godot-mcp__create_scene",
    "mcp__godot-mcp__add_node",
    "mcp__godot-mcp__add_resource",
    "mcp__godot-mcp__update_property",
    "mcp__godot-mcp__delete_node",
    "mcp__godot-mcp__delete_scene",
    "mcp__godot-mcp__duplicate_node",
    "mcp__godot-mcp__move_node",
    "mcp__godot-mcp__add_scene",
    "mcp__godot-mcp__open_scene",
    "mcp__godot-mcp__play_scene",
    "mcp__godot-mcp__stop_running_scene",
    "mcp__godot-mcp__simulate_input",
    "mcp__godot-mcp__set_anchor_preset",
    "mcp__godot-mcp__set_anchor_values",
]

# Tier 1 (read/observe) — these are never blocked for tiers 1–3
# Note: get_godot_errors is Tier 3 despite the get_* prefix
TIER_1_TOOLS = [
    "mcp__godot-mcp__get_scene_tree",
    "mcp__godot-mcp__get_filesystem_tree",
    "mcp__godot-mcp__get_project_info",
    "mcp__godot-mcp__get_scene_file_content",
    "mcp__godot-mcp__search_files",
    "mcp__godot-mcp__get_open_scripts",
    "mcp__godot-mcp__view_script",
    "mcp__godot-mcp__get_editor_screenshot",
    "mcp__godot-mcp__get_running_scene_screenshot",
    "mcp__godot-mcp__uid_to_project_path",
    "mcp__godot-mcp__project_path_to_uid",
    "mcp__godot-mcp__get_input_map",
]

# All Godot MCP tools (for tier 0 — block everything)
ALL_GODOT_TOOLS = TIER_1_TOOLS + TIER_2_TOOLS + TIER_3_TOOLS


# ---------------------------------------------------------------------------
# Utility
# ---------------------------------------------------------------------------

def now_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S")


def load_json(path: Path) -> dict:
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def write_json(path: Path, data: dict):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
        f.flush()
        os.fsync(f.fileno())


def format_duration(seconds: float) -> str:
    m, s = divmod(int(seconds), 60)
    return f"{m}m {s}s"


def format_cost(usd: float) -> str:
    return f"${usd:.2f}"


# ---------------------------------------------------------------------------
# Godot MCP file-based mutex
# ---------------------------------------------------------------------------

STALE_LOCK_SECONDS = 30 * 60  # 30 minutes


def acquire_godot_mcp_lock(
    ticket_id: str, agent_slug: str, wave: int,
    lock_path: Path, logger=None,
) -> bool:
    """Try to acquire the Godot MCP lock file.

    Returns True if the lock was acquired, False if it is held by another agent.
    Automatically removes stale locks older than STALE_LOCK_SECONDS.
    """
    if lock_path.exists():
        try:
            data = json.loads(lock_path.read_text(encoding="utf-8"))
            acquired_at = data.get("acquired_at", "")
            if acquired_at:
                lock_time = datetime.fromisoformat(acquired_at)
                age = (datetime.now(timezone.utc) - lock_time).total_seconds()
                if age > STALE_LOCK_SECONDS:
                    if logger:
                        logger.log("WARNING",
                            f"Stale Godot MCP lock detected (held by {data.get('holder', '?')} "
                            f"for {format_duration(age)}). Removing.")
                    lock_path.unlink(missing_ok=True)
                else:
                    return False
            else:
                return False
        except (json.JSONDecodeError, ValueError, OSError):
            # Corrupt lock file — remove and proceed
            lock_path.unlink(missing_ok=True)

    lock_data = {
        "holder": ticket_id,
        "agent": agent_slug,
        "acquired_at": now_iso(),
        "wave": wave,
    }
    lock_path.write_text(
        json.dumps(lock_data, indent=2), encoding="utf-8"
    )
    return True


def release_godot_mcp_lock(lock_path: Path, logger=None):
    """Release the Godot MCP lock file if it exists."""
    if lock_path.exists():
        try:
            holder = "unknown"
            data = json.loads(lock_path.read_text(encoding="utf-8"))
            holder = data.get("holder", "unknown")
        except (json.JSONDecodeError, ValueError, OSError):
            pass
        lock_path.unlink(missing_ok=True)
        if logger:
            logger.log("UNLOCK", f"Released Godot MCP lock (was held by {holder})")


def read_godot_mcp_lock(lock_path: Path) -> dict | None:
    """Read the current Godot MCP lock data. Returns None if not held."""
    if not lock_path.exists():
        return None
    try:
        return json.loads(lock_path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, ValueError, OSError):
        return None


# ---------------------------------------------------------------------------
# Activity Logger
# ---------------------------------------------------------------------------

class ActivityLogger:
    def __init__(self, path: Path):
        self.path = path

    def log(self, tag: str, message: str):
        ts = now_iso()
        line = f"{ts} [{tag:<12s}] {message}\n"
        with open(self.path, "a", encoding="utf-8") as f:
            f.write(line)
        # Also print to console
        print(line.rstrip())


# ---------------------------------------------------------------------------
# Config helpers
# ---------------------------------------------------------------------------

def get_model(config: dict, agent_slug: str) -> str:
    overrides = config["models"].get("overrides", {})
    return overrides.get(agent_slug, config["models"]["default_worker"])


def get_budget(config: dict, agent_slug: str) -> float:
    overrides = config["budgets"].get("overrides", {})
    return overrides.get(agent_slug, config["budgets"]["default_worker_usd"])


def get_timeout(config: dict, agent_slug: str) -> int:
    overrides = config["timeouts"].get("overrides", {})
    return overrides.get(agent_slug, config["timeouts"]["default_minutes"])


def read_ticket_status(ticket_id: str, milestone: str) -> str:
    """Read a ticket file and return its status field.

    Parses YAML frontmatter from tickets/{milestone}/{ticket_id}.md.
    Returns 'UNKNOWN' if the file doesn't exist or can't be parsed.
    """
    ticket_path = REPO_ROOT / "tickets" / milestone / f"{ticket_id}.md"
    if not ticket_path.exists():
        # Try lowercase milestone folder
        ticket_path = REPO_ROOT / "tickets" / milestone.lower() / f"{ticket_id}.md"
    if not ticket_path.exists():
        return "UNKNOWN"
    try:
        text = ticket_path.read_text(encoding="utf-8")
        for line in text.splitlines()[:30]:
            m = re.match(r'^status:\s*["\']?(\S+?)["\']?\s*$', line)
            if m:
                return m.group(1).upper()
    except Exception:
        pass
    return "UNKNOWN"


def validate_dependencies(
    ticket_id: str,
    milestone: str,
    completed_this_session: list[str] | None = None,
) -> tuple[bool, list[str]]:
    """Check that all depends_on entries for a ticket are DONE.

    Returns (True, []) if all deps are satisfied, or
    (False, [list of unmet dep IDs]) otherwise.
    Tickets in completed_this_session are treated as DONE regardless of
    filesystem status (handles race between commit and git pull).
    """
    completed_set = set(completed_this_session or [])

    ticket_path = REPO_ROOT / "tickets" / milestone / f"{ticket_id}.md"
    if not ticket_path.exists():
        ticket_path = REPO_ROOT / "tickets" / milestone.lower() / f"{ticket_id}.md"
    if not ticket_path.exists():
        # Can't validate — assume OK
        return (True, [])

    try:
        text = ticket_path.read_text(encoding="utf-8")
    except Exception:
        return (True, [])

    # Extract depends_on list from YAML frontmatter
    depends_on: list[str] = []
    dep_match = re.search(r'^depends_on:\s*\[(.*?)\]', text, re.MULTILINE)
    if dep_match:
        raw = dep_match.group(1).strip()
        if raw:
            depends_on = [
                d.strip().strip("\"'") for d in raw.split(",") if d.strip()
            ]

    if not depends_on:
        return (True, [])

    unmet = []
    for dep_id in depends_on:
        if dep_id in completed_set:
            continue
        status = read_ticket_status(dep_id, milestone)
        if status != "DONE":
            unmet.append(dep_id)

    return (len(unmet) == 0, unmet)


def write_ticket_file(
    ticket_data: dict,
    milestone: str,
    wave_number: int,
    logger: "ActivityLogger",
) -> bool:
    """Write a new ticket file from a new_tickets entry.

    Returns True if the ticket was written, False if skipped.
    Performs duplicate and collision checks before writing.
    """
    ticket_id = ticket_data["id"]
    milestone_dir = REPO_ROOT / "tickets" / milestone.lower()
    target_path = milestone_dir / f"{ticket_id}.md"

    # Duplicate guard: exact file path
    if target_path.exists():
        logger.log("WARNING", f"{ticket_id} already exists — skipping ticket creation")
        return False

    # Next-ID collision: check all milestone directories
    tickets_root = REPO_ROOT / "tickets"
    for ticket_file in tickets_root.glob(f"**/{ticket_id}.md"):
        logger.log("WARNING",
            f"{ticket_id} collides with existing {ticket_file} — skipping ticket creation")
        return False

    # Ensure milestone directory exists
    milestone_dir.mkdir(parents=True, exist_ok=True)

    # Build frontmatter
    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    depends_on = ticket_data.get("depends_on", [])
    depends_str = ", ".join(depends_on) if depends_on else ""

    frontmatter = f"""---
id: {ticket_id}
title: "{ticket_data['title']}"
type: {ticket_data['type']}
status: OPEN
priority: {ticket_data['priority']}
owner: {ticket_data['owner']}
created_by: producer
created_at: {today}
updated_at: {today}
milestone: "{milestone}"
phase: "{ticket_data['phase']}"
depends_on: [{depends_str}]
blocks: []
tags: [auto-created]
---"""

    # Build acceptance criteria
    ac_lines = "\n".join(
        f"- [ ] {criterion}" for criterion in ticket_data["acceptance_criteria"]
    )

    content = f"""{frontmatter}

## Summary

{ticket_data['summary']}

## Acceptance Criteria

{ac_lines}

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- {today} [conductor] Created via orchestration wave {wave_number}
"""

    target_path.write_text(content, encoding="utf-8")
    return True


def get_blocked_tools(config: dict, agent_slug: str) -> list[str]:
    """Return list of Godot MCP tool names this agent is NOT allowed to use."""
    tiers = config.get("tool_tiers", {})

    if agent_slug in tiers.get("0", []):
        return ALL_GODOT_TOOLS
    elif agent_slug in tiers.get("1", []):
        return TIER_2_TOOLS + TIER_3_TOOLS
    elif agent_slug in tiers.get("2", []):
        return TIER_3_TOOLS
    elif agent_slug in tiers.get("3", []):
        return []
    else:
        # Unknown agent — block all Godot tools as a safety default
        return ALL_GODOT_TOOLS


# ---------------------------------------------------------------------------
# State management
# ---------------------------------------------------------------------------

def detect_starting_phase(milestone: str) -> str:
    """Return the phase of the earliest non-DONE ticket for the milestone.

    Ticket files are sorted by name (which encodes ID order), so the first
    non-DONE ticket determines which phase the conductor should start in.
    Falls back to "Foundation" if all tickets are DONE or none are found.
    """
    tickets_dir = REPO_ROOT / "tickets" / milestone.lower()
    if not tickets_dir.exists():
        return "Foundation"

    status_re = re.compile(r'^status:\s*["\']?(\w+)["\']?', re.MULTILINE)
    phase_re = re.compile(r'^phase:\s*["\']?([^"\'\\n]+?)["\']?\s*$', re.MULTILINE)

    for ticket_file in sorted(tickets_dir.glob("TICKET-*.md")):
        text = ticket_file.read_text(encoding="utf-8")
        status_match = status_re.search(text)
        if not status_match or status_match.group(1).upper() == "DONE":
            continue
        phase_match = phase_re.search(text)
        if phase_match:
            return phase_match.group(1).strip()

    return "Foundation"


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


def load_state(state_path: Path) -> dict:
    if state_path.exists():
        return load_json(state_path)
    return None


def save_state(state: dict, state_path: Path):
    write_json(state_path, state)


# ---------------------------------------------------------------------------
# Worktree helpers
# ---------------------------------------------------------------------------

def create_worktree(agent_slug: str, ticket_id: str) -> tuple[Path, str]:
    """Create a git worktree for the worker. Returns (worktree_path, branch_name)."""
    safe_slug = agent_slug.replace("/", "-")
    safe_ticket = ticket_id.replace("/", "-")
    worktree_name = f"orch-{safe_slug}-{safe_ticket}"
    branch_name = f"orch/{agent_slug}/{ticket_id}"
    worktree_path = WORKTREES_DIR / worktree_name

    if worktree_path.exists():
        # Clean up stale worktree
        subprocess.run(
            ["git", "worktree", "remove", "--force", str(worktree_path)],
            cwd=str(REPO_ROOT), capture_output=True
        )

    # Delete the branch if it exists (leftover from a previous attempt)
    subprocess.run(
        ["git", "branch", "-D", branch_name],
        cwd=str(REPO_ROOT), capture_output=True
    )

    # Create worktree with new branch from HEAD
    result = subprocess.run(
        ["git", "worktree", "add", "-b", branch_name, str(worktree_path)],
        cwd=str(REPO_ROOT), capture_output=True, text=True
    )
    if result.returncode != 0:
        raise RuntimeError(f"Failed to create worktree: {result.stderr}")

    return worktree_path, branch_name


def remove_worktree(worktree_path: Path, branch_name: str):
    """Remove a worktree and its branch."""
    subprocess.run(
        ["git", "worktree", "remove", "--force", str(worktree_path)],
        cwd=str(REPO_ROOT), capture_output=True
    )
    subprocess.run(
        ["git", "branch", "-D", branch_name],
        cwd=str(REPO_ROOT), capture_output=True
    )


# ---------------------------------------------------------------------------
# Prompt rendering
# ---------------------------------------------------------------------------

def render_template(template_path: Path, variables: dict) -> str:
    """Simple {variable} substitution in a template file."""
    text = template_path.read_text(encoding="utf-8")
    for key, value in variables.items():
        text = text.replace(f"{{{key}}}", str(value))
    return text


# ---------------------------------------------------------------------------
# Claude CLI interface
# ---------------------------------------------------------------------------

async def run_claude(
    prompt: str,
    model: str,
    budget: float,
    blocked_tools: list[str],
    agent_claude_md: Path | None = None,
    output_json: bool = True,
    json_schema: dict | None = None,
    cwd: Path | None = None,
    timeout_minutes: int = 30,
    log_path: Path | None = None,
    on_proc_start: callable = None,
) -> tuple[int, str, str, dict]:
    """Run claude -p as a subprocess. Returns (exit_code, stdout, stderr, usage_meta)."""
    cmd = ["claude", "-p", "--model", model, "--verbose"]

    if budget > 0:
        cmd.extend(["--max-turns", "200"])

    if blocked_tools:
        cmd.extend(["--disallowed-tools", ",".join(blocked_tools)])

    if output_json:
        cmd.extend(["--output-format", "json"])

    if json_schema:
        cmd.extend(["--output-format", "stream-json"])

    if agent_claude_md and agent_claude_md.exists():
        agent_context = agent_claude_md.read_text(encoding="utf-8")
        cmd.extend(["--append-system-prompt", agent_context])

    cmd.extend(["--dangerously-skip-permissions"])

    # The prompt goes last
    cmd.append(prompt)

    effective_cwd = str(cwd) if cwd else str(REPO_ROOT)
    timeout_seconds = timeout_minutes * 60

    if log_path:
        log_path.parent.mkdir(parents=True, exist_ok=True)
        log_file = open(log_path, "w", encoding="utf-8")
    else:
        log_file = None

    try:
        call_start = time.time()
        proc = await asyncio.create_subprocess_exec(
            *cmd,
            cwd=effective_cwd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )

        if on_proc_start:
            on_proc_start(proc)

        try:
            stdout_bytes, stderr_bytes = await asyncio.wait_for(
                proc.communicate(), timeout=timeout_seconds
            )
        except asyncio.TimeoutError:
            proc.kill()
            await proc.communicate()
            return (-1, "", f"TIMEOUT after {timeout_minutes}m", {})
        duration_seconds = time.time() - call_start

        stdout = stdout_bytes.decode("utf-8", errors="replace")
        stderr = stderr_bytes.decode("utf-8", errors="replace")

        if log_file:
            log_file.write(f"=== STDOUT ===\n{stdout}\n")
            log_file.write(f"=== STDERR ===\n{stderr}\n")
            log_file.write(f"=== EXIT CODE: {proc.returncode} ===\n")

        usage_meta = extract_usage_from_output(stdout)
        usage_meta["duration_seconds"] = duration_seconds

        return (proc.returncode, stdout, stderr, usage_meta)

    finally:
        if log_file:
            log_file.close()


def extract_json_from_output(output: str) -> dict:
    """Extract JSON from Claude output, handling potential wrapper text.

    Handles several output shapes:
    - Plain JSON object string
    - JSON object wrapped in markdown code fences
    - ``--output-format json`` stream array (list of message dicts) where
      the final element has ``type: "result"`` and ``result`` holds the
      assistant's text response (which itself may be wrapped in fences).
    """
    output = output.strip()

    # Try direct parse first
    try:
        parsed = json.loads(output)
        if isinstance(parsed, dict):
            return parsed
        # --output-format json produces a JSON array of message objects.
        # Find the 'result' entry and extract the assistant text from it.
        if isinstance(parsed, list):
            for item in reversed(parsed):
                if isinstance(item, dict) and item.get("type") == "result":
                    inner = item.get("result", "")
                    if isinstance(inner, dict):
                        return inner
                    if isinstance(inner, str):
                        return _extract_dict_from_text(inner)
            # No 'result' entry — fall through to brace extraction on raw text
    except json.JSONDecodeError:
        pass

    return _extract_dict_from_text(output)


def extract_usage_from_output(stdout: str) -> dict:
    """Parse token/model/stop_reason usage metadata from Claude CLI JSON stdout.

    Returns a dict with keys: input_tokens, output_tokens, model, stop_reason.
    Returns empty dict on any parse failure — never crashes the caller.
    """
    if not stdout or not stdout.strip():
        return {}
    try:
        parsed = json.loads(stdout.strip())
    except (json.JSONDecodeError, ValueError):
        return {}

    # --output-format json produces a JSON array of message objects.
    # The result item contains usage data.
    if isinstance(parsed, list):
        for item in reversed(parsed):
            if not isinstance(item, dict):
                continue
            if item.get("type") == "result":
                usage = {}
                raw_usage = item.get("usage", {})
                if isinstance(raw_usage, dict):
                    if "input_tokens" in raw_usage:
                        usage["input_tokens"] = raw_usage["input_tokens"]
                    if "output_tokens" in raw_usage:
                        usage["output_tokens"] = raw_usage["output_tokens"]
                if "model" in item:
                    usage["model"] = item["model"]
                if "stop_reason" in item:
                    usage["stop_reason"] = item["stop_reason"]
                return usage
    elif isinstance(parsed, dict):
        usage = {}
        raw_usage = parsed.get("usage", {})
        if isinstance(raw_usage, dict):
            if "input_tokens" in raw_usage:
                usage["input_tokens"] = raw_usage["input_tokens"]
            if "output_tokens" in raw_usage:
                usage["output_tokens"] = raw_usage["output_tokens"]
        if "model" in parsed:
            usage["model"] = parsed["model"]
        if "stop_reason" in parsed:
            usage["stop_reason"] = parsed["stop_reason"]
        return usage

    return {}


def _extract_dict_from_text(text: str) -> dict:
    """Extract a JSON object from free-form text (handles code fences, etc.)."""
    text = text.strip()

    # Direct parse
    try:
        result = json.loads(text)
        if isinstance(result, dict):
            return result
    except json.JSONDecodeError:
        pass

    # Look for the outermost { ... }
    brace_start = text.find("{")
    brace_end = text.rfind("}")
    if brace_start != -1 and brace_end != -1 and brace_end > brace_start:
        try:
            result = json.loads(text[brace_start:brace_end + 1])
            if isinstance(result, dict):
                return result
        except json.JSONDecodeError:
            pass

    raise ValueError(f"Could not extract JSON object from output: {text[:200]}...")


# ---------------------------------------------------------------------------
# Windows toast notification
# ---------------------------------------------------------------------------

def fire_toast(title: str, message: str):
    """Send a Windows toast notification via PowerShell."""
    if platform.system() != "Windows":
        return
    try:
        ps_script = f"""
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
        $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
        $xml.LoadXml('<toast><visual><binding template="ToastText02"><text id="1">{title}</text><text id="2">{message}</text></binding></visual></toast>')
        $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("Hammer Forge Studio").Show($toast)
        """
        subprocess.Popen(
            ["powershell", "-NoProfile", "-Command", ps_script],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )
    except Exception:
        pass  # Best-effort notification


# ---------------------------------------------------------------------------
# Conductor
# ---------------------------------------------------------------------------

class Conductor:
    def __init__(self, paths: InstancePaths, config: dict, run_claude_fn=None):
        self.paths = paths
        self.config = config
        self.logger = ActivityLogger(paths.activity_log)
        self.shutdown_requested = False
        self._active_procs: set[asyncio.subprocess.Process] = set()
        self._run_claude = run_claude_fn or run_claude

        # Auto-resume from saved state if it exists
        self.state = load_state(paths.state_path)
        if self.state is not None:
            self.logger.log("SYSTEM", "Resumed from saved state")

        # Warn if plan_limits is absent — conductor uses defaults; reporting will lack capacity gauges
        if "plan_limits" not in self.config:
            print(
                "WARNING: 'plan_limits' section missing from config.json. "
                "Capacity reporting will use defaults "
                "(plan_tier='Max 20', five_hour_output_token_limit=220000, "
                "weekly_output_token_limit=3080000). "
                "Add a 'plan_limits' section to orchestrator/config.json to silence this warning.",
                file=sys.stderr,
            )

        # Ensure output dirs exist
        paths.results_dir.mkdir(parents=True, exist_ok=True)
        paths.logs_dir.mkdir(parents=True, exist_ok=True)

    def _track_proc(self, proc: asyncio.subprocess.Process):
        """Callback to track active subprocesses for shutdown."""
        self._active_procs.add(proc)

    def setup_signal_handlers(self):
        """Catch Ctrl+C for graceful shutdown."""
        def handler(sig, frame):
            self.logger.log("SYSTEM", "Shutdown requested (SIGINT)")
            self.shutdown_requested = True
            for proc in list(self._active_procs):
                if proc.returncode is None:
                    try:
                        proc.kill()
                    except ProcessLookupError:
                        pass
        signal.signal(signal.SIGINT, handler)

    async def run(self, milestone: str, phase: str):
        """Main orchestration loop."""
        if self.state is None:
            self.state = create_initial_state(milestone, phase)
            save_state(self.state, self.paths.state_path)

        self.setup_signal_handlers()
        self.logger.log("SYSTEM",
            f"Started (milestone={self.state['milestone']}, phase={self.state['phase']})")

        while not self.shutdown_requested:
            status = self.state["status"]

            if status == "PLANNING":
                await self._do_planning()

            elif status == "DISPATCHING":
                await self._do_dispatching()

            elif status == "WORKING":
                await self._do_working()

            elif status == "EVALUATING":
                await self._do_evaluating()

            elif status == "GATE_BLOCKED":
                await self._do_gate_blocked()

            elif status == "HALTED":
                self.logger.log("HALTED",
                    "System halted. Run with --resume after resolving the issue.")
                break

            elif status == "IDLE":
                self.logger.log("SYSTEM", "Idle — no more work.")
                break

            else:
                self.logger.log("ERROR", f"Unknown state: {status}")
                self.state["status"] = "HALTED"

            save_state(self.state, self.paths.state_path)

            if self.shutdown_requested:
                self.logger.log("SYSTEM", "Graceful shutdown — saving state.")
                save_state(self.state, self.paths.state_path)
                break

        self.logger.log("SYSTEM", "Conductor exiting.")

    # ------------------------------------------------------------------
    # PLANNING
    # ------------------------------------------------------------------

    async def _do_planning(self):
        """Ask the Producer for the next wave plan."""
        # Pull latest to pick up ticket status changes from worker commits
        pull_result = subprocess.run(
            ["git", "-C", str(REPO_ROOT), "pull"],
            capture_output=True, text=True, check=False,
        )
        if pull_result.returncode == 0:
            self.logger.log("PLAN", "git pull OK")
            # Fix 2: After a successful pull, sweep completed_this_session and evict
            # any ticket whose file doesn't read DONE. This catches cases where a
            # previous wave's agent self-reported done without updating the ticket file.
            self._verify_session_completions()
        else:
            self.logger.log("WARNING",
                f"git pull failed (exit={pull_result.returncode}): "
                f"{pull_result.stderr.strip()[:200]}")

        self.state["wave_number"] += 1
        wave_num = self.state["wave_number"]

        self.logger.log("PLAN", f"Requesting wave {wave_num} plan from Producer...")

        # Build prompt
        retry_tickets = [
            tid for tid, count in self.state.get("retries", {}).items()
            if count > 0
        ]
        active_ticket_ids = self.state.get("active_ticket_ids", [])
        completed_this_session = self.state.get("completed_this_session", [])
        template_vars = {
            "milestone": self.state["milestone"],
            "phase": self.state["phase"],
            "wave_number": str(wave_num),
            "retry_tickets": json.dumps(retry_tickets) if retry_tickets else "none",
            "completed_waves": json.dumps(self.state.get("completed_waves", [])),
            "max_parallel": str(self.config["concurrency"]["max_parallel_workers"]),
            "active_ticket_ids": json.dumps(active_ticket_ids),
            "completed_this_session": json.dumps(completed_this_session),
        }
        prompt = render_template(self.paths.prompts_dir / "plan_wave.md", template_vars)

        # Call Producer
        model = self.config["models"]["producer"]
        budget = self.config["budgets"]["producer_usd"]
        blocked = get_blocked_tools(self.config, "producer")

        exit_code, stdout, stderr, _usage = await self._run_claude(
            prompt=prompt,
            model=model,
            budget=budget,
            blocked_tools=blocked,
            output_json=True,
            cwd=REPO_ROOT,
            timeout_minutes=10,
            log_path=self.paths.logs_dir / f"producer-wave{wave_num}-{now_iso().replace(':', '')}.log",
            on_proc_start=self._track_proc,
        )

        if exit_code != 0:
            self.logger.log("ERROR", f"Producer exited with code {exit_code}: {stderr[:200]}")
            # Retry up to 3 times
            if self.state.get("_producer_retries", 0) < 3:
                self.state["_producer_retries"] = self.state.get("_producer_retries", 0) + 1
                self.logger.log("RETRY", f"Retrying Producer (attempt {self.state['_producer_retries']}/3)")
                self.state["wave_number"] -= 1  # Don't increment wave on retry
                return
            self.logger.log("ERROR", "Producer failed 3 times. Halting.")
            self.state["status"] = "HALTED"
            return

        self.state.pop("_producer_retries", None)

        # Parse plan
        try:
            plan = extract_json_from_output(stdout)
        except ValueError as e:
            self.logger.log("ERROR", f"Failed to parse Producer JSON: {e}")
            self.state["status"] = "HALTED"
            return

        action = plan.get("action", "error")
        summary = plan.get("summary", "")
        self.logger.log("PLAN", f"Wave {wave_num} action={action}: {summary}")

        if action == "spawn_agents":
            # Accept "wave" or "workers" (LLM sometimes uses the wrong key)
            wave = plan.get("wave") or plan.get("workers") or []
            # Normalize item keys: "ticket_id" -> "ticket"
            for item in wave:
                if "ticket_id" in item and "ticket" not in item:
                    item["ticket"] = item.pop("ticket_id")
            if not wave:
                self.logger.log("PLAN", "Empty wave — treating as no_work.")
                self.state["status"] = "IDLE"
                return
            # Store wave plan for dispatching
            self.state["_pending_wave"] = wave
            # Store any new tickets the producer wants to create
            new_tickets = plan.get("new_tickets")
            if new_tickets:
                self.state["_pending_new_tickets"] = new_tickets
            assignments = ", ".join(
                f"{a['ticket']}->{a['agent']}" for a in wave
            )
            self.logger.log("PLAN",
                f"Wave {wave_num}: {len(wave)} assignments [{assignments}]")
            self.state["status"] = "DISPATCHING"

        elif action == "gate_blocked":
            gate = plan.get("gate", {})
            self.state["status"] = "GATE_BLOCKED"
            self.state["_pending_gate"] = gate
            self.logger.log("GATE",
                f"Phase \"{gate.get('phase', '?')}\" complete — awaiting approval")

        elif action == "no_work":
            self.logger.log("PLAN", "No workable tickets. Idling.")
            self.state["status"] = "IDLE"

        elif action == "milestone_complete":
            self.logger.log("SYSTEM",
                f"Milestone {self.state['milestone']} complete!")
            self.state["status"] = "IDLE"

        elif action == "error":
            self.logger.log("ERROR", f"Producer reported error: {summary}")
            self.state["status"] = "HALTED"

    # ------------------------------------------------------------------
    # SESSION COMPLETION VERIFICATION
    # ------------------------------------------------------------------

    def _verify_session_completions(self) -> list[str]:
        """Fix 2: Re-verify completed_this_session against ticket files after a git pull.

        Evicts any ticket that doesn't read DONE from the filesystem.
        Returns the list of evicted ticket IDs so the caller can log them.
        The Producer will naturally re-plan evicted tickets on the next wave.
        Does NOT increment retry counters — eviction is not a failure, it is
        a correction for tickets the agent forgot to mark DONE.
        """
        milestone = self.state.get("milestone", "")
        session_done = self.state.get("completed_this_session", [])
        still_valid = []
        evicted = []

        for ticket_id in session_done:
            file_status = read_ticket_status(ticket_id, milestone)
            if file_status == "DONE":
                still_valid.append(ticket_id)
            else:
                self.logger.log("WARNING",
                    f"Session-completion mismatch: {ticket_id} was recorded as done "
                    f"but ticket file reads {file_status} — evicting from session set")
                evicted.append(ticket_id)

        if evicted:
            self.state["completed_this_session"] = still_valid
            self.logger.log("WARNING",
                f"Evicted {len(evicted)} ticket(s) from completed_this_session: "
                + ", ".join(evicted))

        return evicted

    # ------------------------------------------------------------------
    # DISPATCHING
    # ------------------------------------------------------------------

    async def _do_dispatching(self):
        """Create worktrees and spawn workers for the planned wave."""
        wave = self.state.pop("_pending_wave", [])
        if not wave:
            self.state["status"] = "PLANNING"
            return

        # Process pending new tickets before spawning workers
        pending_tickets = self.state.pop("_pending_new_tickets", [])
        for ticket_data in pending_tickets:
            tid = ticket_data.get("id", "UNKNOWN")
            title = ticket_data.get("title", "")
            written = write_ticket_file(
                ticket_data,
                self.state["milestone"],
                self.state["wave_number"],
                self.logger,
            )
            if written:
                self.logger.log("TICKET", f"Created {tid}: {title}")

        active_locks = self.state.get("active_ticket_ids", [])

        workers = []
        deferred = []  # Godot MCP workers deferred due to lock contention
        godot_lock_acquired_for = None  # ticket_id that holds the lock this wave

        for assignment in wave:
            agent_slug = assignment["agent"]
            ticket_id = assignment["ticket"]

            # Dispatch guard: skip tickets already locked
            if ticket_id in active_locks:
                self.logger.log("WARNING",
                    f"{ticket_id} already in active_ticket_ids — skipping duplicate dispatch")
                continue

            # Dependency validation: skip if depends_on not satisfied
            completed = self.state.get("completed_this_session", [])
            deps_ok, unmet = validate_dependencies(
                ticket_id, self.state["milestone"], completed
            )
            if not deps_ok:
                for dep in unmet:
                    self.logger.log("SKIP",
                        f"{ticket_id} dependency unmet — {dep} is not DONE "
                        "(producer planning error)")
                continue

            budget = assignment.get("budget_usd", get_budget(self.config, agent_slug))
            needs_worktree = assignment.get("needs_worktree", True)
            needs_godot = assignment.get("needs_godot_mcp", False)
            supplement = assignment.get("prompt_supplement", "")

            # Godot MCP concurrency gate: only one worker may hold the lock
            if needs_godot:
                if godot_lock_acquired_for is not None:
                    # Another worker in this wave already holds the lock — defer
                    self.logger.log("INFO",
                        f"Deferred {ticket_id} — Godot MCP lock held by "
                        f"{godot_lock_acquired_for}")
                    deferred.append(assignment)
                    continue

                acquired = acquire_godot_mcp_lock(
                    ticket_id, agent_slug,
                    self.state["wave_number"],
                    self.paths.godot_mcp_lock_path, self.logger,
                )
                if not acquired:
                    lock_data = read_godot_mcp_lock(self.paths.godot_mcp_lock_path)
                    holder = lock_data["holder"] if lock_data else "unknown"
                    self.logger.log("INFO",
                        f"Deferred {ticket_id} — Godot MCP lock held by {holder}")
                    deferred.append(assignment)
                    continue

                godot_lock_acquired_for = ticket_id

            # Create worktree if needed
            worktree_path = None
            branch_name = None
            if needs_worktree:
                try:
                    worktree_path, branch_name = create_worktree(agent_slug, ticket_id)
                except RuntimeError as e:
                    self.logger.log("ERROR", f"Worktree creation failed for {ticket_id}: {e}")
                    # Release Godot MCP lock if this worker held it
                    if needs_godot and godot_lock_acquired_for == ticket_id:
                        release_godot_mcp_lock(self.paths.godot_mcp_lock_path, self.logger)
                        godot_lock_acquired_for = None
                    continue

            workers.append({
                "agent": agent_slug,
                "ticket": ticket_id,
                "budget_usd": budget,
                "needs_worktree": needs_worktree,
                "needs_godot_mcp": needs_godot,
                "worktree_path": str(worktree_path) if worktree_path else None,
                "branch": branch_name,
                "prompt_supplement": supplement,
                "started_at": now_iso(),
            })

        # Re-queue deferred Godot MCP workers for the next planning cycle
        if deferred:
            pending = self.state.setdefault("_pending_wave", [])
            pending.extend(deferred)
            save_state(self.state, self.paths.state_path)

        # Populate active ticket locks
        self.state["active_ticket_ids"] = [w["ticket"] for w in workers]
        if self.state["active_ticket_ids"]:
            self.logger.log("LOCK",
                f"Locked tickets: {', '.join(self.state['active_ticket_ids'])}")

        self.state["active_workers"] = workers
        self.state["status"] = "WORKING"
        save_state(self.state, self.paths.state_path)

    # ------------------------------------------------------------------
    # WORKING
    # ------------------------------------------------------------------

    async def _do_working(self):
        """Spawn all workers concurrently and wait for them to complete."""
        workers = self.state.get("active_workers", [])
        if not workers:
            self.state["status"] = "EVALUATING"
            return

        tasks = []
        for worker in workers:
            task = asyncio.create_task(self._run_worker(worker))
            tasks.append((worker, task))

        # Wait for all workers
        results = []
        for worker, task in tasks:
            result = await task
            results.append((worker, result))

        # Process results
        wave_tickets = []
        all_succeeded = True
        any_new_gd = False

        for worker, (exit_code, stdout, stderr, _usage_meta) in results:
            agent = worker["agent"]
            ticket = worker["ticket"]

            # Release ticket lock (defensive — only remove if present)
            active_locks = self.state.get("active_ticket_ids", [])
            if ticket in active_locks:
                active_locks.remove(ticket)
                self.state["active_ticket_ids"] = active_locks
                save_state(self.state, self.paths.state_path)

            # Release Godot MCP lock if this worker held it
            if worker.get("needs_godot_mcp", False):
                release_godot_mcp_lock(self.paths.godot_mcp_lock_path, self.logger)

            if exit_code == 0:
                if not stdout.strip():
                    self.logger.log("CRASH",
                        f"{agent} <- {ticket}: exit=0 but empty stdout — treating as failed")
                    all_succeeded = False
                    self._queue_retry(ticket)
                    continue

                # Try to parse result
                try:
                    result_data = extract_json_from_output(stdout)
                    # Normalize outcome: "completed" is a common agent synonym for "done"
                    outcome = result_data.get("outcome", "unknown")
                    if outcome == "completed":
                        outcome = "done"
                        result_data["outcome"] = "done"
                    if result_data.get("new_gd_scripts", False):
                        any_new_gd = True

                    # Save result file
                    result_path = self.paths.results_dir / f"{ticket}.json"
                    write_json(result_path, result_data)

                    if outcome == "done":
                        # Fix 1: Verify the ticket file actually reads DONE before
                        # trusting the agent's self-report. If the file disagrees,
                        # the agent forgot to update status — retry so it finishes.
                        file_status = read_ticket_status(ticket, self.state["milestone"])
                        if file_status != "DONE":
                            self.logger.log("WARNING",
                                f"{agent} <- {ticket}: outcome=done but ticket file "
                                f"reads {file_status} — treating as PARTIAL, queuing retry")
                            all_succeeded = False
                            self._queue_retry(ticket)
                        else:
                            self.logger.log("DONE", f"{agent} <- {ticket}")
                            wave_tickets.append(ticket)
                            # Track session-completed tickets for dependency validation
                            session_done = self.state.setdefault("completed_this_session", [])
                            if ticket not in session_done:
                                session_done.append(ticket)
                    elif outcome == "blocked":
                        self.logger.log("BLOCKED", f"{agent} <- {ticket}: {result_data.get('summary', '')}")
                        all_succeeded = False
                    else:
                        self.logger.log("PARTIAL", f"{agent} <- {ticket}: outcome={outcome}")
                        all_succeeded = False
                        self._queue_retry(ticket)
                except ValueError:
                    self.logger.log("DONE", f"{agent} <- {ticket} (no structured output)")
                    wave_tickets.append(ticket)
            elif exit_code == -1:
                self.logger.log("TIMEOUT", f"{agent} <- {ticket}: {stderr}")
                all_succeeded = False
                self._queue_retry(ticket)
            else:
                empty = not stdout.strip() and not stderr.strip()
                label = "CRASH" if empty else "FAILED"
                self.logger.log(label,
                    f"{agent} <- {ticket} (exit={exit_code}"
                    + (", empty output — possible crash/signal" if empty else "") + ")")
                all_succeeded = False
                self._queue_retry(ticket)

        # Record completed wave
        self.state["completed_waves"].append({
            "wave": self.state["wave_number"],
            "tickets": wave_tickets,
            "completed_at": now_iso(),
        })
        self.state["_any_new_gd"] = any_new_gd
        self.state["active_workers"] = []

        status_msg = f"Wave {self.state['wave_number']} complete: "
        status_msg += f"{len(wave_tickets)}/{len(results)} succeeded"
        self.logger.log("WAVE", status_msg)

        self.state["status"] = "EVALUATING"

    async def _run_worker(self, worker: dict) -> tuple[int, str, str, dict]:
        """Run a single worker agent."""
        agent_slug = worker["agent"]
        ticket_id = worker["ticket"]
        budget = worker["budget_usd"]
        supplement = worker.get("prompt_supplement", "")

        # Build worker prompt
        template_vars = {
            "agent_name": agent_slug.replace("-", " ").title(),
            "agent_slug": agent_slug,
            "ticket_id": ticket_id,
            "milestone": self.state["milestone"],
            "ticket_title": ticket_id,  # Will be refined by the agent after reading
            "prompt_supplement": supplement if supplement else "No additional notes.",
        }
        prompt = render_template(self.paths.prompts_dir / "worker_dispatch.md", template_vars)

        # Determine working directory
        cwd = Path(worker["worktree_path"]) if worker.get("worktree_path") else REPO_ROOT

        # Preflight: verify worktree is accessible before dispatching
        if worker.get("worktree_path"):
            if not cwd.exists():
                self.logger.log("ERROR",
                    f"Worktree {cwd} does not exist — aborting {ticket_id}")
                return (-2, "", "worktree missing", {})
            status_check = subprocess.run(
                ["git", "status", "--porcelain"],
                cwd=str(cwd), capture_output=True, text=True
            )
            if status_check.returncode != 0:
                self.logger.log("ERROR",
                    f"Worktree {cwd} git status failed — aborting {ticket_id}")
                return (-2, "", "worktree git error", {})

        # Agent CLAUDE.md
        agent_md = AGENTS_DIR / agent_slug / "CLAUDE.md"

        # Blocked tools
        blocked = get_blocked_tools(self.config, agent_slug)

        # Timeout
        timeout = get_timeout(self.config, agent_slug)

        # Model
        model = get_model(self.config, agent_slug)

        ts = now_iso().replace(":", "")
        log_path = self.paths.logs_dir / f"{agent_slug}-{ticket_id}-{ts}.log"

        self.logger.log("DISPATCH",
            f"{agent_slug} -> {ticket_id} (model={model}, budget={format_cost(budget)})")

        start = time.time()
        exit_code, stdout, stderr, usage_meta = await self._run_claude(
            prompt=prompt,
            model=model,
            budget=budget,
            blocked_tools=blocked,
            agent_claude_md=agent_md,
            output_json=True,
            cwd=cwd,
            timeout_minutes=timeout,
            log_path=log_path,
            on_proc_start=self._track_proc,
        )
        elapsed = time.time() - start

        self.logger.log(
            "DONE" if exit_code == 0 else "FAILED",
            f"{agent_slug} <- {ticket_id} ({format_duration(elapsed)}, exit={exit_code})"
        )

        return (exit_code, stdout, stderr, usage_meta)

    def _queue_retry(self, ticket_id: str):
        """Queue a ticket for retry if under the max retry count."""
        max_retries = self.config["retries"]["max_per_ticket"]
        current = self.state.get("retries", {}).get(ticket_id, 0)
        if current < max_retries:
            self.state.setdefault("retries", {})[ticket_id] = current + 1
            self.logger.log("RETRY",
                f"{ticket_id} queued for retry (attempt {current + 1}/{max_retries})")
        else:
            self.logger.log("ERROR",
                f"{ticket_id} exceeded max retries ({max_retries}). Halting.")
            self.state["status"] = "HALTED"

    # ------------------------------------------------------------------
    # EVALUATING
    # ------------------------------------------------------------------

    async def _do_evaluating(self):
        """Merge branches and clean up after a wave."""
        completed = self.state.get("completed_waves", [])
        if not completed:
            self.state["status"] = "PLANNING"
            return

        last_wave = completed[-1]

        # Merge branches from workers that used worktrees
        # We need to look at the active_workers snapshot before it was cleared
        # For now, attempt to merge any orch/* branches that exist
        await self._merge_pending_branches()

        # Handle UID commits if any new .gd scripts were created
        if self.state.pop("_any_new_gd", False):
            await self._handle_uid_commits()

        # Check budget ceiling
        if self.state["total_cost_usd"] >= self.config["budgets"]["session_ceiling_usd"]:
            self.logger.log("BUDGET",
                f"Session ceiling reached ({format_cost(self.state['total_cost_usd'])}). Halting.")
            self.state["status"] = "HALTED"
            return

        # Continue to next planning cycle
        self.state["status"] = "PLANNING"

    async def _merge_pending_branches(self):
        """Clean up orch worktrees and branches after workers self-merged via GitHub PR.

        Workers push their branch and self-merge via PR. This step only needs to:
        1. Remove worktrees (must happen before branch deletion)
        2. Pull latest main (to pick up PR merges)
        3. Delete local orch/* branches

        No local git merge is performed here — that was the source of the double-merge
        conflict (TICKET-0135). Branch parsing also strips *, +, and space prefixes
        that git adds for current-branch and worktree-checked-out decorations (TICKET-0134).
        """
        # List orch/* branches, stripping *, +, and space prefix decorations.
        result = subprocess.run(
            ["git", "branch", "--list", "orch/*"],
            cwd=str(REPO_ROOT), capture_output=True, text=True
        )
        branches = [
            re.sub(r'^[*+ ]+', '', b.strip())
            for b in result.stdout.splitlines() if b.strip()
        ]
        branches = [b for b in branches if b]

        if not branches:
            return

        # Build branch -> worktree_path map from porcelain output.
        # Porcelain format (blocks separated by blank lines):
        #   worktree /path/to/wt
        #   HEAD <hash>
        #   branch refs/heads/<name>
        wt_result = subprocess.run(
            ["git", "worktree", "list", "--porcelain"],
            cwd=str(REPO_ROOT), capture_output=True, text=True
        )
        worktree_map: dict[str, str] = {}  # branch_name -> worktree_path
        current_wt_path: str | None = None
        for line in wt_result.stdout.splitlines():
            if line.startswith("worktree "):
                current_wt_path = line.split("worktree ", 1)[1]
            elif line.startswith("branch refs/heads/") and current_wt_path:
                branch_ref = line.split("branch refs/heads/", 1)[1]
                if branch_ref.startswith("orch/"):
                    worktree_map[branch_ref] = current_wt_path

        # Step 1: Remove worktrees FIRST — prevents git branch -D failures on
        # branches still checked out in a linked worktree (TICKET-0136).
        for branch, wt_path in worktree_map.items():
            self.logger.log("CLEANUP", f"Removing worktree {wt_path} (branch={branch})")
            subprocess.run(
                ["git", "worktree", "remove", "--force", wt_path],
                cwd=str(REPO_ROOT), capture_output=True
            )

        # Step 2: Ensure we're on main, then pull — workers already merged via PR.
        subprocess.run(
            ["git", "checkout", "main"],
            cwd=str(REPO_ROOT), capture_output=True
        )
        pull_result = subprocess.run(
            ["git", "pull", "origin", "main"],
            cwd=str(REPO_ROOT), capture_output=True, text=True
        )
        if pull_result.returncode != 0:
            self.logger.log("ERROR", f"git pull origin main failed: {pull_result.stderr[:200]}")
            self.state["status"] = "HALTED"
            return
        self.logger.log("MERGE", "Pulled latest main (workers merged via GitHub PR)")

        # Step 3: Delete local orch/* branches.
        for branch in branches:
            del_result = subprocess.run(
                ["git", "branch", "-D", branch],
                cwd=str(REPO_ROOT), capture_output=True, text=True
            )
            if del_result.returncode == 0:
                self.logger.log("CLEANUP", f"Deleted local branch {branch}")
            else:
                # Branch may already be gone — not fatal
                self.logger.log("CLEANUP",
                    f"Branch {branch} not deleted (may already be gone): "
                    + del_result.stderr.strip())

    async def _handle_uid_commits(self):
        """GDScript UID commit procedure from CLAUDE.md."""
        self.logger.log("SYSTEM", "Checking for new .gd.uid files...")

        # Trigger Godot filesystem scan (best-effort — Godot may not be running)
        try:
            # We can't use Godot MCP from Python directly, so we just wait
            # and check for files that Godot may have generated
            await asyncio.sleep(5)
        except asyncio.CancelledError:
            return

        # Check for new uid files
        result = subprocess.run(
            ["git", "ls-files", "--others", "--exclude-standard", "--", "*.gd.uid"],
            cwd=str(REPO_ROOT), capture_output=True, text=True
        )
        uid_files = [f for f in result.stdout.splitlines() if f.strip()]

        if uid_files:
            self.logger.log("SYSTEM", f"Found {len(uid_files)} new .gd.uid files")
            subprocess.run(
                ["git", "add", "--"] + uid_files,
                cwd=str(REPO_ROOT), capture_output=True
            )
            subprocess.run(
                ["git", "commit", "-m", "chore: commit Godot-generated UIDs"],
                cwd=str(REPO_ROOT), capture_output=True
            )
            subprocess.run(
                ["git", "push", "origin", "main"],
                cwd=str(REPO_ROOT), capture_output=True
            )
            self.logger.log("SYSTEM", "UID files committed and pushed.")

    # ------------------------------------------------------------------
    # GATE_BLOCKED
    # ------------------------------------------------------------------

    async def _do_gate_blocked(self):
        """Handle phase gate — notify human and wait for approval."""
        pending_gate_path = self.paths.pending_gate_path
        gate_response_path = self.paths.gate_response_path

        gate = self.state.pop("_pending_gate", {})
        if not gate:
            # Check if pending_gate.json already exists (resume scenario)
            if pending_gate_path.exists():
                gate = load_json(pending_gate_path)
            else:
                self.state["status"] = "PLANNING"
                return

        # Write gate file
        gate["requested_at"] = now_iso()
        write_json(pending_gate_path, gate)

        # Print notification
        phase = gate.get("phase", "?")
        milestone = gate.get("milestone", self.state["milestone"])
        next_phase = gate.get("next_phase", "?")
        summary = gate.get("summary", "")

        banner = "\n" + "=" * 60
        banner += f"\n  GATE — ACTION REQUIRED"
        banner += f"\n  Phase \"{phase}\" ({milestone}) is complete."
        banner += f"\n  {summary}"
        banner += f"\n  Next phase: \"{next_phase}\""
        banner += f"\n  Run: python orchestrator/approve_gate.py"
        banner += "\n" + "=" * 60 + "\n"
        print(banner)

        # Fire Windows toast
        fire_toast(
            f"Gate: {phase} ({milestone})",
            f"Phase complete. Run approve_gate.py to continue."
        )

        self.logger.log("GATE",
            f"Awaiting Studio Head approval for {phase} ({milestone})")

        # Poll for response
        while not self.shutdown_requested:
            if gate_response_path.exists():
                try:
                    response = load_json(gate_response_path)
                except (json.JSONDecodeError, OSError):
                    await asyncio.sleep(5)
                    continue

                action = response.get("action", "")
                comment = response.get("comment", "")

                if action == "approve":
                    self.logger.log("APPROVED",
                        f"Studio Head approved phase gate"
                        + (f" — {comment}" if comment else ""))
                    self.state["phase"] = next_phase
                    self.state["status"] = "PLANNING"
                elif action == "reject":
                    self.logger.log("REJECTED",
                        f"Studio Head rejected phase gate"
                        + (f" — {comment}" if comment else ""))
                    self.state["status"] = "HALTED"
                else:
                    self.logger.log("ERROR",
                        f"Unknown gate response action: {action}")
                    self.state["status"] = "HALTED"

                # Clean up gate files
                _safe_delete(pending_gate_path)
                _safe_delete(gate_response_path)
                return

            await asyncio.sleep(5)

        # Shutdown requested while waiting for gate
        self.logger.log("SYSTEM", "Shutdown during gate wait. Gate still pending.")


def _safe_delete(path: Path):
    try:
        path.unlink()
    except OSError:
        pass


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Hammer Forge Studio — Agent Orchestrator"
    )
    parser.add_argument("milestone", nargs="?",
        help="Milestone ID (e.g., M7). Required for a fresh start; "
             "omit only with --status.")
    parser.add_argument("--instance", type=str, default=None,
        help="Instance name for scoped state/logs (defaults to <milestone>)")
    parser.add_argument("--status", action="store_true",
        help="Print current state and exit")

    args = parser.parse_args()

    # Resolve instance name: --instance flag, else milestone positional arg
    instance_name = args.instance or args.milestone

    if args.status:
        if not instance_name:
            parser.error("Provide <milestone> or --instance for --status")
            return
        paths = resolve_instance(instance_name, ORCH_DIR)
        state = load_state(paths.state_path)
        if state:
            print(json.dumps(state, indent=2))
        else:
            print("No state.json found.")
        return

    if not instance_name:
        parser.error("Provide <milestone> for a fresh start (e.g., M7)")
        return

    paths = resolve_instance(instance_name, ORCH_DIR)
    config = load_config(paths)
    conductor = Conductor(paths, config)

    if conductor.state is not None:
        # Resuming — milestone and phase come from saved state
        milestone = conductor.state["milestone"]
        phase = conductor.state["phase"]
    else:
        # Fresh start — milestone required; phase auto-detected from tickets
        if not args.milestone:
            parser.error("Provide <milestone> for a fresh start (e.g., M7)")
            return
        milestone = args.milestone
        phase = detect_starting_phase(milestone)
        print(f"Fresh start: milestone={milestone}, auto-detected phase={phase!r}")

    asyncio.run(conductor.run(milestone, phase))


if __name__ == "__main__":
    main()
