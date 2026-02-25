# Icon Evaluation Criteria: 2D Icon Generation Pipeline

**Ticket:** TICKET-0089
**Author:** producer
**Date:** 2026-02-25

> This document defines the scoring framework used to compare the three icon generation experiments (TICKET-0092–0094). The technical-artist uses this framework in TICKET-0095 to produce a clear recommendation for Studio Head approval (TICKET-0096).
>
> The structure mirrors `docs/art/poc-evaluation-criteria.md` (M2 3D Asset PoC) so evaluation is familiar to the technical-artist. Adaptations reflect the specific requirements of 2D icon generation: minimal human effort, minimal financial cost, and maximum visual quality.

---

## Scoring Method

Each method is scored across **seven dimensions**. Each dimension is rated **1–5** and multiplied by its **weight**. The final score is the weighted sum.

**Rating scale:**

| Score | Meaning |
|-------|---------|
| 1 | Unacceptable — does not meet minimum requirements |
| 2 | Below expectations — significant issues that require workarounds |
| 3 | Acceptable — meets the bar with minor issues |
| 4 | Good — exceeds the bar; minor polish would make it production-ready |
| 5 | Excellent — production-quality or very close to it |

---

## Dimensions and Weights

| # | Dimension | Weight | Description |
|---|-----------|--------|-------------|
| 1 | **Visual Quality** | 25% | Does the output match the relevant style guide (item or HUD/functional)? |
| 2 | **Human Effort** | 20% | How much manual intervention is required per icon, start to finish? |
| 3 | **Financial Cost** | 20% | What is the total cost to generate the full 29-icon set? |
| 4 | **Consistency** | 15% | Do all icons across the full set share a coherent visual language? |
| 5 | **Scalability** | 10% | Are icons legible across all target sizes (16px–48px)? |
| 6 | **Godot Compatibility** | 5% | Does the output import cleanly as SVG or PNG with correct transparency and scale? |
| 7 | **Maintainability** | 5% | Can another agent produce additional icons by following the documented SOP? |
| | **Total** | **100%** | |

### Weight Rationale

- **Visual Quality (25%):** The game's art direction is a core differentiator. Icons that don't match the stylized sci-fi aesthetic are not shippable regardless of cost or speed.
- **Human Effort (20%):** The team is AI-agent-driven. Methods requiring a human artist per icon are incompatible with the studio's operating model. High effort = high ongoing cost and production bottleneck.
- **Financial Cost (20%):** Icon production is a large batch (29 icons). Per-icon costs that appear small multiply across the full set and future additions. Free or negligible cost is strongly preferred.
- **Consistency (15%):** Icons must look like they belong to the same game. A method that produces one great icon but fails to maintain style across 29 different subjects is unreliable.
- **Scalability (10%):** HUD icons must read at 16px; inventory icons at up to 48px. A method that only works at one scale has limited utility.
- **Godot Compatibility (5%):** Import friction kills velocity. SVG or PNG with correct transparency and scale must work without manual cleanup. This is a lower-weight gate because format issues are often fixable via post-processing.
- **Maintainability (5%):** The SOP must be reproducible by any agent, not just the original operator. This is lower-weight because the initial 29-icon set is the primary deliverable; future additions are secondary.

---

## Per-Dimension Scoring Rubric

### 1. Visual Quality (25%)

Evaluate each icon against its relevant style guide: the Item Icon Style Guide (TICKET-0090) for item icons, the HUD/Functional Icon Style Guide (TICKET-0091) for HUD icons. Score reflects match to the stylized sci-fi aesthetic defined in the applicable guide.

| Score | Criteria |
|-------|----------|
| 1 | Output is stylistically wrong — photorealistic, generic clip-art, or inconsistent with the sci-fi aesthetic |
| 2 | Recognizable intent but silhouette, line weight, color palette, or detail level is off |
| 3 | Matches the stylized sci-fi tone; silhouette and color reads are correct; minor issues that could ship with minor polish |
| 4 | Strong aesthetic match; clean silhouette, consistent line weight, correct palette; needs only light polish for production |
| 5 | Nails the stylized sci-fi aesthetic as defined in the style guide; could ship with no changes |

### 2. Human Effort (20%)

Measure the steps required per icon from a written brief to a production-ready file. Score 5 = fully automated (agent prompt in, icon file out, zero human steps). Score 1 = a human artist must be involved in every icon.

| Score | Criteria |
|-------|----------|
| 1 | Requires a human artist for every icon (manual drawing, painting, or sculpting) |
| 2 | Mostly automated but requires manual human review and correction on most icons |
| 3 | Largely automated; human intervention required at setup and spot-checking output |
| 4 | Fully agent-operable; human spot-checks only at batch level, not per-icon |
| 5 | Fully automated end-to-end; agent brief in, icon file out, no human steps at any stage |

### 3. Financial Cost (20%)

Evaluate total cost to generate the full 29-icon set (9 item icons + 20 HUD/functional icons). Calibrate to full-set cost, not per-icon cost in isolation.

