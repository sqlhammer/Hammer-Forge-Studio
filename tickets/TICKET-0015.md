---
id: TICKET-0015
title: "BLOCKER — Studio Head must approve pipeline decision before M2 QA proceeds"
type: BLOCKER
status: OPEN
priority: P0
owner: producer
created_by: producer
created_at: 2026-02-22
updated_at: 2026-02-22
milestone: "M2"
depends_on: []
blocks: [TICKET-0014]
tags: [blocker, art-pipeline, approval-required]
---

## Summary

TICKET-0011 (pipeline recommendation) is `IN_REVIEW` and has not received Studio Head approval. Despite this, technical-artist proceeded to mark TICKET-0012 (SOP) and TICKET-0013 (M3-ready assets) as DONE. QA (TICKET-0014) must not proceed until:

1. game-designer reviews the recommendation (unchecked AC on TICKET-0011)
2. Studio Head approves the pipeline decision in TICKET-0011's Activity Log
3. Studio Head explicitly ratifies or requests rework on TICKET-0012 and TICKET-0013

Additionally: the technical-artist's TICKET-0013 handoff notes reveal the final asset selection was switched to Blender-only, diverging from the hybrid pipeline recommendation in TICKET-0011. This scope decision was made unilaterally and requires Studio Head acknowledgment.

## Acceptance Criteria

- [ ] game-designer reviews `docs/art/pipeline-recommendation.md` and logs sign-off in TICKET-0011 Activity Log
- [ ] Studio Head approves pipeline decision in TICKET-0011 Activity Log
- [ ] Studio Head reviews TICKET-0013 Blender-only asset selection and either ratifies it or requests rework
- [ ] TICKET-0011 status updated to DONE by producer once all approvals are logged
- [ ] This BLOCKER ticket closed by producer

## Activity Log

- 2026-02-22 [producer] Created blocker. technical-artist completed TICKET-0012 and TICKET-0013 while TICKET-0011 was still IN_REVIEW awaiting Studio Head decision. TICKET-0014 gated until approvals are in place. Escalated to Studio Head.
