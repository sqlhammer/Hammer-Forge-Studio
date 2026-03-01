# Hammer Forge Studio — Fresh Windows VM Setup Guide

**Audience:** Studio Head (Derik Hammer)
**Purpose:** Reproduce the full development environment on a new Windows machine.
**Last Updated:** 2026-02-28

---

## Prerequisites

- Windows 10/11 (64-bit, x86_64)
- Internet access
- GitHub access (read/write to the Hammer-Forge-Studio repo)
- An Anthropic account with Claude Max subscription

---

## Overview

| # | What | Why |
|---|------|-----|
| 1 | Git | Version control |
| 2 | VS Code | Auxiliary editor for scripts and docs |
| 3 | Python 3.11 | Orchestrator, scripts, MCP server |
| 4 | uv | Python script runner (no venv needed) |
| 5 | Godot 4.5.1 stable | Game engine + MCP host |
| 6 | Claude Code | Agent runtime + your interactive terminal |
| 7 | Clone repo | Get the codebase |
| 8 | Discord | Access GDAI MCP plugin releases |
| 9 | Install GDAI MCP Plugin + open Godot project | Godot ↔ Claude Code bridge |
| 10 | Register Godot MCP | Connect Claude Code to the Godot editor |
| 11 | Configure Claude Code | Global settings and project permissions |
| 12 | Project-level permissions | Pre-approve tools for agent runs |
| 13 | Verification checklist | Confirm everything works |
| 14 | Start orchestration | Day-to-day workflow reference |

---

## Step 1 — Git

Download and install Git for Windows: https://git-scm.com/download/win

Accept all defaults. After install, open **Git Bash** and verify:

```bash
git --version
# git version 2.x.x.windows.x
```

Configure your identity:

```bash
git config --global user.name "Derik Hammer"
git config --global user.email "your-email@example.com"
```

Authenticate with GitHub. The simplest method is GitHub CLI:

```bash
# Download gh from https://cli.github.com/
gh auth login
# Choose: GitHub.com → HTTPS → Login with browser
```

---

## Step 2 — VS Code

Download and run the `system installer` from https://code.visualstudio.com/download — choose the **Windows User Installer (64-bit)**.

Accept all defaults. The installer adds `code` to your PATH automatically.

Verify from a new PowerShell or Git Bash window:

```bash
code --version
```

**Recommended extensions** — install these from the Extensions panel (`Ctrl+Shift+X`):

| Extension | Purpose |
|-----------|---------|
| Python (Microsoft) | Syntax, linting, and run support for orchestrator scripts |
| GDScript (Godot Tools) | Syntax highlighting for `.gd` files when browsing game code |

> VS Code is used for auxiliary work — editing orchestrator scripts, reviewing tickets, and browsing docs. Agent work happens inside Claude Code sessions, not VS Code.

---

## Step 3 — Python 3.11

Download the Windows installer from https://www.python.org/downloads/
Select **Python 3.11.x** (the version currently on this machine; 3.10+ is the minimum).

**Important during install:**
- ☑ Check **"Add Python to PATH"**
- Choose **"Install for all users"** or current user — either works

Verify from Git Bash:

```bash
python --version
# Python 3.11.x
```

---

## Step 4 — uv

`uv` is a fast Python script runner used by the GDAI MCP plugin to manage its own dependencies automatically. No manual virtualenv or pip install is needed.

Install via PowerShell:

```powershell
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

Close and reopen your terminal, then verify:

```bash
uv --version
# uv x.x.x
```

---

## Step 5 — Godot 4.5.1 Stable

Download the **Windows 64-bit** build from the official Godot releases page:
https://github.com/godotengine/godot/releases

Download `Godot_v4.5.1-stable_win64.exe` (the standard editor build).

**Recommended location:** Place the executable on your Desktop or in `C:\tools\Godot\`.

> Godot is a portable application — no installer. Just download and run.

Create a Start Menu shortcut (optional but convenient):
Right-click the exe → Send to → Desktop (create shortcut).

Verify by launching the editor. The Godot project manager should open.

---

## Step 6 — Claude Code

Install Claude Code from **PowerShell** (run as any user — no admin required):

```powershell
irm https://claude.ai/install.ps1 | iex
```

The installer places the `claude` binary in `%USERPROFILE%\.local\bin\` and adds it to your user PATH automatically. Close and reopen PowerShell after install, then verify:

```powershell
claude --version
# 2.x.xx (Claude Code)
```

> **Alternative — winget:** `winget install Anthropic.ClaudeCode`
> Winget does not auto-update; run `winget upgrade Anthropic.ClaudeCode` periodically.

> **Note for Git Bash users:** The binary is installed to a Windows path. After the PowerShell install it should be callable from Git Bash too (`claude --version`). If not, add to your `~/.bashrc`: `export PATH="$USERPROFILE/.local/bin:$PATH"`

**Log in to your Anthropic account:**

```bash
claude
# First launch will open browser for OAuth login
# Sign in with your Anthropic / Claude Max account
```

---

## Step 7 — Clone the Repository

```bash
# Create the repos directory if it doesn't exist
mkdir -p /c/repos

