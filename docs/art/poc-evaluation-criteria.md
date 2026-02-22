# PoC Evaluation Criteria: 3D Asset Pipeline

**Ticket:** TICKET-0008
**Author:** game-designer
**Date:** 2026-02-22

> This document defines the scoring framework used to compare the Blender Python pipeline (TICKET-0009) against the AI generation pipeline (TICKET-0010). The technical-artist uses this framework in TICKET-0011 to produce a clear recommendation for Studio Head.

---

## Scoring Method

Each pipeline is scored across **six dimensions**. Each dimension is rated **1–5** and multiplied by its **weight**. The final score is the weighted sum.

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
| 1 | **Visual Quality** | 25% | Does the output match the game's stylized sci-fi aesthetic? |
| 2 | **Iteration Speed** | 20% | How long does one asset take from brief to importable GLB? |
| 3 | **Consistency** | 20% | Can multiple assets share a coherent visual language? |
| 4 | **Godot Compatibility** | 15% | Does the output import cleanly with correct scale, UVs, and materials? |
| 5 | **AI-Team Suitability** | 10% | Can agents operate this pipeline without manual 3D modeling skills? |
| 6 | **Maintainability** | 10% | Can another agent reproduce or modify an asset using documented steps? |
| | **Total** | **100%** | |

### Weight Rationale

- **Visual Quality (25%):** The game's art direction is a core differentiator. If the output doesn't match the aesthetic, nothing else matters.
- **Iteration Speed (20%):** The team is AI-agent-driven. Fast iteration enables rapid prototyping and course correction.
- **Consistency (20%):** Four diverse assets must look like they belong in the same game. A pipeline that produces one great asset but can't maintain style across types is unreliable.
- **Godot Compatibility (15%):** Import friction kills velocity. Scale, UVs, materials, and file format must work without manual cleanup.
- **AI-Team Suitability (10%):** The production team is AI agents. A pipeline requiring manual vertex editing or sculpting is a bottleneck.
- **Maintainability (10%):** The pipeline must be reproducible. If only the original operator can make it work, it's fragile.

---

## Per-Dimension Scoring Rubric

### 1. Visual Quality (25%)

Evaluate each of the four PoC assets against the art style targets defined in the asset briefs.

| Score | Criteria |
|-------|----------|
| 1 | Output is unrecognizable or stylistically wrong (photorealistic, cartoonish, generic) |
| 2 | Recognizable intent but proportions, silhouette, or material reads are off |
| 3 | Matches the stylized sci-fi tone; silhouette and material zones are correct; minor issues |
| 4 | Strong aesthetic match; distinct material zones read well; would need only minor tweaks for production |
| 5 | Nails the Outer Wilds / Hades-inspired aesthetic; could ship with minimal polish |

### 2. Iteration Speed (20%)

Measure wall-clock time from receiving the asset brief to having an importable `.glb` file.

| Score | Criteria |
|-------|----------|
| 1 | > 8 hours per asset |
| 2 | 4–8 hours per asset |
| 3 | 1–4 hours per asset |
| 4 | 15 min – 1 hour per asset |
| 5 | < 15 minutes per asset |

Record actual times for each of the four assets. Score based on the average.

### 3. Consistency (20%)

Compare the four PoC assets against each other. Do they look like they belong in the same game?

| Score | Criteria |
|-------|----------|
| 1 | Assets look like they came from different games; no shared visual language |
| 2 | Some shared elements but noticeable style drift between asset types |
| 3 | Coherent visual language with minor inconsistencies in proportion or detail density |
| 4 | Strong cohesion; all four assets clearly share an art style; minor variation acceptable |
| 5 | Unified visual language across all four assets; could be mistaken for a single artist's output |

### 4. Godot Compatibility (15%)

Import each `.glb` into Godot 4.5 and evaluate.

| Score | Criteria |
|-------|----------|
| 1 | Import fails or produces unusable results (missing geometry, broken transforms) |
| 2 | Imports but requires significant manual fixes (wrong scale, flipped normals, broken UVs) |
| 3 | Imports correctly; minor issues fixable with Godot import settings (scale factor, material reassignment) |
| 4 | Clean import; correct scale, intact UVs, materials map to Godot's StandardMaterial3D with minimal adjustment |
| 5 | Perfect import; drop-in ready with correct scale, clean UVs, and PBR-compatible materials |

### 5. AI-Team Suitability (10%)

Could an AI agent (LLM with code execution) operate this pipeline end-to-end?

| Score | Criteria |
|-------|----------|
| 1 | Requires manual 3D modeling, sculpting, or visual judgment that only a human artist can provide |
| 2 | Mostly automated but requires manual intervention at key steps (UV unwrapping, material painting) |
| 3 | Largely scriptable/automatable; manual steps are limited to parameter tuning |
| 4 | Fully scriptable with clear parameters; an agent can execute the pipeline given documentation |
| 5 | Fully automated end-to-end; brief in, GLB out, no human intervention |

### 6. Maintainability (10%)

Can the pipeline be documented and reproduced by a different agent?

| Score | Criteria |
|-------|----------|
| 1 | No documentation possible; relies on undocumented intuition or trial-and-error |
| 2 | Partially documentable but key steps are fragile or version-dependent |
| 3 | Documentable as a step-by-step SOP; another agent could follow it with some troubleshooting |
| 4 | Well-documented; another agent can reproduce results reliably with the SOP |
| 5 | Fully reproducible; SOP + scripts produce identical output given the same inputs |

---

## Scoring Template

Use this table to record scores for TICKET-0011 evaluation:

| Dimension | Weight | Blender Python (1-5) | Blender Weighted | AI Generation (1-5) | AI Weighted |
|-----------|--------|----------------------|------------------|----------------------|-------------|
| Visual Quality | 0.25 | | | | |
| Iteration Speed | 0.20 | | | | |
| Consistency | 0.20 | | | | |
| Godot Compatibility | 0.15 | | | | |
| AI-Team Suitability | 0.10 | | | | |
| Maintainability | 0.10 | | | | |
| **Total** | **1.00** | | **—** | | **—** |

**Recommendation threshold:** If both pipelines score within 0.3 points of each other (weighted total), recommend a hybrid approach. If one pipeline leads by > 0.3 points, recommend it as primary with the other as fallback for specific asset types where it scored higher.

---

## Additional Evaluation Notes

- **Score per asset, then average.** Each dimension should be evaluated independently for each of the four PoC assets, then averaged to produce the dimension score. This prevents one strong asset from hiding weaknesses on others.
- **Document evidence.** Each score must include a brief justification (1–2 sentences). Raw scores without reasoning are not actionable.
- **Record iteration times.** For the Iteration Speed dimension, log start and end times for each asset. This is the hardest dimension to assess subjectively — use actual data.
- **Import test on clean project.** Godot Compatibility should be tested by importing into a fresh Godot 4.5 project with default settings, not a project with custom import presets.