| Score | Criteria |
|-------|----------|
| 1 | > $25 for the full set — unacceptably expensive for a single batch |
| 2 | $10–$25 for the full set — high cost; requires justification against quality gains |
| 3 | $2–$10 for the full set — acceptable cost; within normal tooling budget |
| 4 | < $2 for the full set — very low cost; negligible budget impact |
| 5 | Free or negligible ($0–$0.10) — no meaningful financial cost |

### 4. Consistency (15%)

Evaluate across the full 29-icon set: do all icons look like they belong to the same visual language? Evaluate item icons as a group and HUD icons as a group; then assess cross-group cohesion.

| Score | Criteria |
|-------|----------|
| 1 | Icons look like they came from different sources; no shared visual language |
| 2 | Some shared elements but noticeable style drift between icon types or subjects |
| 3 | Coherent visual language with minor inconsistencies in line weight, detail density, or palette |
| 4 | Strong cohesion; all 29 icons clearly share an art style; minor variation is acceptable |
| 5 | Unified visual language across all 29 icons; indistinguishable from a single artist's output |

### 5. Scalability (10%)

Test each icon at the two target sizes: 16px (smallest HUD use) and 48px (largest inventory slot). Score based on legibility across both extremes.

| Score | Criteria |
|-------|----------|
| 1 | Only usable at one size; icon is unrecognizable or broken at the other size |
| 2 | Marginally legible at both sizes but requires rework to be production-ready at either |
| 3 | Legible at both sizes with acceptable quality; minor detail loss at 16px is acceptable |
| 4 | Crisp and clear at both sizes; no rework required for either target size |
| 5 | Crisp and legible at all sizes from 16px to 48px, including intermediate sizes; zero rework |

### 6. Godot Compatibility (5%)

Import each icon into Godot 4.5 as SVG or PNG. Evaluate transparency, scale, and import warnings.

| Score | Criteria |
|-------|----------|
| 1 | Import fails or produces unusable results (broken transparency, wrong dimensions, missing file) |
| 2 | Imports but requires significant manual fixes (background bleed, wrong canvas size, import errors) |
| 3 | Imports correctly; minor issues fixable with Godot import settings or a one-time script |
| 4 | Clean import; correct canvas size, clean transparency, no import warnings |
| 5 | Perfect import; drop-in ready with correct dimensions, clean transparency, and no warnings on all 29 icons |

### 7. Maintainability (5%)

Can another agent (not the one who ran the experiment) produce additional icons beyond the 29 in the experiment set by following only the documented SOP?

| Score | Criteria |
|-------|----------|
| 1 | No reproducible SOP exists; only the original operator can replicate the results |
| 2 | Partially documentable but key steps are fragile, version-dependent, or require undocumented judgment |
| 3 | Documentable as a step-by-step SOP; another agent can follow it with some troubleshooting |
| 4 | Well-documented; another agent can reproduce results reliably with the SOP |
| 5 | Fully reproducible; SOP alone produces consistent output given the same inputs, with no troubleshooting required |

---

## Scoring Template

Use this table to record scores in TICKET-0095. Each dimension score is the average of per-icon scores for that dimension (see Additional Evaluation Notes). Weighted scores are dimension score × weight.

| Dimension | Weight | Exp A (1-5) | Exp A Weighted | Exp B (1-5) | Exp B Weighted | Exp C (1-5) | Exp C Weighted |
|-----------|--------|-------------|----------------|-------------|----------------|-------------|----------------|
| Visual Quality | 0.25 | | | | | | |
| Human Effort | 0.20 | | | | | | |
| Financial Cost | 0.20 | | | | | | |
| Consistency | 0.15 | | | | | | |
| Scalability | 0.10 | | | | | | |
| Godot Compatibility | 0.05 | | | | | | |
| Maintainability | 0.05 | | | | | | |
| **Total** | **1.00** | | **—** | | **—** | | **—** |

**Recommendation threshold:** If the top two methods score within 0.3 weighted points of each other, recommend a hybrid approach (e.g., use Method A for item icons and Method B for HUD icons, if one method excels per category). If one method leads by > 0.3 weighted points, recommend it as primary.

---

## Additional Evaluation Notes

- **Score each icon individually, then average.** Each dimension must be evaluated independently for each of the 29 icons, then averaged to produce the dimension score. This prevents a single strong icon from hiding weaknesses across the set. Reference `docs/art/icon-needs.md` for the full icon manifest.
- **Document evidence.** Each score must include a brief justification (1–2 sentences). Raw scores without reasoning are not actionable.
- **Use the applicable style guide.** Item icons are evaluated against the Item Icon Style Guide (TICKET-0090 output). HUD/functional icons are evaluated against the HUD/Functional Icon Style Guide (TICKET-0091 output). Do not apply one guide to both categories.
- **Test imports on a clean project.** Godot Compatibility should be tested by importing into a fresh Godot 4.5 project with default settings, not a project with custom import presets.
- **Log actual costs.** For Financial Cost, record the actual API cost or tool license fee for the full experiment run. Do not estimate — retrieve the actual charge from the tool's billing dashboard or usage log.