# Clone
git clone https://github.com/sqlhammer/Hammer-Forge-Studio.git /c/repos/Hammer-Forge-Studio

# Verify
cd /c:/repos/Hammer-Forge-Studio
git log --oneline -5
```

The repo must live at `C:\repos\Hammer-Forge-Studio`. The orchestrator and MCP paths are hardcoded to this location.

---

## Step 8 — Discord

The GDAI MCP plugin releases are distributed through the developer's Discord server. You need Discord to download the plugin files.

1. Install Discord from https://discord.com/download
2. Create or log in to your Discord account
3. Join the **3ddelano Cafe** server — you can find the invite link at https://gdaimcp.com/
4. Navigate to the **GDAI MCP Releases** channel: https://discord.com/channels/330264450148073474/1413398652273168405
5. Download the latest release zip for **Windows** from that channel

---

## Step 9 — Install the GDAI MCP Plugin and Open the Godot Project

The GDAI MCP plugin is a commercial product and is **not included in the repository**. It must be installed manually from the files downloaded in Step 7.

### 9a — Copy the plugin into the project

Extract the downloaded zip and place the `gdai-mcp-plugin-godot` folder at exactly this path:

```
C:\repos\Hammer-Forge-Studio\game\addons\gdai-mcp-plugin-godot\
```

After copying, the folder structure should look like this:

```
game\
└── addons\
    └── gdai-mcp-plugin-godot\
        ├── plugin.cfg
        ├── gdai_mcp_plugin.gd
        ├── gdai_mcp_server.py
        └── bin\
            └── windows\
                └── ...
```

### 9b — Open the project

1. Launch `Godot_v4.5.1-stable_win64.exe`
2. In the Godot Project Manager, click **Import**
3. Navigate to `C:\repos\Hammer-Forge-Studio\game\` and select `project.godot`
4. Click **Import & Edit**

### 9c — Enable plugins

1. In the Godot editor, go to **Project → Project Settings → Plugins**
2. Enable **both** plugins:
   - **GDAI MCP** — the Claude Code ↔ Godot bridge; starts an HTTP server on port `3571`
   - **Hammer Forge Tests** — the unit testing framework; required for QA agents to run the test suite and for the QA phase gate to pass
3. Close Project Settings

You should see no errors in the Godot Output panel.

### 9d — Godot generates UID files

On first open, Godot scans the filesystem and generates `.gd.uid` sidecar files. Wait ~10 seconds for this to complete (watch the bottom-left progress bar in the editor).

---

## Step 10 — Register the Godot MCP Server with Claude Code

Claude Code connects to Godot via an MCP server. Register it once at the project scope:

```bash
cd /c/repos/Hammer-Forge-Studio

