# Icon Generation Method Research

**Ticket:** TICKET-0088
**Author:** technical-artist
**Date:** 2026-02-25
**Status:** COMPLETE

> This document evaluates candidate icon generation methods and selects 3 finalists for experiments (TICKET-0092–0094). The output here drives which method each experiment ticket uses and informs what format the style guides should target.
>
> Studio Head goals for M6: **low human effort · low financial cost · high quality**
> Style guide target: **line icons, 2px stroke weight, rounded caps; SVG preferred**
> Icon set size: **29 icons** (9 item icons at 48×48px primary; 20 HUD/functional icons at 16–32px)

---

## Methods Evaluated

Four distinct generation approaches were evaluated. Each is meaningfully different in workflow, cost structure, and output characteristics.

---

### Method 1: Programmatic SVG Generation (Python + svgwrite)

**Tool / approach:** Python 3.x with `svgwrite` library (v1.4.3+, pip-installable, MIT license) or direct SVG XML string construction. No external service dependency.

**Generation workflow:**
1. Agent writes one Python script per icon (or a single parameterized script with an icon selector)
2. Each script constructs an SVG document with `viewBox="0 0 24 24"`, `stroke-width="2"`, `stroke-linecap="round"`, `stroke-linejoin="round"`, and `fill="none"`
3. Icon shapes are drawn using SVG primitives: `<line>`, `<polyline>`, `<path>`, `<circle>`, `<rect>`
4. Script saves the `.svg` file to the experiment output directory
5. Godot imports via `SVGTexture` with no conversion step

**Human steps required:**
- None. Agent writes and executes all scripts. Optional: human visual review of rendered output via Godot editor screenshot.

**Estimated cost:**
- Per icon: $0.00
- Full set (29 icons): $0.00
- `svgwrite` is open source and pip-installable with no usage fees.

**Output format:** SVG natively. Matches the style guide's "SVG preferred" specification exactly. Godot's `SVGTexture` resource loads `.svg` files directly with no conversion.

**Preliminary quality assessment:** Quality is entirely determined by the agent's ability to construct accurate icon shapes as SVG path data. The output is mechanically precise (exact stroke width, exact rounded caps), but the visual design skill required to render a recognizable "hand drill" or "shield" as geometric paths is non-trivial. Icons may appear functional but flat — correct but potentially generic in aesthetic.

**Agent operability:** Fully agent-operable end-to-end. No GUI, no external service, no authentication. The agent writes Python, executes with `python icon_name.py`, and commits the SVG file. No human involvement after the initial script is written.

---

### Method 2: Recraft.ai API (AI Vector Generation)

**Tool / approach:** Recraft.ai REST API (v1), model `recraft-v3-svg`. Access via `https://api.recraft.ai`. Purpose-built for icon and logo generation with native SVG output.

**Generation workflow:**
1. Agent calls `POST /v1/images/generations` with a text prompt (e.g., `"minimalist line icon of a hand drill, 2px stroke, rounded caps, white on transparent, sci-fi style"`) and `style: "vector_illustration/line_art"` parameter
2. API responds with a URL or inline SVG content (async job for batch)
3. Agent downloads the SVG file and saves to experiment output directory
4. Optionally run a post-processing step to enforce `stroke-width="2"` and color inheritance if API output uses hardcoded colors

**Human steps required:**
- Account creation at recraft.ai (~5 minutes, one-time)
- API key generation (one-time, via web dashboard)
- Billing setup if free-tier credits are exhausted
- All icon generation steps after setup: fully automated

**Estimated cost:**
- API units: ~$0.01 per image generation (vectorization endpoint)
- Full set (29 icons): ~$0.29 — well within free-tier credit allocation
- Free tier provides sufficient credits for a full 29-icon experiment set; no paid plan required for the experiment

**Output format:** SVG natively (via `recraft-v3-svg` model). No conversion required for Godot. Post-processing a color/stroke normalization pass in Python is recommended (~10 lines of XML string replacement) to enforce style guide compliance.

**Preliminary quality assessment:** Recraft is the highest-quality AI option for stylized line icons. The model was purpose-trained for icon and logo generation, producing coherent visual language across a set when given consistent prompt templates. Risk: stylistic drift between icon categories (item icons vs HUD icons) may require prompt tuning to lock in the same weight and aesthetic. The 2px stroke constraint requires explicit prompting and likely a post-processing normalization pass.

