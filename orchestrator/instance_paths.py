"""Shared utility module for multi-milestone orchestrator path resolution and config loading.

Centralizes all path resolution and config loading so every other orchestrator
module uses a single, consistent set of paths per instance.
"""

from __future__ import annotations

import json
import os
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class InstancePaths:
    """All resolved paths for one orchestrator instance."""

    # Top-level directories
    orch_dir: Path
    instance_dir: Path

    # Global config (shared across instances, lives under orch_dir)
    config_path: Path
    config_local_path: Path

    # Per-instance state files
    state_path: Path
    activity_log: Path
    pending_gate_path: Path
    gate_response_path: Path
    godot_mcp_lock_path: Path

    # Per-instance output directories
    results_dir: Path
    logs_dir: Path

    # Shared directories (under orch_dir)
    prompts_dir: Path
    schemas_dir: Path


def resolve_instance(
    instance_name: str, orch_dir: Path | None = None
) -> InstancePaths:
    """Resolve all paths for a named orchestrator instance.

    Args:
        instance_name: The name of the instance (e.g. a milestone identifier).
        orch_dir: Explicit orchestrator root. Falls back to $HFS_ORCH_DIR,
                  then to ``<repo_root>/orchestrator``.

    Returns:
        A fully populated ``InstancePaths`` with directories created as needed.
    """
    if orch_dir is None:
        env_dir = os.environ.get("HFS_ORCH_DIR")
        if env_dir:
            orch_dir = Path(env_dir)
        else:
            # Walk up from this file to find the repo root (parent of orchestrator/)
            orch_dir = Path(__file__).resolve().parent

    orch_dir = orch_dir.resolve()
    instance_dir = orch_dir / "instances" / instance_name

    # Ensure per-instance directories exist
    (instance_dir / "results").mkdir(parents=True, exist_ok=True)
    (instance_dir / "logs").mkdir(parents=True, exist_ok=True)

    return InstancePaths(
        orch_dir=orch_dir,
        instance_dir=instance_dir,
        # Global config
        config_path=orch_dir / "config.json",
        config_local_path=orch_dir / "config.local.json",
        # Per-instance state
        state_path=instance_dir / "state.json",
        activity_log=instance_dir / "activity.log",
        pending_gate_path=instance_dir / "pending_gate.json",
        gate_response_path=instance_dir / "gate_response.json",
        godot_mcp_lock_path=instance_dir / "godot_mcp.lock",
        # Per-instance output
        results_dir=instance_dir / "results",
        logs_dir=instance_dir / "logs",
        # Shared
        prompts_dir=orch_dir / "prompts",
        schemas_dir=orch_dir / "schemas",
    )


def load_config(paths: InstancePaths) -> dict:
    """Load and merge orchestrator configuration.

    Reads the required global ``config.json``, then deep-merges
    ``config.local.json`` on top if it exists.

    Args:
        paths: Resolved instance paths (only config_path and
               config_local_path are used).

    Returns:
        The merged configuration dictionary.

    Raises:
        FileNotFoundError: If the base ``config.json`` does not exist.
    """
    if not paths.config_path.exists():
        raise FileNotFoundError(
            f"Required config file not found: {paths.config_path}"
        )

    with open(paths.config_path, "r", encoding="utf-8") as f:
        config = json.load(f)

    if paths.config_local_path.exists():
        with open(paths.config_local_path, "r", encoding="utf-8") as f:
            local_overrides = json.load(f)
        config = _deep_merge(config, local_overrides)

    return config


def _deep_merge(base: dict, override: dict) -> dict:
    """Recursively merge *override* into *base*, returning a new dict.

    - Sub-dicts are merged recursively (not replaced wholesale).
    - All other values: *override* wins at leaf level.

    Neither input dict is mutated.
    """
    merged = dict(base)
    for key, override_value in override.items():
        base_value = merged.get(key)
        if isinstance(base_value, dict) and isinstance(override_value, dict):
            merged[key] = _deep_merge(base_value, override_value)
        else:
            merged[key] = override_value
    return merged
