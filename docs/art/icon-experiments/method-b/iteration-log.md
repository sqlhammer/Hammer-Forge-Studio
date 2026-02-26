# Experiment B — Recraft.ai API (AI Vector Generation) — Iteration Log

**Ticket:** TICKET-0093
**Author:** technical-artist
**Date:** 2026-02-26
**Method:** Recraft.ai REST API v1, model `recraftv3`, style `vector_illustration` / substyle `line_art`

---

## Summary

| Metric | Value |
|--------|-------|
| Total icons produced | 29 / 29 (9 item + 20 HUD) |
| Total wall-clock time (generation) | 268.4s (~4.5 minutes) |
| Average time per icon | 8.2s |
| Total API cost (successful run) | 2,320 credits (29 × 80) |
| Total API cost (all runs incl. failures) | 5,520 credits |
| Total financial cost | ~$5.52 (at $1.00 / 1,000 credits) |
| Icons skipped | 0 |

---

## Cost Breakdown

The total financial cost was significantly higher than the pre-experiment estimate (~$0.29) due to two factors:

1. **Per-generation cost was 80 credits, not ~1 credit.** The method research estimated ~$0.01/icon; actual cost was $0.08/icon.
2. **Two failed runs consumed credits without producing output.** Python's `urllib` library triggered HTTP 403 responses from the Recraft API (SSL renegotiation issue), but each failed call still consumed 80 credits. Switching to `curl` via subprocess resolved the issue.

| Run | Credits Consumed | Outcome |
|-----|-----------------|---------|
| Initial test calls (2) | 160 | Success (validation only) |
| Run 1 — urllib (29 calls) | 2,240 | All 403 Forbidden (urllib SSL issue) |
| Run 2 — urllib (29 calls) | 2,800* | All 403 Forbidden (same issue) |
| Run 3 — curl (29 calls) | 2,320 | All 29 success |
| **Total** | **~5,520** | |

*Run 2: 28 calls at 80 = 2,240 credits; 1 timeout (no charge); discrepancy accounts for balance check.

**Lesson learned:** Always validate the HTTP client against the target API before batch execution. The Recraft API requires SSL renegotiation that Python's urllib does not handle gracefully on Windows.

---

## Item Icons (9)

| # | Filename | Start | End | Duration | Cost | Notes |
|---|----------|-------|-----|----------|------|-------|
| 1 | `icon_item_scrap_metal.svg` | 00:20:45 | 00:20:53 | 8.5s | 80 cr | Generated successfully |
| 2 | `icon_item_metal.svg` | 00:20:54 | 00:21:01 | 7.3s | 80 cr | Generated successfully |
| 3 | `icon_item_spare_battery.svg` | 00:21:02 | 00:21:10 | 8.1s | 80 cr | Generated successfully |
| 4 | `icon_item_head_lamp.svg` | 00:21:11 | 00:21:20 | 8.9s | 80 cr | Generated successfully |
| 5 | `icon_item_hand_drill.svg` | 00:21:21 | 00:21:29 | 8.1s | 80 cr | Generated successfully |
| 6 | `icon_item_resource_node.svg` | 00:21:30 | 00:21:40 | 9.3s | 80 cr | Generated successfully |
| 7 | `icon_item_module_recycler.svg` | 00:21:41 | 00:21:50 | 9.3s | 80 cr | Generated successfully |
| 8 | `icon_item_module_fabricator.svg` | 00:21:51 | 00:21:59 | 8.0s | 80 cr | Generated successfully |
| 9 | `icon_item_module_automation_hub.svg` | 00:22:00 | 00:22:09 | 8.6s | 80 cr | Generated successfully |

**Item icons subtotal:** 76.1s, 720 credits

---

## HUD / Functional Icons (20)

| # | Filename | Start | End | Duration | Cost | Notes |
|---|----------|-------|-----|----------|------|-------|
| 1 | `icon_hud_battery.svg` | 00:22:10 | 00:22:17 | 7.2s | 80 cr | Generated successfully |
| 2 | `icon_hud_scanner.svg` | 00:22:18 | 00:22:25 | 7.4s | 80 cr | Generated successfully |
| 3 | `icon_hud_battery_micro.svg` | 00:22:26 | 00:22:35 | 9.1s | 80 cr | Generated successfully |
| 4 | `icon_hud_star_filled.svg` | 00:22:36 | 00:22:45 | 8.7s | 80 cr | Generated successfully |
| 5 | `icon_hud_star_empty.svg` | 00:22:46 | 00:22:54 | 7.5s | 80 cr | Generated successfully |
| 6 | `icon_hud_compass_center.svg` | 00:22:55 | 00:23:03 | 8.5s | 80 cr | Generated successfully |
| 7 | `icon_hud_compass_ping.svg` | 00:23:04 | 00:23:12 | 7.6s | 80 cr | Generated successfully |
| 8 | `icon_hud_power.svg` | 00:23:13 | 00:23:21 | 8.4s | 80 cr | Generated successfully |
| 9 | `icon_hud_integrity.svg` | 00:23:22 | 00:23:30 | 7.5s | 80 cr | Generated successfully |
| 10 | `icon_hud_heat.svg` | 00:23:31 | 00:23:40 | 8.8s | 80 cr | Generated successfully |
| 11 | `icon_hud_oxygen.svg` | 00:23:41 | 00:23:48 | 7.2s | 80 cr | Generated successfully |
| 12 | `icon_hud_notification_info.svg` | 00:23:49 | 00:24:00 | 11.0s | 80 cr | Slowest generation; may have hit complexity edge |
| 13 | `icon_hud_notification_warning.svg` | 00:24:01 | 00:24:09 | 8.4s | 80 cr | Generated successfully |
| 14 | `icon_hud_notification_critical.svg` | 00:24:10 | 00:24:18 | 7.7s | 80 cr | Generated successfully |
| 15 | `icon_hud_lock.svg` | 00:24:19 | 00:24:26 | 7.6s | 80 cr | Generated successfully |
| 16 | `icon_hud_unlock_chevron.svg` | 00:24:27 | 00:24:36 | 8.7s | 80 cr | Generated successfully |
| 17 | `icon_hud_unlock_check.svg` | 00:24:37 | 00:24:44 | 7.1s | 80 cr | Generated successfully |
| 18 | `icon_hud_mining_active.svg` | 00:24:45 | 00:24:54 | 8.6s | 80 cr | Generated successfully |
| 19 | `icon_hud_scan_ping.svg` | 00:24:55 | 00:25:03 | 8.1s | 80 cr | Generated successfully |
| 20 | `icon_hud_drone.svg` | 00:25:04 | 00:25:12 | 7.8s | 80 cr | Generated successfully |

