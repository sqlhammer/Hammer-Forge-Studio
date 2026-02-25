# SOP — Adding a New Ship Machine

**Owner:** producer
**Status:** Active
**Last Updated:** 2026-02-24 (TICKET-0080 — DEC-0001 compliance update)

> Standard Operating Procedure for introducing any new ship machine to Hammer Forge Studio. Follow this process every milestone that adds a new installable machine. Use the M5 Fabricator as the canonical reference example, with M4 Recycler notes where the processes diverged.

---

## Overview

A "ship machine" is an installable module that the player purchases through the tech tree, places in the ship interior, and operates via an interaction panel. Every ship machine requires coordinated work across five agents: systems-programmer, ui-ux-designer, technical-artist, gameplay-programmer, and qa-engineer.

**Reference machines:**
- **Recycler** (M4) — first machine; established the baseline pattern but was built under the old pause model — see DEC-0001 note in Step 7
- **Fabricator** (M5) — canonical reference for all future machines; first machine built to the correct non-pause model (DEC-0001, `docs/studio/decision-log.md`)

> **Panel Interaction Model (DEC-0001):** Machine interaction panels do **not** pause the game. When a panel is open: player movement and action inputs are suppressed via `InputManager`; all game systems and machines continue running; mouse mode switches to `MOUSE_MODE_VISIBLE`. Machines run at default `PROCESS_MODE_INHERIT`. Do **not** use `get_tree().paused` or `PROCESS_MODE_ALWAYS` for machine panels. See `docs/studio/decision-log.md` (DEC-0001) for the authoritative decision.

---

## Step-by-Step Process

### Step 1 — Physical Machine Design Brief
**Owner:** producer (at milestone kickoff) or ui-ux-designer (if visual design lead)
**Handoff to:** technical-artist, ui-ux-designer

Define the machine's physical form factor before any art or UI work begins.

Required fields:
- **Functional identity:** What does this machine do? What is its visual metaphor?
- **Form factor:** Approximate dimensions (W × D × H in meters), weight class (Light / Medium / Heavy)
- **Visual distinction:** How does it differ visually from existing machines? (Silhouette, dominant feature)
- **Placement zone:** Which area of the ship interior does it occupy? (Coordinate with interior layout wireframe)
- **Interaction point:** Where does the player stand/face to trigger the panel?

> **Recycler (M4):** 1.8m × 1.2m × 1.4m; industrial processor; input hopper left, output tray right, built-in screen front. Designed to read as heavy extraction equipment.
>
> **Fabricator (M5):** 2.0m × 1.0m × 1.2m; wide/low workbench with press arm. Distinct silhouette from Recycler — lower profile, broader footprint. Reads as crafting/assembly, not heavy industry.

---

### Step 2 — 3D Mesh Production
**Owner:** technical-artist
**Depends on:** Step 1 (design brief)
**Handoff to:** gameplay-programmer (TICKET: Interaction Panel Implementation)

Produce the machine mesh following the M2 pipeline SOP (`docs/engineering/3d-pipeline-sop.md`).

Checklist:
- [ ] Blender build script created at `blender_experiments/build_<machine_name>.py`
- [ ] Asset brief created at `docs/art/asset-briefs/<machine_name>.md`
- [ ] Mesh produced within poly budget (M2 art tech spec: 1,500–4,000 tris for greybox machines)
- [ ] Mesh exported as `.glb` to `game/assets/meshes/machines/mesh_<machine_name>_module.glb`
- [ ] Mesh imported into Godot with no import errors or warnings
- [ ] Mesh placed in greybox ship interior scene (`game/scenes/gameplay/`)
- [ ] `InteractionArea` (Area3D) attached to mesh — collision Layer 4 (interactable), Mask Layer 1 (player)
- [ ] Collision coverage tests pass — `ModelConfig` entry updated and all 4 generated tests pass
- [ ] Scene saved and committed

> **Recycler (M4):** No Blender build script — mesh produced manually. retroactive build script not created. **Gap noted for future machines.**
>
> **Fabricator (M5):** `build_fabricator_module.py` produced via Blender Python pipeline. Mesh at `game/assets/meshes/machines/mesh_fabricator_module.glb` (79 KB, ~1,135 verts). `_place_module_visual()` in `test_world.gd` handles `"fabricator"` module_id with InteractionArea.