**Agent operability:** Fully agent-operable after one-time API key setup. REST API with documented endpoints. Batch job support for async generation of the full 29-icon set in parallel. The only human step is initial account provisioning — matching the pattern established with Tripo3D in M2.

---

### Method 3: Blender Python Icon Renders (PNG)

**Tool / approach:** Blender 4.x in `--background` mode via `bpy` Python API. Extends the existing M2 3D asset pipeline (SOP at `docs/art/3d-pipeline-sop.md`). Blender is already installed on the agent's machine as a M2 pipeline dependency.

**Generation workflow:**
1. Agent writes a Python script that constructs icon geometry in Blender (flat 2D plane with Freestyle edge rendering, or simple 3D objects viewed from orthographic front camera)
2. Configure: orthographic camera at Z = 10, transparent background (`film_transparent = True`), Freestyle renderer for line-art output (line thickness 2px relative to 256px render)
3. Set material to pure white (`emission = 1.0`) for stroke color; background transparent
4. Render to PNG at 256×256px via `bpy.ops.render.render(write_still=True)`
5. Scale down to target sizes (48×48, 24×24, 16×16) using Godot import settings or a Python PIL post-step
6. Godot imports PNG via `ImageTexture` — no `SVGTexture` path

**Human steps required:**
- None (Blender already installed via M2 pipeline). Agent executes all steps headlessly.

**Estimated cost:**
- Per icon: $0.00
- Full set (29 icons): $0.00
- Blender is free and open source; M2 license already established.

**Output format:** PNG natively. This is a **format mismatch** against the style guide's "SVG preferred" specification. Conversion to SVG via pixel-trace (e.g., `potrace`) is possible but introduces artifacts on complex paths and adds a processing step. The icons would be integrated as `ImageTexture` resources instead of `SVGTexture`, which is workable but non-ideal for scalability across resolution targets.

**Preliminary quality assessment:** The M2 pipeline demonstrated that Blender Python produces highly consistent, deterministic output. Applied to icon generation: all 29 icons would share identical rendering parameters (camera, lighting, line weight), yielding a perfectly unified visual language. Con: Blender Freestyle line rendering is calibrated in pixels at render resolution, not a true SVG stroke — the output is a raster line-art render, not vector geometry. At small sizes (16×16px HUD icons), rasterization artifacts may reduce legibility.

**Agent operability:** Fully agent-operable once Blender is installed (already satisfied). The M2 SOP establishes the pattern. Each icon requires a distinct geometry script, which adds authoring time compared to prompt-based methods. Estimated ~30 minutes per icon script, though the geometry for 2D icons is far simpler than the 3D assets produced in M2.

---

### Method 4: game-icons.net Library + Scripted Customization

**Tool / approach:** game-icons.net open-source SVG library (~4,170+ icons), licensed CC BY 3.0. Full SVG source available at `https://github.com/game-icons/icons`. Batch customization via the project's own `colorize-svgs.sh` or a custom Python script.

**Generation workflow:**
1. Agent searches the game-icons GitHub repository for icons matching each of the 29 required names (drill, battery, shield, lightning bolt, etc.)
2. Agent downloads matching SVG source files from GitHub
3. Python script applies style transforms: normalize `viewBox`, set `stroke-width="2"`, `stroke-linecap="round"`, remove any `fill` attributes (replace with `currentColor` or `inherit`), validate dimensions
4. Output customized SVGs to experiment directory
5. For any of the 29 required icons with no library match, agent falls back to Method 1 (programmatic SVG construction) to fill gaps

**Human steps required:**
- Gap assessment: a review pass to identify which of the 29 icons have no satisfactory library match. The agent can automate search and flag uncertain matches, but human judgment on "is this close enough?" adds quality.
- Minimum viable path: agent runs automated search, auto-selects closest match by name, skips human review. Reduces quality of gap-fill decisions but eliminates human involvement.

**Estimated cost:**
- Per icon: $0.00
- Full set (29 icons): $0.00
- CC BY 3.0 requires attribution in game credits (one-line credit).

**Output format:** SVG natively. The library delivers SVG source files. Style transforms are lightweight XML edits. No conversion required for Godot.

**Preliminary quality assessment:** game-icons.net icons use a consistent monochromatic line style with good symbol readability — a reasonable baseline for the sci-fi aesthetic. Coverage assessment against the 29 required icons shows strong overlap for common symbols (lightning bolt, shield, padlock, checkmark, drill-like shapes) but poor coverage for project-specific icons (automation hub, resource node, scan ping, compass tick). An estimated 10–15 of the 29 icons would require Method 1 gap-fill, making this a hybrid approach rather than a standalone method. Attribution requirement adds one line to game credits.

