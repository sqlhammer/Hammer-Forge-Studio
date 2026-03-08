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
import shutil
import signal
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path

from instance_paths import InstancePaths, load_config, resolve_instance

# ---------------------------------------------------------------------------
# Paths — only repo-level constants that are needed before arg parsing
# ---------------------------------------------------------------------------

REPO_ROOT = Path(os.environ.get("HFS_REPO_ROOT", Path(__file__).resolve().parent.parent))
ORCH_DIR = Path(os.environ.get("HFS_ORCH_DIR", REPO_ROOT / "orchestrator"))
AGENTS_DIR = REPO_ROOT / "agents"
WORKTREES_DIR = REPO_ROOT / ".claude" / "worktrees"
USAGE_LOG = ORCH_DIR / "usage.jsonl"

# ---------------------------------------------------------------------------
# Pricing constants — USD per million tokens
# ---------------------------------------------------------------------------

MODEL_PRICING = {
    "opus":   {"input": 15.0,  "output": 75.0},
    "sonnet": {"input":  3.0,  "output": 15.0},
    "haiku":  {"input":  0.80, "output":  4.0},
}

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
    return datetime.now().strftime("%Y-%m-%dT%H:%M:%S")


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


def calc_cost_usd(model: str, input_tokens: int, output_tokens: int) -> float:
    """Calculate cost in USD from token counts using MODEL_PRICING."""
    model_lower = (model or "").lower()
    rates = MODEL_PRICING.get("sonnet")  # default if no match
    for key in MODEL_PRICING:
        if key in model_lower:
            rates = MODEL_PRICING[key]
            break
    return (input_tokens * rates["input"] + output_tokens * rates["output"]) / 1_000_000


def append_usage_record(record: dict):
    """Append a single JSON line to the JSONL usage ledger. Never raises."""
    try:
        with open(USAGE_LOG, "a", encoding="utf-8") as f:
            f.write(json.dumps(record) + "\n")
            f.flush()
    except Exception:
        pass


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
                age = (datetime.now() - lock_time).total_seconds()
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


class SuspensionLogger:
    """Writes machine-readable JSON-lines to suspension.log for all suspension events.

    Each entry is one JSON object per line (JSONL format). Used alongside
    ActivityLogger to provide structured data for gate evaluation and analysis.
    """

    def __init__(self, path: Path):
        self.path = path

    def log(
        self,
        event: str,
        agent: str = "",
        ticket: str = "",
        milestone: str = "",
        phase: str = "",
        wave: int = 0,
        checkpoint_path: str = "",
        retry_count: int = 0,
        retry_reason: str = "",
        notes: str = "",
    ):
        """Write a structured suspension event entry to suspension.log.

        Args:
            event: One of limit_hit, suspended, resume_dispatched, resume_success,
                   resume_failure, auto_remediated, zombie_detected.
            agent: Agent slug (e.g. "gameplay-programmer").
            ticket: Ticket ID (e.g. "TICKET-0187").
            milestone: Milestone ID (e.g. "M9").
            phase: Phase name (e.g. "Orchestrator Resilience").
            wave: Wave number at time of event.
            checkpoint_path: Path to checkpoint file (relative string).
            retry_count: Number of retries attempted so far.
            retry_reason: "usage_limit" or "implementation_failure".
            notes: Free-text details about the event.
        """
        entry = {
            "timestamp": now_iso(),
            "event": event,
            "agent": agent,
            "ticket": ticket,
            "milestone": milestone,
            "phase": phase,
            "wave": wave,
            "checkpoint_path": checkpoint_path,
            "retry_count": retry_count,
            "retry_reason": retry_reason,
            "notes": notes,
        }
        try:
            with open(self.path, "a", encoding="utf-8") as f:
                f.write(json.dumps(entry) + "\n")
                f.flush()
        except Exception:
            pass  # Never crash the conductor over a log write failure


# ---------------------------------------------------------------------------
# Config helpers
# ---------------------------------------------------------------------------

def get_model(config: dict, agent_slug: str) -> str:
    overrides = config["models"].get("overrides", {})
    return overrides.get(agent_slug, config["models"]["default_worker"])


def get_max_turns(config: dict, agent_slug: str) -> int:
    overrides = config["max_turns"].get("overrides", {})
    return overrides.get(agent_slug, config["max_turns"]["default"])


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


def _mark_ticket_done_on_disk(
    ticket_id: str,
    milestone: str,
    pr_number: int | None,
) -> bool:
    """Update a ticket file to DONE status on disk.

    Sets ``status: DONE``, updates ``updated_at:`` to today, and appends an
    auto-completion entry to the ticket's Activity Log section.

    Returns True on success, False if the file could not be found or written.
    """
    ticket_path = REPO_ROOT / "tickets" / milestone / f"{ticket_id}.md"
    if not ticket_path.exists():
        ticket_path = REPO_ROOT / "tickets" / milestone.lower() / f"{ticket_id}.md"
    if not ticket_path.exists():
        return False

    try:
        text = ticket_path.read_text(encoding="utf-8")
    except OSError:
        return False

    today = datetime.now().strftime("%Y-%m-%d")
    text = re.sub(r"^status:\s*\S+", f"status: DONE", text, flags=re.MULTILINE)
    text = re.sub(r"^updated_at:\s*\S+", f"updated_at: {today}", text, flags=re.MULTILINE)

    pr_ref = f"PR #{pr_number}" if pr_number is not None else "a merged PR"
    log_entry = (
        f"\n- {today} [conductor] Auto-completed — {pr_ref} was merged but "
        "agent session terminated before updating ticket status"
    )
    if "## Activity Log" in text:
        text = text.rstrip() + log_entry + "\n"

    try:
        ticket_path.write_text(text, encoding="utf-8")
    except OSError:
        return False

    return True


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
    today = datetime.now().strftime("%Y-%m-%d")
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


def get_phase_tickets(milestone: str, phase: str) -> list[str]:
    """Return all ticket IDs in the milestone that belong to the given phase.

    Reads ticket files under tickets/{milestone}/ and returns IDs where the
    `phase:` frontmatter field matches the given phase name exactly.
    Sorted by ticket filename (i.e., ticket ID order).
    """
    tickets_dir = REPO_ROOT / "tickets" / milestone.lower()
    if not tickets_dir.exists():
        return []

    phase_re = re.compile(r'^phase:\s*["\']?([^"\'\\n]+?)["\']?\s*$', re.MULTILINE)
    result = []
    for ticket_file in sorted(tickets_dir.glob("TICKET-*.md")):
        try:
            text = ticket_file.read_text(encoding="utf-8")
            m = phase_re.search(text)
            if m and m.group(1).strip() == phase:
                result.append(ticket_file.stem)
        except Exception:
            pass
    return result


def get_next_phase(milestone: str, current_phase: str) -> str | None:
    """Return the phase that follows current_phase in ticket ID order.

    Scans all ticket files in the milestone sorted by ID and collects distinct
    phase values in order of first appearance.  Returns the phase immediately
    after current_phase, or None if current_phase is the last (or not found).
    """
    tickets_dir = REPO_ROOT / "tickets" / milestone.lower()
    if not tickets_dir.exists():
        return None

    phase_re = re.compile(r'^phase:\s*["\']?([^"\'\\n]+?)["\']?\s*$', re.MULTILINE)
    seen: list[str] = []
    for ticket_file in sorted(tickets_dir.glob("TICKET-*.md")):
        try:
            text = ticket_file.read_text(encoding="utf-8")
            m = phase_re.search(text)
            if m:
                p = m.group(1).strip()
                if p not in seen:
                    seen.append(p)
        except Exception:
            pass

    if current_phase in seen:
        idx = seen.index(current_phase)
        if idx + 1 < len(seen):
            return seen[idx + 1]
    return None


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
        "_uid_commit_pending": False,
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