---

### Step 3 — Interaction Panel UI Design
**Owner:** ui-ux-designer
**Depends on:** Step 1 (design brief) — can run in parallel with Step 2
**Handoff to:** gameplay-programmer (TICKET: Interaction Panel Implementation)

Produce wireframes for the machine's interaction panel UI.

Required deliverables:
- Panel wireframe at `docs/design/wireframes/m<N>/<machine_name>-panel.md`
- Machine 3D form factor wireframe at `docs/design/wireframes/m<N>/<machine_name>-machine.md` (if applicable)
- Consistency check: panel must reuse slot, button, and layout patterns from the M3 UI style guide (`docs/design/ui-style-guide.md`)

Panel must specify:
- Input slot(s): resource type(s), quantity, selection method
- Output slot(s): result resource, collect interaction
- Active job display: progress indicator style (bar vs. timer), recipe identification
- Cancel/close behavior
- Error states: insufficient resources, machine unpowered, inventory full

> **Recycler (M4):** TICKET-0042. Panel delivered alongside ship globals HUD and sidebar. Key decision: panel is a screen-space overlay representing the machine's built-in screen. Machine screen brightens when panel is open.
>
> **Fabricator (M5):** TICKET-0065 (IN_REVIEW at M5 Foundation phase close). Panel follows same screen-space overlay pattern. Adds recipe selector for multiple output types (Spare Battery, Head Lamp).

---

### Step 4 — Tech Tree Node Definition
**Owner:** systems-programmer (or producer at design doc stage)
**Depends on:** tech tree data layer exists (TICKET-0060 or equivalent)
**Handoff to:** systems-programmer (Step 6 — Data Layer)

Define the tech tree node that gates this machine's unlock.

Required fields per node:
- `id`: snake_case identifier (e.g., `fabricator_module`)
- `display_name`: human-readable string
- `unlock_cost`: resource type + quantity
- `prerequisites`: list of node IDs that must be unlocked first
- `description`: one-sentence player-facing description

> **Recycler (M4):** No tech tree gate. Recycler was the first machine — the tech tree system did not exist yet. **All future machines are gated.**
>
> **Fabricator (M5):** Node `fabricator_module` — unlock cost 100 Metal, no prerequisites. Registered in `TechTreeDefs` (TICKET-0060). Automation Hub (`automation_hub`) requires `fabricator_module` as prerequisite.

---

### Step 5 — Build Cost Specification
**Owner:** producer (design decision), systems-programmer (implementation)
**Depends on:** module system exists (ModuleDefs + ModuleManager from M4)
**Handoff to:** systems-programmer (Step 6 — Data Layer)

Define the physical install cost and operating parameters of the module.

Required fields:
- **Install cost:** resource type + quantity (paid once from player inventory at install time)
- **Power draw:** units consumed from ship power grid (must not exceed baseline alone; document if upgrade power is needed)
- **Weight class:** Light / Medium / Heavy (affects future navigation fuel calculations)
- **Tech tree gate:** which node must be unlocked before install is permitted