**Agent operability:** Mostly agent-operable. GitHub API-based SVG download, Python style transforms, and gap-fill fallback are all fully scriptable. The icon search and match-quality judgment can be automated but benefits from human review for the borderline cases.

---

## Comparison Summary

| Dimension | Method 1: Programmatic SVG | Method 2: Recraft.ai API | Method 3: Blender Render | Method 4: game-icons.net |
|-----------|---------------------------|--------------------------|--------------------------|--------------------------|
| Human effort | None | One-time API setup | None | Optional gap review |
| Financial cost | $0 | ~$0.29 (free tier) | $0 | $0 (attribution) |
| Output format | SVG (native) | SVG (native) | PNG (format mismatch) | SVG (native) |
| Agent operability | Full | Full (post-setup) | Full | Mostly full |
| Visual quality ceiling | Medium (design-limited) | High (AI-generated) | High (render quality) | Medium (library-limited) |
| Consistency | Perfect (deterministic) | Good (prompt-dependent) | Perfect (deterministic) | Good (library style) |
| Godot integration | SVGTexture (ideal) | SVGTexture (ideal) | ImageTexture (workable) | SVGTexture (ideal) |
| Coverage for all 29 icons | Full (agent draws all) | Full (agent prompts all) | Full (agent scripts all) | ~50–70% direct match |
| Pipeline integration | New | New | Extends M2 SOP | New |
| External service risk | None | Recraft API dependency | None | GitHub dependency (low) |

---

## Rationale for Eliminating Method 3

**Blender Python Renders (Method 3) is not selected as an experiment finalist.** Reasons:

1. **Format mismatch.** The style guide specifies "SVG preferred." Blender renders produce PNG raster output. PNG at 16×16px (HUD icons) introduces rasterization artifacts that reduce legibility — the same problem the SVG preference was designed to solve.
2. **No added value over Method 1.** Both methods have zero cost and full agent operability. Method 1 produces SVG (better format) while Method 3 produces PNG (inferior format). The only advantage of Blender is icon shape complexity (3D geometry is easier to render than to describe as SVG paths), but for the 2D line icons specified, the SVG path approach is tractable.
3. **M2 pipeline integration is not a benefit here.** The M2 SOP is for 3D mesh production. Icon art is 2D and does not reuse the mesh production workflow. Blender's inclusion would add the dependency cost without the pipeline benefit.

Blender remains available as a **fallback method** if all three experiments fail to meet quality standards.

---

## Selected Methods

These 3 methods are approved for experiments (TICKET-0092–0094):

**Experiment A — Programmatic SVG (Python svgwrite)**
Rationale: Zero cost, zero human effort, SVG-native output, perfectly deterministic. Tests the ceiling of what an agent can produce with pure geometric construction. Serves as the quality baseline and guaranteed fallback: even if the icons are simple, they will be pixel-perfect to spec.

**Experiment B — Recraft.ai API (AI Vector Generation)**
Rationale: Highest AI-quality ceiling for icon design. Purpose-built for the exact use case (icon generation, SVG output, consistent style sets). Low cost (~$0.29 for the full set), minimal human effort after one-time API setup. The most likely candidate to produce production-ready icons without manual polish.

**Experiment C — game-icons.net Library + Scripted Customization**
Rationale: Zero cost, proven sci-fi gaming aesthetic, SVG-native. Tests whether a library-sourced approach can cover enough of the 29 required icons to be viable. The fastest possible path to a complete set if library coverage is sufficient. Gap-fill via Method A for any missing icons keeps the experiment fully agent-operable.

---

## Output Format Recommendation for Style Guides

Based on this research, TICKET-0090 (item icon style guide) and TICKET-0091 (HUD icon style guide) should specify:

- **Primary format:** SVG, `viewBox="0 0 24 24"`, `stroke-width="2"`, `stroke-linecap="round"`, `stroke-linejoin="round"`, `fill="none"`, color via `currentColor`
- **Raster export:** PNG at 256×256px (for any Godot `ImageTexture` fallback paths)
- **Godot integration:** `SVGTexture` resource preferred; `ImageTexture` acceptable for any method that produces PNG
- **Atlas:** Consider an `AtlasTexture` sprite sheet if runtime performance requires batching (defer to QA findings)
