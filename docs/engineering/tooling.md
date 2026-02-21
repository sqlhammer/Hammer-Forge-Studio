# Engineering Tooling

**Owner:** tools-devops-engineer
**Status:** Draft
**Last Updated:** —

> Reference for all build tools, editor plugins, CI/CD pipeline, and Git workflow. If you need a tool and it's not here, create a TASK ticket for tools-devops-engineer.

---

## Godot Version

_[Document the exact Godot version in use and where to download it]_

---

## MCP Plugin (gdai-mcp-plugin-godot)

- **Version:** 0.3.0
- **Location:** `game/addons/gdai-mcp-plugin-godot/`
- **Server:** `game/addons/gdai-mcp-plugin-godot/gdai_mcp_server.py`
- **Port:** 3571 (Godot HTTP API)
- **Python requirement:** 3.10+
- **Dependencies:** `uv run` handles dependency install automatically

To start: ensure Godot is open with the plugin enabled, then Claude Code connects via the configured MCP server.

---

## Git Workflow

_[Branch strategy, naming conventions, merge process — to be filled in by tools-devops-engineer]_

---

## CI/CD Pipeline

_[What runs on commit/PR, where results are reported — to be filled in by tools-devops-engineer]_

---

## Export Pipeline

_[How to export the game for each platform, where builds land — to be filled in by tools-devops-engineer]_

---

## Editor Tools (hfs-tools addon)

_[List of custom @tool scripts available in game/addons/hfs-tools/ — updated as tools are added]_

---

## Utility Scripts

_[List of scripts/ utilities, what they do, how to run them]_