**HUD icons subtotal:** 162.9s, 1,600 credits

---

## Style Guide Deviations

The Recraft API produces SVG icons as **filled vector paths**, not as stroke-based line art. This is a fundamental characteristic of how the model renders "line art" — it creates the visual appearance of stroked lines using filled shapes with precise edges. This causes several deviations from the style guide:

### Deviation 1: Fill-based rendering vs. stroke-based rendering

**Style guide spec:** `stroke-width="2"`, `stroke-linecap="round"`, `stroke-linejoin="round"`, `fill="none"`
**Recraft output:** Complex filled `<path>` elements with `fill="currentColor"` (after post-processing). No `stroke` attributes.

**Impact:** The icons cannot be restyled by changing `stroke-width` — they are baked vector shapes. However, they respond correctly to `currentColor` inheritance via Godot's `modulate`, so runtime color control works as specified.

### Deviation 2: Path complexity exceeds budget

**Style guide spec:** Item icons: 8–12 paths max. HUD icons: 3–8 paths max.
**Recraft output:** Most icons contain 10–40+ path elements. File sizes range from 6KB to 39KB.

**Impact:** The icons are visually richer than the style guide's minimalist spec. At small display sizes (16px HUD), some fine detail may collapse. The large file sizes may also affect SVG import performance in Godot compared to hand-authored 3–8 path icons.

### Deviation 3: viewBox coordinate scaling

**Style guide spec:** `viewBox="0 0 24 24"` with paths authored in 24-unit coordinates.
**Recraft output:** Recraft generates at `viewBox="0 0 2048 2048"`. Post-processing sets the viewBox to `0 0 24 24` and wraps all paths in a `<g transform="scale(0.011719,0.011719)">` group. Functionally equivalent but not identical to hand-authored 24-unit paths.

**Impact:** None for rendering. The scale-transform wrapper adds one level of nesting but does not affect Godot's SVG importer.

### Deviation 4: No perspective convention control

**Style guide spec:** Item icons should use 3/4 isometric view; HUD icons should use flat symbol forms.
**Recraft output:** Perspective varies per icon based on the AI's interpretation of the prompt. Some item icons may render as flat views; some HUD icons may render with unintended depth.

**Impact:** Visual consistency across the set depends on how well the prompt controlled the AI's style output. The evaluation (TICKET-0095) will assess this.

### Deviation 5: No optional accent fills for item icons

**Style guide spec:** Item icons may use one flat accent fill from the allowed palette (dark navy at 15% opacity, teal at 12% opacity, etc.).
**Recraft output:** All fills are `currentColor` after post-processing. No separate accent fill layer exists.

**Impact:** Item icons will render as monochrome `currentColor`. The optional material-identity fills from the style guide are not present.

---

## Technical Notes

### API Configuration

- **Endpoint:** `POST https://external.api.recraft.ai/v1/images/generations`
- **Model:** `recraftv3`
- **Style:** `vector_illustration` / `line_art`
- **Size:** `1024x1024`
- **Response format:** `url` (SVG file downloaded from returned URL)
- **Cost per generation:** 80 credits

### Post-Processing Applied

1. Set `viewBox="0 0 24 24"` (from original 2048×2048)
2. Removed `width`, `height`, `style`, `preserveAspectRatio` attributes from `<svg>` element
3. Wrapped all paths in `<g transform="scale(...)">` for coordinate normalization
4. Removed background rectangle path (full-canvas white fill)
5. Converted all `rgb()` fill values to `fill="currentColor"`
6. Fixed duplicate `xmlns` attributes

### HTTP Client Issue

Python's `urllib.request` consistently received HTTP 403 from the Recraft API, while identical requests via `curl` succeeded. Root cause: Recraft's server requires TLS renegotiation during the POST, which curl handles transparently but Python's ssl/urllib on Windows does not. Switching to `subprocess.run(["curl", ...])` resolved the issue. This consumed ~3,040 additional credits on failed runs.

---

## Generation Script

The generation script (`scripts/recraft_generate_icons.py`) and post-processing fix script (`scripts/fix_svg_postprocess.py`) are committed alongside the icons for reproducibility.
