---
id: TICKET-0088
title: "Generation method research — evaluate 3+ tools, select experiment finalists"
type: RESEARCH
status: OPEN
priority: P1
owner: technical-artist
created_by: producer
created_at: 2026-02-25
updated_at: 2026-02-25
milestone: "M6"
milestone_gate: "M5"
phase: "Foundation"
depends_on: []
blocks: [TICKET-0090, TICKET-0091, TICKET-0092, TICKET-0093, TICKET-0094]
tags: [icons, research, pipeline, foundation]
---

## Summary

Before style guides or experiments can begin, we need to know which generation methods are viable candidates. This ticket researches the landscape of icon generation approaches — AI image tools, vector/SVG tools, procedural scripts, rendered 3D bakes, and others — and produces a documented shortlist of exactly 3+ methods to be run as experiments. The output doc drives which experiment tickets get run and what format the style guides should target.

## Acceptance Criteria

- [ ] `docs/art/icon-method-research.md` created and committed
- [ ] At least 3 distinct generation methods are evaluated. Methods must meaningfully differ (e.g., two AI image generators count as two methods only if they have substantially different workflows, cost structures, or output characteristics)
- [ ] For each evaluated method, the document covers:
  - **Tool / approach name** and version or access URL
  - **Generation workflow** — step-by-step summary of how an agent produces one icon from a brief
  - **Human steps required** — enumerate every step that requires a human (or cannot be scripted/automated)
  - **Estimated cost** — cost per icon and per full set (~20 icons); note if free tier is sufficient
  - **Output format** — what format the tool natively produces (SVG, PNG, sprite sheet, etc.) and any conversion required for Godot
  - **Preliminary quality assessment** — 1–2 sentence qualitative take on fit for stylized sci-fi aesthetic
  - **Agent operability** — can an AI agent operate this tool end-to-end without a human GUI? If not, what is the minimum human involvement?
- [ ] The document ends with a **Selected Methods** section listing exactly the 3+ methods approved for experiments, with a 1-sentence rationale for each selection
- [ ] Experiment tickets (TICKET-0092, TICKET-0093, TICKET-0094) are updated with the actual method name in their titles after this ticket is DONE

## Implementation Notes

- Prioritize methods that balance all three Studio Head goals: low human effort, low financial cost, high quality
- Good starting candidates to evaluate (do not limit to these): AI image generators (e.g., DALL-E, Midjourney, Stable Diffusion via API), SVG icon libraries + scripted customization, pixel-art generator scripts, Blender icon renders (bake 3D objects to 2D sprites), vector AI tools (e.g., Recraft, Adobe Firefly)
- The M2 pipeline decision established Blender Python as the primary 3D asset pipeline — consider whether a Blender-based icon render approach would integrate cleanly with that SOP
- This is a research ticket: do not generate any icons. The output is documentation only.

## Handoff Notes

(Leave blank until handoff occurs.)

## Activity Log

- 2026-02-25 [producer] Created ticket for M6 Foundation phase