> **Recycler (M4):** Install cost: Scrap Metal (quantity left to designer's discretion — set at implementation). Power draw: 10.0 units (within BASELINE_POWER=30.0). No tech tree gate. Weight class not formally specified in M4 — retroactively Medium.
>
> **Fabricator (M5):** Install cost: TBD (placeholder — Studio Head to confirm). Power draw: matched to Recycler (10.0) as placeholder. Tech tree gate: `fabricator_module`. Weight class: Medium (TICKET-0061).

---

### Step 6 — Data Layer Implementation
**Owner:** systems-programmer
**Depends on:** Steps 4 and 5 (node and cost specs confirmed)
**Handoff to:** gameplay-programmer (Step 7 — Interaction Panel), ui-ux-designer (signal reference for Step 3 if parallel)

Implement the machine as a module in the module system.

Checklist:
- [ ] Module data class created extending module base class (e.g., `FabricatorModule`)
- [ ] Module registered in `ModuleDefs` catalog with all required fields (id, display_name, tier, install_cost, power_draw, slot_type, tech_tree_gate)
- [ ] Tech tree gate check wired in `ModuleManager.install_module()` — blocks install if node is not unlocked
- [ ] Recipe catalog defined (data file: `scripts/data/<machine_name>_defs.gd`)
- [ ] Machine autoload created (`scripts/systems/<machine_name>.gd`) with:
  - `queue_job(recipe_id)` — validates inputs, deducts inventory, starts job
  - `cancel_job()` — stops active job (inputs not refunded in M5)
  - `job_started` and `job_completed` signals
  - Progress tracking (float 0.0–1.0, delta-based)
  - Output mode: inventory deposit on completion
- [ ] Machine autoload registered in `project.godot`
- [ ] All scripts load clean with no Godot errors or warnings
- [ ] All code follows `docs/engineering/coding-standards.md`

> **Recycler (M4):** `Recycler` autoload at `game/scripts/systems/recycler.gd`. Recipe: 3 Scrap Metal → 1 Metal, 5s. Note: method is `is_job_active()` not `is_processing()` — conflicts with Node base class method.
>
> **Fabricator (M5):** `Fabricator` autoload at `game/scripts/systems/fabricator.gd`. `FabricatorDefs` at `game/scripts/data/fabricator_defs.gd`. Dual output modes (inventory/equip). Tech tree gate field added to `ModuleDefs`; `get_tech_tree_gate()` helper added; gate check wired in `ModuleManager`.

---

### Step 7 — Interaction Panel Implementation
**Owner:** gameplay-programmer
**Depends on:** Step 2 (mesh in scene), Step 3 (wireframes DONE), Step 6 (data layer DONE)
**Handoff to:** qa-engineer (Step 8 — QA)

Wire the machine's interaction panel into the game world.

Checklist:
- [ ] Panel scene created at `game/scenes/ui/panels/<machine_name>_panel.tscn`
- [ ] Panel opens on interact input when player is in range of the machine's `InteractionArea`
- [ ] Panel opens without pausing the game; player movement and action inputs suppressed via `InputManager`; game world and all machines continue running at default `PROCESS_MODE_INHERIT` (DEC-0001)
- [ ] Input slot: player selects recipe/input from inventory; invalid recipes grayed out
- [ ] Active job display: progress bar updates live while panel is open
- [ ] Output slot: result appears on `job_completed`; player collects manually
- [ ] Insufficient resource state communicated clearly (text feedback, not silent failure)
- [ ] Panel closes gracefully if player exits ship while open
- [ ] All input routed through `InputManager`
- [ ] Follows wireframe from Step 3 and M3 UI style guide
- [ ] No Godot editor errors or warnings

> **Recycler (M4):** TICKET-0045. `RecyclerPanel` scene. Integrated into `test_world.gd`. Originally called `get_tree().paused = true` and set `Recycler.process_mode = ALWAYS` as a workaround to keep the machine running through the pause — both are obsolete per DEC-0001 (`docs/studio/decision-log.md`). TICKET-0077 removed both; the Recycler now runs at default `PROCESS_MODE_INHERIT`. **Do not use `PROCESS_MODE_ALWAYS` or `get_tree().paused` for future machines.**
>
> **Fabricator (M5):** TICKET-0069. Panel adds recipe selector (multiple output types). The Fabricator is the **canonical reference** for the correct model (DEC-0001): panel opens without pausing the game; player inputs suppressed via `InputManager`; machine runs at default `PROCESS_MODE_INHERIT`. Use the Fabricator, not the Recycler, as the reference for future machines.

---

### Step 8 — QA Checklist
**Owner:** qa-engineer
**Depends on:** Step 7 complete (all gameplay implementation DONE)

End-to-end loop test for every new ship machine:

| # | Test | Pass Condition |
|---|------|----------------|
| 1 | Tech tree unlock | Player can spend required resources to unlock the machine's tech tree node |
| 2 | Install — insufficient resources | Install blocked when player lacks required install cost items |
| 2.5 | Collision coverage tests | All `test_collision_coverage_unit` tests for this machine's mesh pass with zero failures |
| 3 | Install — success | Machine installs when player has sufficient resources; items deducted from inventory |
| 4 | Power overload | Install blocked if machine power draw would exceed available ship power |
| 5 | Panel open | Interact with installed machine opens panel; game input suppressed |
| 6 | Panel — insufficient input | Queuing a job with insufficient input resources shows feedback; no job started |
| 7 | Job start | Valid job queues; input resources deducted from inventory |
| 8 | Job progress | Progress indicator updates over time while panel is open |
| 9 | Job completion | `job_completed` signal fires; output appears in output slot |
| 10 | Output collect | Player collects output; items added to inventory |
| 11 | Panel close mid-job | Panel closes cleanly; job continues running in background |
| 12 | Collect after panel reopen | Output collected correctly after panel close/reopen cycle |
| 13 | Remove module | Module uninstalls; power draw deregistered from ShipState |
| 14 | Reinstall after remove | Machine can be reinstalled (cost paid again) |
| 15 | Full loop | Unlock → Install → Queue job → Collect output completes without errors |

> **Recycler (M4):** QA run in TICKET-0049. All tests passed. 284/284 total test suite at M4 close.
>
> **Fabricator (M5):** QA run in TICKET-0076. Will extend above checklist with recipe selector tests (multiple output types) and mining minigame yield integration.

---

## Agent Responsibility Matrix

| Step | Agent | Key Output |
|------|-------|------------|
| 1 — Design Brief | producer / ui-ux-designer | Form factor spec, placement zone |
| 2 — 3D Mesh | technical-artist | `.glb` mesh in ship interior scene, `InteractionArea` attached |
| 3 — UI Design | ui-ux-designer | Wireframes for panel and machine form |
| 4 — Tech Tree Node | systems-programmer | Node definition in `TechTreeDefs` |
| 5 — Build Cost | producer → systems-programmer | Install cost, power draw, weight class, gate |
| 6 — Data Layer | systems-programmer | Module catalog entry, autoload, recipe catalog |
| 7 — Interaction Panel | gameplay-programmer | Panel scene wired to mesh InteractionArea and autoload signals |
| 8 — QA | qa-engineer | End-to-end loop test passing |

---

## Cross-Agent Handoff Points

1. **producer → technical-artist:** Design brief (Step 1) must be complete before mesh production begins
2. **technical-artist → gameplay-programmer:** Mesh in scene with `InteractionArea` attached before panel implementation
3. **ui-ux-designer → gameplay-programmer:** Wireframes at DONE status before panel implementation begins
4. **systems-programmer → gameplay-programmer:** Data layer autoload registered and signals documented in handoff notes before panel implementation
5. **gameplay-programmer → qa-engineer:** All Gameplay phase tickets DONE before QA begins

---

## File Naming Conventions

| Artifact | Pattern |
|----------|---------|
| Blender build script | `blender_experiments/build_<machine_id>.py` |
| Asset brief | `docs/art/asset-briefs/<machine_id>.md` |
| Mesh file | `game/assets/meshes/machines/mesh_<machine_id>_module.glb` |
| Panel wireframe | `docs/design/wireframes/m<N>/<machine_id>-panel.md` |
| Machine wireframe | `docs/design/wireframes/m<N>/<machine_id>-machine.md` |
| Data defs script | `game/scripts/data/<machine_id>_defs.gd` |
| System autoload | `game/scripts/systems/<machine_id>.gd` |
| Panel scene | `game/scenes/ui/panels/<machine_id>_panel.tscn` |

---

## Known Gaps (Retrofitted from M4 Recycler)

| Gap | Status | Notes |
|-----|--------|-------|
| No Blender build script for Recycler mesh | Accepted | Recycler predates the formalized pipeline. M5+ machines must have a build script. |
| Recycler weight class not formally specified | Accepted | Retroactively Medium for future navigation calculations. |
| Recycler install cost quantity undocumented at ticket level | Accepted | Set at implementation time. M5+ machines should define cost at Step 5 before implementation. |
| Recycler has no tech tree gate | By design | Recycler was the first machine; tech tree introduced in M5. All subsequent machines must have a tech tree gate. |