def _build_resume_briefing(ticket_id: str, checkpoint: dict) -> str:
    """Format a checkpoint dict into a human-readable resume briefing for the dispatch prompt.

    Called by _run_worker (TICKET-0185) when a checkpoint file exists for the ticket
    being dispatched.  Returns a Markdown section that is injected into the
    {checkpoint_context} placeholder in worker_dispatch.md.
    """
    progress = checkpoint.get("progress", {})
    commit = progress.get("commit_hash") or "none"
    branch = progress.get("branch") or "unknown"
    push_status = "yes" if commit and commit != "none" else "unknown"
    pr_url = progress.get("pr_url") or "none"
    pr_merged = progress.get("pr_merged", False)
    if pr_merged:
        pr_status = "merged"
    elif pr_url and pr_url != "none":
        pr_status = f"open ({pr_url})"
    else:
        pr_status = "no"
    ticket_status = progress.get("ticket_status_on_disk", "UNKNOWN")
    steps = progress.get("steps_completed", [])
    steps_str = ", ".join(steps) if steps else "none recorded"

    # Determine remaining steps from observable state
    remaining: list[str] = []
    if "committed" not in steps:
        remaining.append("Complete the implementation, commit your work, and push the branch")
    elif "pushed" not in steps and pr_url == "none" and not pr_merged:
        remaining.append("Push your branch to remote")
    if not pr_merged and pr_url == "none" and "committed" in steps:
        remaining.append(f"Create a PR from {branch} targeting main")
    if not pr_merged and pr_url != "none":
        remaining.append("Self-merge the PR")
    if ticket_status != "DONE":
        remaining.append(
            "Update the ticket status to DONE with an Activity Log entry "
            "(include the commit hash and PR URL)"
        )
    remaining.append("Output your JSON result")

    remaining_str = "\n".join(f"{i + 1}. {step}" for i, step in enumerate(remaining))

    return (
        f"## Resume Context\n"
        f"You are resuming {ticket_id} from an interrupted session.\n"
        f"- Previous commit: {commit} on branch {branch}\n"
        f"- Branch pushed to remote: {push_status}\n"
        f"- PR created: {pr_status}\n"
        f"- Ticket status on disk: {ticket_status}\n"
        f"- Steps completed: {steps_str}\n"
        f"\n"
        f"YOUR REMAINING STEPS:\n"
        f"{remaining_str}\n"
        f"\n"
        f"Do NOT redo work that was already completed."
    )


# ---------------------------------------------------------------------------
# Claude CLI interface
# ---------------------------------------------------------------------------