claude mcp add godot-mcp -- uv run C:/repos/Hammer-Forge-Studio/game/addons/gdai-mcp-plugin-godot/gdai_mcp_server.py
```

This writes the MCP server definition into the project's Claude configuration. Verify the registration:

```bash
claude mcp list
# Should show: godot-mcp  ...  C:/repos/Hammer-Forge-Studio/game/addons/...
```

> **Important:** The Godot editor must be open with the project loaded whenever an agent (or you) uses `mcp__godot-mcp__*` tools. The MCP server is a bridge to the running editor — it won't work if Godot is closed.

---

## Step 11 — Configure Claude Code Global Settings

Create or edit `C:\Users\<you>\.claude\settings.json`:

```json
{
  "model": "sonnet",
  "autoUpdatesChannel": "latest",
  "skipDangerousModePermissionPrompt": true
}
```

These settings:
- Set the default model to Sonnet (overridden per-agent by the orchestrator)
- Enable auto-updates
- Skip the `--dangerously-skip-permissions` confirmation prompt that the orchestrator passes to worker agents

---

## Step 12 — Verify the Project-Level Permission Settings

The file `.claude/settings.local.json` is already in the repo (gitignored but present on disk after clone... actually it's inside `.claude/` which is gitignored).

Create it manually:

```bash
mkdir -p /c/repos/Hammer-Forge-Studio/.claude
```

Then create the file at `C:\repos\Hammer-Forge-Studio\.claude\settings.local.json` with this content:

```json
{
  "permissions": {
    "allow": [
      "mcp__godot-mcp__get_filesystem_tree",
      "mcp__godot-mcp__get_project_info",
      "mcp__godot-mcp__create_script",
      "mcp__godot-mcp__create_scene",
      "mcp__godot-mcp__add_node",
      "mcp__godot-mcp__attach_script",
      "mcp__godot-mcp__set_anchor_preset",
      "mcp__godot-mcp__update_property",
      "mcp__godot-mcp__get_godot_errors",
      "mcp__godot-mcp__clear_output_logs",
      "mcp__godot-mcp__view_script",
      "mcp__godot-mcp__play_scene",
      "mcp__godot-mcp__get_running_scene_screenshot",
      "mcp__godot-mcp__stop_running_scene",
      "mcp__godot-mcp__add_resource",
      "mcp__godot-mcp__edit_file",
      "mcp__godot-mcp__add_scene",
      "mcp__godot-mcp__get_scene_tree",
      "mcp__godot-mcp__get_editor_screenshot",
      "mcp__godot-mcp__simulate_input",
      "mcp__godot-mcp__get_input_map",
      "mcp__godot-mcp__get_scene_file_content",
      "mcp__godot-mcp__execute_editor_script",
      "mcp__godot-mcp__search_files",
      "mcp__godot-mcp__open_scene"
    ]
  }
}
```

This file pre-approves the Godot MCP tools and common Git operations so worker agents are not blocked by permission prompts during orchestrator runs.

---

## Step 13 — Verification Checklist

Work through each item to confirm the environment is fully operational.

### 13a — Tools

```bash
git --version          # git version 2.x.x
python --version       # Python 3.11.x
uv --version           # uv x.x.x
claude --version       # 2.x.xx (Claude Code)
```

### 13b — Claude Code authentication

```bash
# Should not prompt for login:
claude -p "Say hello" --model sonnet
# Expected: a short response from Claude
```

### 13c — Godot MCP connectivity

1. Ensure Godot editor is open with `C:\repos\Hammer-Forge-Studio\game\project.godot` loaded
2. Ensure the GDAI MCP plugin is enabled (Project Settings → Plugins)
3. From inside a `claude` session in the project directory, run a quick tool call:
   ```
   Use get_project_info to tell me the project name
   ```
   Expected: Claude calls `mcp__godot-mcp__get_project_info` and returns `"core"`.

### 13d — Orchestrator dry-run

```bash
cd /c/repos/Hammer-Forge-Studio
python orchestrator/status.py
# Expected: prints current state (IDLE or a milestone state)
```

---

## Step 14 — Starting Agent Orchestration

With the environment verified, here is the normal workflow for kicking off a milestone.

### Before every orchestrator run

1. Open Godot editor with the project loaded (port 3571 must be live)
2. Confirm Godot's GDAI MCP plugin is enabled
3. Open a terminal in `C:\repos\Hammer-Forge-Studio\`

### Start a new milestone

```bash
python orchestrator/start_milestone.py M9
python orchestrator/conductor.py M9
```

### Resume after a crash or reboot

```bash
python orchestrator/conductor.py M9
# or, if the conductor exited abnormally:
python orchestrator/conductor.py --resume
```

### Check status

```bash
python orchestrator/status.py
python orchestrator/status.py --log 20   # include last 20 activity log lines
```

### Approve a phase gate

When a phase completes, the conductor halts and prints a notification (and fires a Windows toast). To continue:

```bash
python orchestrator/approve_gate.py                      # approve
python orchestrator/approve_gate.py --comment "LGTM"     # approve with note
python orchestrator/approve_gate.py --reject             # reject (pages Studio Head)
```

### Stop gracefully

Press `Ctrl+C` in the conductor terminal. It finishes active workers, saves state, and exits cleanly.

---

## Reference — Tool Versions (as of 2026-02-28)

| Tool | Version |
|------|---------|
| Claude Code | 2.1.63 |
| Python | 3.11.9 |
| uv | 0.9.9 |
| Git | 2.53.0.windows.1 |
| Godot | 4.5.1 stable |
| GDAI MCP Plugin | 0.3.0 |

---

## Troubleshooting

### Godot MCP tools return "connection refused"

The Godot editor is not running or the GDAI MCP plugin is disabled. Open the editor, verify the plugin is enabled, and retry.

### `claude mcp list` shows no servers

Re-run the `claude mcp add` command from Step 8. Make sure you are in the project directory (`/c/repos/Hammer-Forge-Studio`) when running it.

### Worker agents fail with permission errors

The `.claude/settings.local.json` file may be missing or malformed. Recreate it using the content in Step 10.

### Orchestrator crashes immediately with `state.json` mismatch

You ran `conductor.py` without `start_milestone.py` first. Run:
```bash
python orchestrator/start_milestone.py M9 --force
python orchestrator/conductor.py M9
```

### Godot UID files not committed after a ticket

Follow the GDScript UID Commit procedure in `CLAUDE.md` (section "GDScript UID Commit"). Trigger a Godot filesystem scan, wait 5 seconds, then commit any new `.gd.uid` files.

### `uv` not found after install

Close and reopen Git Bash or PowerShell. uv installs to `~/.local/bin/` or `%USERPROFILE%\.local\bin\` which may require a new shell session to be on PATH.