async def run_claude(
    prompt: str,
    model: str,
    max_turns: int,
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

    cmd.extend(["--max-turns", str(max_turns)])

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

    # Pass the prompt via stdin to avoid Windows command-line length limits
    # (WinError 206: "The filename or extension is too long").
    # claude -p reads from stdin when no prompt argument is given.
    prompt_bytes = prompt.encode("utf-8")

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
            stdin=asyncio.subprocess.PIPE,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )

        if on_proc_start:
            on_proc_start(proc)

        try:
            stdout_bytes, stderr_bytes = await asyncio.wait_for(
                proc.communicate(input=prompt_bytes), timeout=timeout_seconds
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
        # Suspension log lives alongside activity.log in the instance dir
        self.suspension_logger = SuspensionLogger(
            paths.activity_log.parent / "suspension.log"
        )
        self.shutdown_requested = False
        self._active_procs: set[asyncio.subprocess.Process] = set()
        self._run_claude = run_claude_fn or run_claude

        # Gate detection state (TICKET-0189)
        self._gate_emitted_this_wave: bool = False
        self._gate_check_logged_this_wave: bool = False
        # Phase-ticket cache: stores (milestone, phase, wave_number, tickets)
        self._phase_ticket_cache: tuple[str, str, int, list[str]] | None = None

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

        # Startup zombie detection: clear stale state from previous sessions
        self._scan_checkpoints_on_startup()

        # Resume interrupted UID commit sequence before any git pull attempt.
        # A pending UID commit can leave the repo in dirty state (staged but not
        # committed), which blocks git pull in _do_planning. Run it here first.
        if self.state.get("_uid_commit_pending", False):
            self.logger.log("SYSTEM",
                "UID commit: _uid_commit_pending=True on startup — resuming UID commit sequence")
            await self._handle_uid_commits()

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

            elif status == "LIMIT_WAIT":
                await self._do_limit_wait()

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

        # Reset per-wave gate flags (TICKET-0189)
        self._gate_emitted_this_wave = False
        self._gate_check_logged_this_wave = False
        # If pending_gate.json already exists (e.g. Producer emitted it), mark gate as emitted
        if self.paths.pending_gate_path.exists():
            self._gate_emitted_this_wave = True

        self.logger.log("PLAN", f"Requesting wave {wave_num} plan from Producer...")

        # Build prompt
        retry_tickets = [
            tid for tid, entry in self.state.get("retries", {}).items()
            if (entry["count"] if isinstance(entry, dict) else entry) > 0
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
            "pending_checkpoints": self._get_pending_checkpoints_summary(),
        }
        prompt = render_template(self.paths.prompts_dir / "plan_wave.md", template_vars)

        # Call Producer
        model = self.config["models"]["producer"]
        max_turns = get_max_turns(self.config, "producer")
        blocked = get_blocked_tools(self.config, "producer")

        exit_code, stdout, stderr, usage_meta = await self._run_claude(
            prompt=prompt,
            model=model,
            max_turns=max_turns,
            blocked_tools=blocked,
            output_json=True,
            cwd=REPO_ROOT,
            timeout_minutes=10,
            log_path=self.paths.logs_dir / f"producer-wave{wave_num}-{now_iso().replace(':', '')}.log",
            on_proc_start=self._track_proc,
        )

        if exit_code != 0:
            self.logger.log("ERROR", f"Producer exited with code {exit_code}: {stderr[:200]}")
            if self._detect_usage_limit(exit_code, stdout, stderr):
                self.logger.log("BUDGET",
                    "Producer hit usage limit — entering cooldown")
                self.state["wave_number"] -= 1
                self._enter_limit_wait()
                return
            # Retry up to 3 times for non-usage-limit failures
            if self.state.get("_producer_retries", 0) < 3:
                self.state["_producer_retries"] = self.state.get("_producer_retries", 0) + 1
                self.logger.log("RETRY", f"Retrying Producer (attempt {self.state['_producer_retries']}/3)")
                self.state["wave_number"] -= 1  # Don't increment wave on retry
                return
            self.logger.log("ERROR", "Producer failed 3 times. Halting.")
            self.state["status"] = "HALTED"
            return

        self.state.pop("_producer_retries", None)

        # Write usage record for this planning call
        if usage_meta:
            input_tok = usage_meta.get("input_tokens", 0)
            output_tok = usage_meta.get("output_tokens", 0)
            model_used = usage_meta.get("model", model)
            cost = calc_cost_usd(model_used, input_tok, output_tok)
            append_usage_record({
                "timestamp": now_iso(),
                "agent": "producer",
                "ticket_id": f"PLAN_WAVE_{wave_num}",
                "milestone": self.state.get("milestone", ""),
                "phase": self.state.get("phase", ""),
                "model": model_used,
                "input_tokens": input_tok,
                "output_tokens": output_tok,
                "cost_usd": cost,
                "duration_seconds": usage_meta.get("duration_seconds", 0.0),
                "call_type": "planning",
            })
            self.state["total_cost_usd"] = (
                self.state.get("total_cost_usd", 0.0) + cost
            )
            save_state(self.state, self.paths.state_path)

        # Detect usage limit on exit_code==0 with empty stdout (silent session exit)
        if not stdout.strip():
            self.logger.log("BUDGET",
                "Producer exited cleanly but produced no output — suspected usage limit")
            self.state["wave_number"] -= 1
            self._enter_limit_wait()
            return

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

        elif action == "no_work":
            # Gate deferral (R7): before going idle, check for unresolved checkpoints
            # in the current phase.  If any exist, those tickets were suspended and
            # not yet re-dispatched — defer the gate and stay in PLANNING so the
            # conductor can re-dispatch them on the next wave.
            current_phase = self.state.get("phase", "")
            should_defer, deferred_tickets = self._check_gate_deferral(current_phase)
            if should_defer:
                n = len(deferred_tickets)
                self.logger.log("WARNING",
                    f"Gate deferred — {n} unresolved checkpoint(s) exist for phase "
                    f'"{current_phase}": {", ".join(deferred_tickets)}')
                # Stay in PLANNING — do not set status to IDLE
            else:
                self.logger.log("PLAN", "No workable tickets. Idling.")
                self.state["status"] = "IDLE"

        elif action == "milestone_complete":
            self.logger.log("SYSTEM",
                f"Milestone {self.state['milestone']} complete!")
            self.state["status"] = "IDLE"
            self._rotate_logs_on_milestone_complete()

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

            # Studio Head guard: never execute studio-head tickets automatically
            if agent_slug == "studio-head":
                self.logger.log("SKIP",
                    f"{ticket_id} owner=studio-head — requires human action, not dispatching")
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

            max_turns = assignment.get("max_turns", get_max_turns(self.config, agent_slug))
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
                "max_turns": max_turns,
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
        # Track usage-limit failures for mass-threshold detection (per-worker tuple)
        usage_limit_failures: list[str] = []  # ticket IDs that hit usage limit

        for worker, (exit_code, stdout, stderr, usage_meta) in results:
            agent = worker["agent"]
            ticket = worker["ticket"]

            # Write usage record for this worker call
            if usage_meta:
                input_tok = usage_meta.get("input_tokens", 0)
                output_tok = usage_meta.get("output_tokens", 0)
                model_used = usage_meta.get("model", "")
                cost = calc_cost_usd(model_used, input_tok, output_tok)
                append_usage_record({
                    "timestamp": now_iso(),
                    "agent": agent,
                    "ticket_id": ticket,
                    "milestone": self.state.get("milestone", ""),
                    "phase": self.state.get("phase", ""),
                    "model": model_used,
                    "input_tokens": input_tok,
                    "output_tokens": output_tok,
                    "cost_usd": cost,
                    "duration_seconds": usage_meta.get("duration_seconds", 0.0),
                    "call_type": "worker",
                })
                self.state["total_cost_usd"] = (
                    self.state.get("total_cost_usd", 0.0) + cost
                )

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
                    # exit=0 + empty stdout is a strong usage-limit signal
                    is_limit = self._detect_usage_limit(exit_code, stdout, stderr)
                    self.logger.log("CRASH",
                        f"{agent} <- {ticket}: exit=0 but empty stdout — "
                        + ("suspected usage limit" if is_limit else "treating as failed"))
                    all_succeeded = False
                    # Silent-success check (R1, R10): ticket may be DONE even though the
                    # agent exited before outputting JSON.  If so, skip the retry.
                    if read_ticket_status(ticket, self.state["milestone"]) == "DONE":
                        self.logger.log("DONE",
                            f"{agent} <- {ticket} (silent success — ticket is DONE on disk)")
                        wave_tickets.append(ticket)
                        session_done = self.state.setdefault("completed_this_session", [])
                        if ticket not in session_done:
                            session_done.append(ticket)
                    elif is_limit:
                        self.suspension_logger.log(
                            event="limit_hit",
                            agent=agent,
                            ticket=ticket,
                            milestone=self.state.get("milestone", ""),
                            phase=self.state.get("phase", ""),
                            wave=self.state.get("wave_number", 0),
                            notes=f"exit_code={exit_code} empty stdout",
                        )
                        checkpoint = self._write_checkpoint(worker, exit_code, stdout, stderr)
                        if worker.get("_was_resumed"):
                            self.logger.log("RESUME", f"{ticket} resume failed")
                        branch = checkpoint.get("progress", {}).get("branch") or ""
                        if not self._auto_remediate_merged_pr(ticket, branch, agent, wave_tickets):
                            usage_limit_failures.append(ticket)
                            self._queue_retry(ticket, reason="usage_limit")
                    else:
                        checkpoint = self._write_checkpoint(worker, exit_code, stdout, stderr)
                        if worker.get("_was_resumed"):
                            self.logger.log("RESUME", f"{ticket} resume failed")
                        branch = checkpoint.get("progress", {}).get("branch") or ""
                        if not self._auto_remediate_merged_pr(ticket, branch, agent, wave_tickets):
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
                            if worker.get("_was_resumed"):
                                self.logger.log("RESUME", f"{ticket} resumed successfully")
                            retry_entry = self.state.get("retries", {}).get(ticket, 0)
                            retry_count = retry_entry["count"] if isinstance(retry_entry, dict) else retry_entry
                            if retry_count > 0:
                                self.suspension_logger.log(
                                    event="resume_success",
                                    agent=agent,
                                    ticket=ticket,
                                    milestone=self.state.get("milestone", ""),
                                    phase=self.state.get("phase", ""),
                                    wave=self.state.get("wave_number", 0),
                                    retry_count=retry_count,
                                    notes="ticket completed successfully after resume",
                                )
                            self._delete_checkpoint(ticket)
                            # Track session-completed tickets for dependency validation
                            session_done = self.state.setdefault("completed_this_session", [])
                            if ticket not in session_done:
                                session_done.append(ticket)
                    elif outcome == "blocked":
                        self.logger.log("BLOCKED", f"{agent} <- {ticket}: {result_data.get('summary', '')}")
                        all_succeeded = False
                        retry_entry = self.state.get("retries", {}).get(ticket, 0)
                        retry_count = retry_entry["count"] if isinstance(retry_entry, dict) else retry_entry
                        if retry_count > 0:
                            self.suspension_logger.log(
                                event="resume_failure",
                                agent=agent,
                                ticket=ticket,
                                milestone=self.state.get("milestone", ""),
                                phase=self.state.get("phase", ""),
                                wave=self.state.get("wave_number", 0),
                                retry_count=retry_count,
                                notes=f"outcome=blocked after resume",
                            )
                    else:
                        self.logger.log("PARTIAL", f"{agent} <- {ticket}: outcome={outcome}")
                        all_succeeded = False
                        if worker.get("_was_resumed"):
                            self.logger.log("RESUME", f"{ticket} resume failed")
                        retry_entry = self.state.get("retries", {}).get(ticket, 0)
                        retry_count = retry_entry["count"] if isinstance(retry_entry, dict) else retry_entry
                        if retry_count > 0:
                            self.suspension_logger.log(
                                event="resume_failure",
                                agent=agent,
                                ticket=ticket,
                                milestone=self.state.get("milestone", ""),
                                phase=self.state.get("phase", ""),
                                wave=self.state.get("wave_number", 0),
                                retry_count=retry_count,
                                notes=f"outcome={outcome} after resume",
                            )
                        self._queue_retry(ticket)
                except ValueError:
                    self.logger.log("DONE", f"{agent} <- {ticket} (no structured output)")
                    wave_tickets.append(ticket)
            elif exit_code == -1:
                self.logger.log("TIMEOUT", f"{agent} <- {ticket}: {stderr}")
                all_succeeded = False
                # Silent-success check (R10): agent may have completed before timing out.
                is_limit = self._detect_usage_limit(exit_code, stdout, stderr)
                if read_ticket_status(ticket, self.state["milestone"]) == "DONE":
                    self.logger.log("DONE",
                        f"{agent} <- {ticket} (silent success — ticket is DONE on disk)")
                    wave_tickets.append(ticket)
                    session_done = self.state.setdefault("completed_this_session", [])
                    if ticket not in session_done:
                        session_done.append(ticket)
                elif is_limit:
                    self.suspension_logger.log(
                        event="limit_hit",
                        agent=agent,
                        ticket=ticket,
                        milestone=self.state.get("milestone", ""),
                        phase=self.state.get("phase", ""),
                        wave=self.state.get("wave_number", 0),
                        notes=f"exit_code={exit_code} timeout",
                    )
                    checkpoint = self._write_checkpoint(worker, exit_code, stdout, stderr)
                    if worker.get("_was_resumed"):
                        self.logger.log("RESUME", f"{ticket} resume failed")
                    branch = checkpoint.get("progress", {}).get("branch") or ""
                    if not self._auto_remediate_merged_pr(ticket, branch, agent, wave_tickets):
                        usage_limit_failures.append(ticket)
                        self._queue_retry(ticket, reason="usage_limit")
                else:
                    checkpoint = self._write_checkpoint(worker, exit_code, stdout, stderr)
                    if worker.get("_was_resumed"):
                        self.logger.log("RESUME", f"{ticket} resume failed")
                    branch = checkpoint.get("progress", {}).get("branch") or ""
                    if not self._auto_remediate_merged_pr(ticket, branch, agent, wave_tickets):
                        self._queue_retry(ticket)
            else:
                empty = not stdout.strip() and not stderr.strip()
                label = "CRASH" if empty else "FAILED"
                self.logger.log(label,
                    f"{agent} <- {ticket} (exit={exit_code}"
                    + (", empty output — possible crash/signal" if empty else "") + ")")
                all_succeeded = False
                # Silent-success check (R1, R3, R10): agent may have completed before crashing.
                is_limit = self._detect_usage_limit(exit_code, stdout, stderr)
                if read_ticket_status(ticket, self.state["milestone"]) == "DONE":
                    self.logger.log("DONE",
                        f"{agent} <- {ticket} (silent success — ticket is DONE on disk)")
                    wave_tickets.append(ticket)
                    session_done = self.state.setdefault("completed_this_session", [])
                    if ticket not in session_done:
                        session_done.append(ticket)
                elif is_limit:
                    self.suspension_logger.log(
                        event="limit_hit",
                        agent=agent,
                        ticket=ticket,
                        milestone=self.state.get("milestone", ""),
                        phase=self.state.get("phase", ""),
                        wave=self.state.get("wave_number", 0),
                        notes=f"exit_code={exit_code} crash/nonzero",
                    )
                    checkpoint = self._write_checkpoint(worker, exit_code, stdout, stderr)
                    if worker.get("_was_resumed"):
                        self.logger.log("RESUME", f"{ticket} resume failed")
                    branch = checkpoint.get("progress", {}).get("branch") or ""
                    if not self._auto_remediate_merged_pr(ticket, branch, agent, wave_tickets):
                        usage_limit_failures.append(ticket)
                        self._queue_retry(ticket, reason="usage_limit")
                else:
                    checkpoint = self._write_checkpoint(worker, exit_code, stdout, stderr)
                    if worker.get("_was_resumed"):
                        self.logger.log("RESUME", f"{ticket} resume failed")
                    branch = checkpoint.get("progress", {}).get("branch") or ""
                    if not self._auto_remediate_merged_pr(ticket, branch, agent, wave_tickets):
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

        # Mass usage-limit detection: if >= threshold% of workers failed with usage limit,
        # enter LIMIT_WAIT instead of queuing individual retries normally.
        if usage_limit_failures and results:
            threshold_pct = self.config.get("limit_wait", {}).get("mass_threshold_pct", 50)
            failure_ratio = len(usage_limit_failures) / len(results)
            if failure_ratio >= threshold_pct / 100:
                self.logger.log("BUDGET",
                    f"{len(usage_limit_failures)}/{len(results)} workers hit usage limit "
                    f"(>={threshold_pct}% threshold) — entering cooldown")
                self._enter_limit_wait()
                return

        self.state["status"] = "EVALUATING"

    async def _run_worker(self, worker: dict) -> tuple[int, str, str, dict]:
        """Run a single worker agent."""
        agent_slug = worker["agent"]
        ticket_id = worker["ticket"]
        max_turns = worker["max_turns"]
        supplement = worker.get("prompt_supplement", "")

        # Build worker prompt
        retry_entry = self.state.get("retries", {}).get(ticket_id, 0)
        retry_count = retry_entry["count"] if isinstance(retry_entry, dict) else retry_entry
        checkpoint_context = worker.get("checkpoint_context", "")

        # TICKET-0185: Load checkpoint file if present and inject structured resume briefing.
        checkpoint_file = ORCH_DIR / "checkpoints" / f"{ticket_id}.checkpoint.json"
        if not checkpoint_context and checkpoint_file.exists():
            try:
                cp_data = json.loads(checkpoint_file.read_text(encoding="utf-8"))
                checkpoint_context = _build_resume_briefing(ticket_id, cp_data)
                worker["_was_resumed"] = True
                self.logger.log("RESUME", f"Dispatching {ticket_id} with checkpoint context")
            except (json.JSONDecodeError, OSError):
                pass

        if not checkpoint_context and retry_count > 0:
            # Fallback: no checkpoint file exists, but this is a retry dispatch.
            # Inform the agent so it can assess current state before proceeding.
            ticket_status_on_disk = read_ticket_status(ticket_id, self.state["milestone"])
            checkpoint_context = (
                f"This ticket is {ticket_status_on_disk} from a previous session that was "
                "interrupted. Assess the current state of the branch and ticket before "
                "proceeding."
            )

        template_vars = {
            "agent_name": agent_slug.replace("-", " ").title(),
            "agent_slug": agent_slug,
            "ticket_id": ticket_id,
            "milestone": self.state["milestone"],
            "ticket_title": ticket_id,  # Will be refined by the agent after reading
            "prompt_supplement": supplement if supplement else "No additional notes.",
            "checkpoint_context": checkpoint_context,
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
            f"{agent_slug} -> {ticket_id} (model={model}, max_turns={max_turns})")

        # Log resume_dispatched if this is a retry with checkpoint context
        if checkpoint_context and retry_count > 0:
            checkpoint_file = (
                ORCH_DIR / "checkpoints" / f"{ticket_id}.checkpoint.json"
            )
            self.suspension_logger.log(
                event="resume_dispatched",
                agent=agent_slug,
                ticket=ticket_id,
                milestone=self.state.get("milestone", ""),
                phase=self.state.get("phase", ""),
                wave=self.state.get("wave_number", 0),
                checkpoint_path=str(checkpoint_file) if checkpoint_file.exists() else "",
                retry_count=retry_count,
                notes="dispatching with checkpoint context",
            )

        start = time.time()
        exit_code, stdout, stderr, usage_meta = await self._run_claude(
            prompt=prompt,
            model=model,
            max_turns=max_turns,
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

    # ------------------------------------------------------------------
    # LIMIT_WAIT
    # ------------------------------------------------------------------

    def _enter_limit_wait(self):
        """Transition to LIMIT_WAIT, or HALT if max cooldown cycles exhausted."""
        cfg = self.config.get("limit_wait", {})
        max_cycles = cfg.get("max_cooldown_cycles", 3)
        current_cycles = self.state.get("_cooldown_cycle_count", 0)
        if current_cycles >= max_cycles:
            self.logger.log("BUDGET",
                f"Persistent usage limit after {max_cycles} cooldowns — halting")
            self.state["status"] = "HALTED"
        else:
            self.state["_cooldown_cycle_count"] = current_cycles + 1
            self.state["status"] = "LIMIT_WAIT"

    async def _do_limit_wait(self):
        """Sleep in intervals during a usage-limit cooldown period."""
        cfg = self.config.get("limit_wait", {})
        cooldown_minutes = cfg.get("cooldown_minutes", 15)
        total_seconds = cooldown_minutes * 60
        log_interval_seconds = 5 * 60  # log every 5 minutes

        cycle = self.state.get("_cooldown_cycle_count", 1)
        self.logger.log("LIMIT_WAIT",
            f"Cooldown cycle {cycle} — sleeping {cooldown_minutes}m before resuming")

        elapsed = 0
        while elapsed < total_seconds:
            if self.shutdown_requested:
                return
            remaining = total_seconds - elapsed
            sleep_time = min(log_interval_seconds, remaining)
            await asyncio.sleep(sleep_time)
            elapsed += sleep_time
            if elapsed < total_seconds:
                remaining_minutes = (total_seconds - elapsed) / 60
                self.logger.log("LIMIT_WAIT",
                    f"Cooling down — {remaining_minutes:.0f}m remaining")

        self.logger.log("LIMIT_WAIT", "Cooldown expired — resuming")
        self.state["status"] = "PLANNING"

    async def _do_gate_blocked(self):
        """Wait for gate approval after a phase-completion gate is emitted.

        Polls for gate_response.json (written by Producer or Studio Head).
        When found: advances conductor to the next phase and returns to PLANNING.
        If gate_response.json is absent, sleeps 30 seconds and polls again.
        """
        if self.paths.gate_response_path.exists():
            try:
                resp = load_json(self.paths.gate_response_path)
                next_phase = resp.get("next_phase", "").strip()

                # Fall back to reading next_phase from the pending gate itself
                if not next_phase and self.paths.pending_gate_path.exists():
                    try:
                        gate_data = load_json(self.paths.pending_gate_path)
                        next_phase = gate_data.get("next_phase", "").strip()
                    except Exception:
                        pass

                if next_phase:
                    self.state["phase"] = next_phase
                    # Invalidate phase-ticket cache for the new phase
                    self._phase_ticket_cache = None
                    self.logger.log(
                        "GATE",
                        f"Gate approved — advancing to phase: {next_phase}",
                    )
                else:
                    self.logger.log(
                        "GATE",
                        "Gate response received but next_phase is missing — "
                        "staying in current phase",
                    )

                # Clean up gate files
                _safe_delete(self.paths.pending_gate_path)
                _safe_delete(self.paths.gate_response_path)
                self._gate_emitted_this_wave = False
                self.state["status"] = "PLANNING"
            except Exception as exc:
                self.logger.log("WARNING",
                    f"Failed to read gate_response.json: {exc}")
                await asyncio.sleep(30)
        else:
            self.logger.log("GATE",
                "Waiting for gate response (pending_gate.json written — "
                "awaiting gate_response.json)...")
            await asyncio.sleep(30)

    # Usage-limit keywords (case-insensitive scan of stderr/stdout)
    _USAGE_LIMIT_KEYWORDS = (
        "rate limit", "rate_limit", "usage limit", "usage_limit",
        "capacity", "exceeded", "too many requests", "429", "quota",
    )

    @staticmethod
    def _detect_usage_limit(exit_code: int, stdout: str, stderr: str) -> bool:
        """Return True if the failure appears to be a Claude Max usage limit.

        Heuristics:
        - stderr or stdout contains a known usage-limit keyword (case-insensitive)
        - exit_code == 0 with completely empty stdout (Claude session starts and
          immediately ends — common Claude Max capacity behaviour)
        """
        combined = (stdout + "\n" + stderr).lower()
        for keyword in Conductor._USAGE_LIMIT_KEYWORDS:
            if keyword in combined:
                return True
        if exit_code == 0 and not stdout.strip():
            return True
        return False

    def _queue_retry(self, ticket_id: str, reason: str = "implementation_failure"):
        """Queue a ticket for retry.

        Args:
            ticket_id: The ticket to retry.
            reason: "usage_limit" or "implementation_failure" (default).
                    Only implementation_failure retries count toward the
                    max_per_ticket HALT threshold.
        """
        max_retries = self.config["retries"]["max_per_ticket"]
        retries = self.state.setdefault("retries", {})
        entry = retries.get(ticket_id)
        # Migrate legacy int format (produced before this feature was added)
        if isinstance(entry, int):
            entry = {"count": entry, "reasons": ["implementation_failure"] * entry}
        elif entry is None:
            entry = {"count": 0, "reasons": []}

        if reason == "implementation_failure":
            if entry["count"] >= max_retries:
                self.logger.log("ERROR",
                    f"{ticket_id} exceeded max retries ({max_retries}). Halting.")
                self.state["status"] = "HALTED"
                return
            entry["count"] += 1

        entry["reasons"].append(reason)
        retries[ticket_id] = entry

        total_attempts = len(entry["reasons"])
        self.logger.log("RETRY",
            f"{ticket_id} queued for retry (reason={reason}, attempt {total_attempts})")

    # ------------------------------------------------------------------
    # CHECKPOINT SYSTEM
    # ------------------------------------------------------------------

    def _write_checkpoint(
        self,
        worker: dict,
        exit_code: int,
        stdout: str,
        stderr: str,
    ) -> dict:
        """Write a suspension checkpoint for an abnormally-exiting worker.

        Probes worktree git state and remote PR state, then writes an atomic
        checkpoint JSON to orchestrator/checkpoints/{TICKET-NNNN}.checkpoint.json.
        Returns the checkpoint dict for downstream use (context injection, auto-remediation).
        """
        ticket_id = worker["ticket"]
        agent = worker["agent"]
        worktree_path_str = worker.get("worktree_path")
        branch = worker.get("branch") or ""

        # Determine suspension reason
        is_limit = self._detect_usage_limit(exit_code, stdout, stderr)
        if is_limit:
            reason = "usage_limit"
        elif exit_code == -1:
            reason = "timeout"
        elif not stdout.strip() and not stderr.strip() and exit_code != 0:
            reason = "crash"
        else:
            reason = "unknown"

        # Probe worktree git state (best-effort)
        commit_hash = None
        uncommitted_changes = False
        actual_branch = branch
        if worktree_path_str:
            wt = Path(worktree_path_str)
            if wt.exists():
                log_result = subprocess.run(
                    ["git", "-C", str(wt), "log", "--oneline", "-1"],
                    capture_output=True, text=True,
                )
                if log_result.returncode == 0 and log_result.stdout.strip():
                    commit_hash = log_result.stdout.strip().split()[0]

                status_result = subprocess.run(
                    ["git", "-C", str(wt), "status", "--porcelain"],
                    capture_output=True, text=True,
                )
                if status_result.returncode == 0:
                    uncommitted_changes = bool(status_result.stdout.strip())

                branch_result = subprocess.run(
                    ["git", "-C", str(wt), "branch", "--show-current"],
                    capture_output=True, text=True,
                )
                if branch_result.returncode == 0 and branch_result.stdout.strip():
                    actual_branch = branch_result.stdout.strip()

        # Probe remote PR state via gh CLI (best-effort)
        pr_url = None
        pr_merged = False
        pr_state = None
        if actual_branch:
            try:
                pr_result = subprocess.run(
                    ["gh", "pr", "list", "--head", actual_branch,
                     "--json", "number,url,state,merged"],
                    capture_output=True, text=True, timeout=15,
                )
                if pr_result.returncode == 0 and pr_result.stdout.strip():
                    pr_data = json.loads(pr_result.stdout)
                    if pr_data:
                        pr_entry = pr_data[0]
                        pr_url = pr_entry.get("url")
                        pr_merged = pr_entry.get("merged", False)
                        pr_state = pr_entry.get("state")
            except (json.JSONDecodeError, subprocess.TimeoutExpired, OSError):
                pass

        # Read ticket status from disk
        ticket_status = read_ticket_status(ticket_id, self.state.get("milestone", ""))

        # Infer completed steps from observable state
        steps_completed = ["read_ticket", "verified_deps"]
        if ticket_status == "IN_PROGRESS":
            steps_completed.append("marked_in_progress")
        if commit_hash:
            steps_completed.append("committed")
        if pr_url and pr_merged:
            steps_completed.append("merged_pr")

        checkpoint = {
            "ticket": ticket_id,
            "agent": agent,
            "milestone": self.state.get("milestone", ""),
            "phase": self.state.get("phase", ""),
            "wave": self.state.get("wave_number", 0),
            "suspended_at": now_iso(),
            "reason": reason,
            "progress": {
                "steps_completed": steps_completed,
                "commit_hash": commit_hash,
                "branch": actual_branch or None,
                "uncommitted_changes": uncommitted_changes,
                "pr_url": pr_url,
                "pr_merged": pr_merged,
                "pr_state": pr_state,
                "ticket_status_on_disk": ticket_status,
                "files_changed": [],
                "new_gd_scripts": False,
            },
            "notes": f"exit_code={exit_code}",
        }

        # Write atomically: tmp file then rename
        checkpoints_dir = ORCH_DIR / "checkpoints"
        checkpoints_dir.mkdir(parents=True, exist_ok=True)
        checkpoint_path = checkpoints_dir / f"{ticket_id}.checkpoint.json"
        tmp_path = checkpoint_path.with_suffix(".tmp")
        try:
            write_json(tmp_path, checkpoint)
            tmp_path.replace(checkpoint_path)
            self.logger.log("CHECKPOINT", f"{ticket_id} suspended — wrote checkpoint")
            retry_entry = self.state.get("retries", {}).get(ticket_id, 0)
            retry_count = retry_entry["count"] if isinstance(retry_entry, dict) else retry_entry
            self.suspension_logger.log(
                event="suspended",
                agent=agent,
                ticket=ticket_id,
                milestone=self.state.get("milestone", ""),
                phase=self.state.get("phase", ""),
                wave=self.state.get("wave_number", 0),
                checkpoint_path=str(checkpoint_path),
                retry_count=retry_count,
                retry_reason=reason,
                notes=f"exit_code={exit_code}",
            )
        except OSError as e:
            self.logger.log("WARNING", f"Failed to write checkpoint for {ticket_id}: {e}")

        return checkpoint

    def _delete_checkpoint(self, ticket_id: str):
        """Delete the checkpoint file for a successfully completed ticket."""
        checkpoint_path = ORCH_DIR / "checkpoints" / f"{ticket_id}.checkpoint.json"
        if checkpoint_path.exists():
            try:
                checkpoint_path.unlink()
                self.logger.log("CHECKPOINT", f"{ticket_id} checkpoint cleared")
            except OSError:
                pass

    def _check_gate_deferral(self, phase: str) -> tuple[bool, list[str]]:
        """Check if any unresolved checkpoints exist for tickets in the given phase.

        Scans ORCH_DIR/checkpoints/ for checkpoint files whose phase matches `phase`.
        Returns (True, [ticket_ids]) if the gate should be deferred because suspended
        tickets exist for the phase, or (False, []) if the gate may fire normally.
        """
        checkpoints_dir = ORCH_DIR / "checkpoints"
        if not checkpoints_dir.exists():
            return False, []

        deferred: list[str] = []
        for cp_file in checkpoints_dir.glob("*.checkpoint.json"):
            try:
                cp_data = json.loads(cp_file.read_text(encoding="utf-8"))
            except (json.JSONDecodeError, OSError):
                continue
            if cp_data.get("phase", "") == phase:
                ticket_id = cp_data.get("ticket", "")
                if ticket_id:
                    deferred.append(ticket_id)

        return (len(deferred) > 0, deferred)

    def _rotate_logs_on_milestone_complete(self):
        """Archive activity.log and suspension.log at milestone close (TICKET-0191).

        Called after status is set to IDLE via milestone_complete, before save_state.
        - Scans checkpoints/ for anomalies and logs a warning if any remain.
        - Logs the archive action to activity.log (so it is the last entry in the archive).
        - Copies active logs to logs/activity-{milestone}.log (appending if archive exists).
        - Truncates the active logs so the next milestone starts clean.
        - Uses copy-then-truncate (not move) to prevent data loss if interrupted.
        - Creates logs/ directory if it does not exist (defensive).
        """
        milestone = self.state.get("milestone", "unknown").lower()
        logs_dir = self.paths.logs_dir
        logs_dir.mkdir(parents=True, exist_ok=True)

        # --- Checkpoint anomaly scan (informational — does NOT block archive) ---
        checkpoints_dir = ORCH_DIR / "checkpoints"
        if checkpoints_dir.exists():
            remaining = list(checkpoints_dir.glob("*.checkpoint.json"))
            if remaining:
                n = len(remaining)
                ticket_ids = []
                for cp_file in remaining:
                    try:
                        cp_data = json.loads(cp_file.read_text(encoding="utf-8"))
                        tid = cp_data.get("ticket", "")
                        ticket_ids.append(tid if tid else cp_file.name)
                    except (json.JSONDecodeError, OSError):
                        ticket_ids.append(cp_file.name)
                self.logger.log("WARNING",
                    f"{n} unresolved checkpoint(s) found at milestone close — "
                    f"investigate before proceeding: {', '.join(ticket_ids)}")

        # --- Archive activity.log ---
        activity_log = self.paths.activity_log
        archive_activity = logs_dir / f"activity-{milestone}.log"

        # Log the archive action BEFORE truncating (this entry ends up in the archive)
        self.logger.log("SYSTEM",
            f"Archived activity.log -> logs/activity-{milestone}.log")

        if activity_log.exists():
            content = activity_log.read_bytes()
            with open(archive_activity, "ab") as af:
                af.write(content)
            activity_log.write_bytes(b"")

        # --- Archive suspension.log (if it exists; skip if absent) ---
        suspension_log = self.paths.activity_log.parent / "suspension.log"
        if suspension_log.exists():
            archive_suspension = logs_dir / f"suspension-{milestone}.log"
            content = suspension_log.read_bytes()
            with open(archive_suspension, "ab") as af:
                af.write(content)
            suspension_log.write_bytes(b"")

    def _check_merged_pr(self, ticket_id: str, branch: str) -> dict | None:
        """Check whether a PR for *branch* has been merged to main.

        Uses ``gh pr list --state all`` so that PRs whose source branch has
        already been deleted from the remote are still queryable.

        Returns the first merged PR data dict (keys: number, url, state,
        merged) if one exists, or ``None`` if no merged PR is found or if the
        query fails.
        """
        if not branch:
            return None
        try:
            result = subprocess.run(
                [
                    "gh", "pr", "list",
                    "--head", branch,
                    "--json", "number,url,state,merged",
                    "--state", "all",
                ],
                capture_output=True, text=True, timeout=15,
            )
            if result.returncode == 0 and result.stdout.strip():
                prs = json.loads(result.stdout)
                for pr in prs:
                    if pr.get("merged", False):
                        return pr
        except (json.JSONDecodeError, subprocess.TimeoutExpired, OSError):
            pass
        return None

    def _auto_remediate_merged_pr(
        self,
        ticket_id: str,
        branch: str,
        agent: str,
        wave_tickets: list[str],
    ) -> bool:
        """Auto-remediate Risk R3: PR merged but ticket still IN_PROGRESS on disk.

        Calls ``_check_merged_pr``.  If a merged PR is found AND the ticket is
        IN_PROGRESS on disk:
        - Updates the ticket file to DONE on disk.
        - Adds the ticket to ``completed_this_session``.
        - Deletes any checkpoint file for the ticket.
        - Appends the ticket to *wave_tickets* (counts as a wave completion).
        - Logs a CLEANUP entry to activity.log and an auto_remediated entry to
          suspension.log (TICKET-0187 will formalise the suspension logger; for
          now a simple JSON-lines append is used).

        Returns True when auto-remediation was performed so the caller can skip
        queuing a retry; False when no merged PR was found (caller should
        proceed normally).
        """
        pr_data = self._check_merged_pr(ticket_id, branch)
        if pr_data is None:
            return False

        milestone = self.state.get("milestone", "")
        ticket_status = read_ticket_status(ticket_id, milestone)
        if ticket_status != "IN_PROGRESS":
            return False

        pr_number = pr_data.get("number")
        pr_url = pr_data.get("url", "")

        if not _mark_ticket_done_on_disk(ticket_id, milestone, pr_number):
            self.logger.log(
                "WARNING",
                f"{ticket_id}: auto-remediation failed — could not update ticket file",
            )
            return False

        # Track as completed in this session
        session_done = self.state.setdefault("completed_this_session", [])
        if ticket_id not in session_done:
            session_done.append(ticket_id)

        # Include in wave completion set
        if ticket_id not in wave_tickets:
            wave_tickets.append(ticket_id)

        # Remove checkpoint (work is done)
        self._delete_checkpoint(ticket_id)

        # Log to activity.log
        self.logger.log(
            "CLEANUP",
            f"{ticket_id} auto-completed — PR #{pr_number} merged, ticket updated to DONE",
        )

        # Log auto-remediation to suspension.log via SuspensionLogger (TICKET-0187)
        self.suspension_logger.log(
            event="auto_remediated",
            agent=agent,
            ticket=ticket_id,
            milestone=milestone,
            phase=self.state.get("phase", ""),
            wave=self.state.get("wave_number", 0),
            checkpoint_path=str(ORCH_DIR / "checkpoints" / f"{ticket_id}.checkpoint.json"),
            notes=(
                f"PR #{pr_number} ({pr_url}) was merged but agent session "
                "terminated before updating ticket status"
            ),
        )

        return True

    def _scan_checkpoints_on_startup(self):
        """Scan checkpoints/ for zombie tickets from previous sessions.

        Called once at the start of run() before the main loop.
        - DONE on disk  → auto-remediate: add to completed_this_session, delete checkpoint.
        - IN_PROGRESS with merged PR → R3 auto-remediate via _auto_remediate_merged_pr.
        - IN_PROGRESS   → log zombie warning (will be re-dispatched with checkpoint context).
        Clears any stale active_ticket_ids entries that correspond to checkpoints.
        """
        checkpoints_dir = ORCH_DIR / "checkpoints"
        if not checkpoints_dir.exists():
            return

        checkpoint_files = list(checkpoints_dir.glob("*.checkpoint.json"))
        if not checkpoint_files:
            return

        milestone = self.state.get("milestone", "")
        stale_ids: set[str] = set()

        for cp_file in checkpoint_files:
            try:
                cp_data = json.loads(cp_file.read_text(encoding="utf-8"))
            except (json.JSONDecodeError, OSError):
                continue

            ticket_id = cp_data.get("ticket", "")
            if not ticket_id:
                continue

            stale_ids.add(ticket_id)
            ticket_status = read_ticket_status(ticket_id, milestone)

            if ticket_status == "DONE":
                self.logger.log("CLEANUP",
                    f"{ticket_id} auto-remediated on startup — "
                    "ticket is DONE on disk, deleting checkpoint")
                self.suspension_logger.log(
                    event="auto_remediated",
                    ticket=ticket_id,
                    agent=cp_data.get("agent", ""),
                    milestone=cp_data.get("milestone", milestone),
                    phase=cp_data.get("phase", ""),
                    wave=cp_data.get("wave", 0),
                    checkpoint_path=str(cp_file),
                    notes="ticket DONE on disk at startup — checkpoint auto-deleted",
                )
                session_done = self.state.setdefault("completed_this_session", [])
                if ticket_id not in session_done:
                    session_done.append(ticket_id)
                try:
                    cp_file.unlink()
                except OSError:
                    pass
            elif ticket_status == "IN_PROGRESS":
                # R3 auto-remediation: check whether the PR was merged even
                # though the agent exited before updating the ticket.
                branch = cp_data.get("progress", {}).get("branch") or ""
                agent = cp_data.get("agent", "unknown")
                dummy_wave_tickets: list[str] = []
                if self._auto_remediate_merged_pr(
                    ticket_id, branch, agent, dummy_wave_tickets
                ):
                    # auto-remediation already added to completed_this_session
                    pass
                else:
                    self.logger.log("CLEANUP",
                        f"{ticket_id} was zombie — checkpoint exists from previous session "
                        f"(status={ticket_status})")
            else:
                self.logger.log("CLEANUP",
                    f"{ticket_id} was zombie — checkpoint exists from previous session "
                    f"(status={ticket_status})")
                self.suspension_logger.log(
                    event="zombie_detected",
                    ticket=ticket_id,
                    agent=cp_data.get("agent", ""),
                    milestone=cp_data.get("milestone", milestone),
                    phase=cp_data.get("phase", ""),
                    wave=cp_data.get("wave", 0),
                    checkpoint_path=str(cp_file),
                    notes=f"ticket status={ticket_status} at startup",
                )

        # Clear stale active_ticket_ids (no live process after restart)
        if stale_ids:
            active = self.state.get("active_ticket_ids", [])
            cleared = [tid for tid in active if tid in stale_ids]
            if cleared:
                self.state["active_ticket_ids"] = [
                    tid for tid in active if tid not in stale_ids
                ]
                self.logger.log("CLEANUP",
                    f"Cleared stale active_ticket_ids: {', '.join(cleared)}")

    def _get_pending_checkpoints_summary(self) -> str:
        """Scan checkpoints/ and return a human-readable summary for the Producer prompt.

        Called by _do_planning (TICKET-0185) to populate {pending_checkpoints} in
        plan_wave.md.  The Producer uses this information to prioritize resumed tickets
        and avoid re-dispatching tickets with unresolved checkpoint states.
        """
        checkpoints_dir = ORCH_DIR / "checkpoints"
        if not checkpoints_dir.exists():
            return "none"

        checkpoint_files = sorted(checkpoints_dir.glob("*.checkpoint.json"))
        if not checkpoint_files:
            return "none"

        entries: list[str] = []
        for cp_file in checkpoint_files:
            try:
                cp = json.loads(cp_file.read_text(encoding="utf-8"))
            except (json.JSONDecodeError, OSError):
                continue
            ticket = cp.get("ticket", "UNKNOWN")
            agent = cp.get("agent", "unknown")
            progress = cp.get("progress", {})
            steps = progress.get("steps_completed", [])
            status = progress.get("ticket_status_on_disk", "UNKNOWN")
            reason = cp.get("reason", "unknown")
            steps_str = ", ".join(steps) if steps else "none"
            entries.append(
                f"- {ticket} (agent: {agent}, status: {status}, "
                f"reason: {reason}, steps: {steps_str})"
            )

        return "\n".join(entries) if entries else "none"

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
            self.state["_uid_commit_pending"] = True
            save_state(self.state, self.paths.state_path)
            await self._handle_uid_commits()

        # Check budget ceiling
        if self.state["total_cost_usd"] >= self.config["budgets"]["session_ceiling_usd"]:
            self.logger.log("BUDGET",
                f"Session ceiling reached ({format_cost(self.state['total_cost_usd'])}). Halting.")
            self.state["status"] = "HALTED"
            return

        # Conductor-level gate detection fallback (TICKET-0189 / R7)
        # If all phase tickets are DONE on disk and no gate was already emitted
        # this wave, the conductor emits the gate without waiting for Producer.
        if not self._gate_emitted_this_wave:
            self._check_fallback_gate()
            if self.state["status"] == "GATE_BLOCKED":
                return

        # Continue to next planning cycle
        self.state["status"] = "PLANNING"

    def _get_phase_tickets_cached(self) -> list[str]:
        """Return phase tickets, using the per-wave cache."""
        milestone = self.state["milestone"]
        phase = self.state["phase"]
        wave = self.state["wave_number"]

        if (self._phase_ticket_cache is not None
                and self._phase_ticket_cache[0] == milestone
                and self._phase_ticket_cache[1] == phase
                and self._phase_ticket_cache[2] == wave):
            return self._phase_ticket_cache[3]

        tickets = get_phase_tickets(milestone, phase)
        self._phase_ticket_cache = (milestone, phase, wave, tickets)
        return tickets

    def _check_fallback_gate(self):
        """Check if all phase tickets are DONE and emit a conductor fallback gate.

        Emits pending_gate.json and transitions to GATE_BLOCKED if:
        - All tickets in the current phase read DONE on disk.
        - No unresolved checkpoints exist for phase tickets.
        - No gate was already emitted this wave.

        Logs once per wave if the phase is not yet complete (DEBUG level).
        """
        milestone = self.state["milestone"]
        phase = self.state["phase"]
        phase_tickets = self._get_phase_tickets_cached()

        if not phase_tickets:
            return

        total = len(phase_tickets)
        done_count = 0
        for tid in phase_tickets:
            status = read_ticket_status(tid, milestone)
            if status == "DONE":
                done_count += 1

        if done_count < total:
            if not self._gate_check_logged_this_wave:
                self._gate_check_logged_this_wave = True
                self.logger.log(
                    "GATE",
                    f"Phase {phase} has {done_count}/{total} tickets DONE — not ready",
                )
            return

        # All tickets DONE — check for unresolved checkpoints before emitting
        checkpoints_dir = self.paths.orch_dir / "checkpoints"
        if checkpoints_dir.exists():
            for tid in phase_tickets:
                cp_path = checkpoints_dir / f"{tid}.checkpoint.json"
                if cp_path.exists():
                    self.logger.log(
                        "GATE",
                        f"Gate deferred — unresolved checkpoint exists for {tid} "
                        "(all tickets DONE but checkpoint not cleared)",
                    )
                    return

        # All clear — emit the fallback gate
        next_phase = get_next_phase(milestone, phase)
        gate_data = {
            "milestone": milestone,
            "phase": phase,
            "next_phase": next_phase or "",
            "summary": "Conductor fallback — Producer unavailable",
            "requested_at": now_iso(),
        }
        write_json(self.paths.pending_gate_path, gate_data)
        self._gate_emitted_this_wave = True

        self.logger.log(
            "GATE",
            f"Conductor detected phase completion — emitting gate (Producer fallback) "
            f"[phase={phase}, next_phase={next_phase!r}]",
        )
        self.state["status"] = "GATE_BLOCKED"

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
        """GDScript UID commit procedure from CLAUDE.md.

        Idempotent — safe to call multiple times. Each step checks its own
        precondition before executing, so interrupted runs resume cleanly.
        Clears the _uid_commit_pending flag in state.json after all steps complete.
        """
        self.logger.log("SYSTEM", "UID commit: starting idempotent UID commit sequence...")

        # Trigger Godot filesystem scan (best-effort — Godot may not be running)
        try:
            await asyncio.sleep(5)
        except asyncio.CancelledError:
            return

        # --- Step 1: git add ---
        # Check which .uid files are already staged.
        already_staged = subprocess.run(
            ["git", "diff", "--cached", "--name-only", "--", "*.gd.uid"],
            cwd=str(REPO_ROOT), capture_output=True, text=True
        )
        staged_uid_files = {f.strip() for f in already_staged.stdout.splitlines() if f.strip()}
        self.logger.log("SYSTEM",
            f"UID commit: {len(staged_uid_files)} .gd.uid file(s) already staged")

        # Find untracked .uid files that still need staging.
        untracked = subprocess.run(
            ["git", "ls-files", "--others", "--exclude-standard", "--", "*.gd.uid"],
            cwd=str(REPO_ROOT), capture_output=True, text=True
        )
        untracked_uid_files = [f.strip() for f in untracked.stdout.splitlines() if f.strip()]
        self.logger.log("SYSTEM",
            f"UID commit: {len(untracked_uid_files)} untracked .gd.uid file(s) to stage")

        if untracked_uid_files:
            subprocess.run(
                ["git", "add", "--"] + untracked_uid_files,
                cwd=str(REPO_ROOT), capture_output=True
            )
            self.logger.log("SYSTEM",
                f"UID commit: staged {len(untracked_uid_files)} file(s)")
        else:
            self.logger.log("SYSTEM", "UID commit: git add skipped — no untracked .gd.uid files")

        # --- Step 2: git commit ---
        # Only commit if there are staged changes.
        has_staged = subprocess.run(
            ["git", "diff", "--cached", "--quiet"],
            cwd=str(REPO_ROOT), capture_output=True
        )
        if has_staged.returncode != 0:
            # returncode != 0 means there are staged changes
            self.logger.log("SYSTEM", "UID commit: staged changes detected — committing")
            subprocess.run(
                ["git", "commit", "-m", "chore: commit Godot-generated UIDs"],
                cwd=str(REPO_ROOT), capture_output=True
            )
            self.logger.log("SYSTEM", "UID commit: committed")
        else:
            self.logger.log("SYSTEM", "UID commit: git commit skipped — no staged changes")

        # --- Step 3: git push ---
        # Only push if local HEAD is ahead of origin/main.
        ahead_count = subprocess.run(
            ["git", "rev-list", "--count", "origin/main..HEAD"],
            cwd=str(REPO_ROOT), capture_output=True, text=True
        )
        commits_ahead = int(ahead_count.stdout.strip() or "0")
        self.logger.log("SYSTEM",
            f"UID commit: local is {commits_ahead} commit(s) ahead of origin/main")

        if commits_ahead > 0:
            subprocess.run(
                ["git", "push", "origin", "main"],
                cwd=str(REPO_ROOT), capture_output=True
            )
            self.logger.log("SYSTEM", "UID commit: pushed to origin/main")
        else:
            self.logger.log("SYSTEM", "UID commit: git push skipped — already up to date with origin/main")

        # --- Done: clear the pending flag ---
        self.state["_uid_commit_pending"] = False
        save_state(self.state, self.paths.state_path)
        self.logger.log("SYSTEM", "UID commit: _uid_commit_pending cleared")

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
        help="Milestone ID (e.g., M9 for game milestones, T1 for tooling milestones). "
             "Required for a fresh start; omit only with --status.")
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
        parser.error("Provide <milestone> for a fresh start (e.g., M9 or T1)")
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
            parser.error("Provide <milestone> for a fresh start (e.g., M9 or T1)")
            return
        milestone = args.milestone
        phase = detect_starting_phase(milestone)
        print(f"Fresh start: milestone={milestone}, auto-detected phase={phase!r}")

    asyncio.run(conductor.run(milestone, phase))


if __name__ == "__main__":
    main()
