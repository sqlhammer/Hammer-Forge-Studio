# UAT Sign-Off Procedure — [MILESTONE]

> **Template:** Populated by QA Engineer during the final QA phase, before requesting Studio Head sign-off.
> Save to `docs/studio/reports/` as `YYYY-MM-DD-[milestone]-uat-signoff.md`.
>
> **Studio Head:** Review each feature below, play-test as described, then mark each checkbox.
> When all checkboxes are marked `✅ Approved`, reply to the Producer to grant final milestone sign-off.

---

## Header

| Field | Value |
|-------|-------|
| **Milestone** | e.g., M8 — Ship Navigation |
| **Prepared By** | qa-engineer |
| **Date Prepared** | YYYY-MM-DD |
| **Test Build** | Commit hash or branch |
| **Sign-Off Status** | ⏳ Pending / ✅ Approved |

---

## How to Use This Document

1. Launch the game from the Godot editor (`res://game.tscn` or the debug launcher as noted per feature).
2. For each feature, check the **Verification Method** tag:
   - `unit-test` — Covered by unit tests (automated, no manual action needed)
   - `scene-validation` — Covered by scene property tests (automated, no manual action needed)
   - `integration-test` — Covered by integration tests (automated, no manual action needed)
   - **`manual-playtest`** — **Requires hands-on testing by Studio Head.** Follow the test steps.
3. For `manual-playtest` items, follow the **How to Test** steps.
4. Mark the checkbox:
   - `✅ Approved` — feature works as described, no blocking issues
   - `❌ Rejected` — feature is broken or missing; add a note describing the problem
5. Once all features are marked, sign off at the bottom of this document.

> **Note:** Items tagged `manual-playtest` are highlighted because they have NOT been verified by automated tests. These require the most attention during review.

---

## Feature Sign-Off Checklist

### [Feature Group Name — e.g., Navigation System]

---

#### [Feature Name] (TICKET-NNNN)

**Verification Method:** `manual-playtest` | `unit-test` | `scene-validation` | `integration-test`

**What changed:** Brief description of what was implemented or changed.

**How to test:**
1. Step one — e.g., "Open the navigation console (press `M` or interact with the console panel)"
2. Step two — e.g., "Select a destination biome from the list"
3. Step three — e.g., "Confirm the ship fuel is consumed and the biome loads"

**Expected result:** What the Studio Head should see/experience if working correctly.

**Automated coverage:** <!-- e.g., "test_navigation_unit: 12 tests, test_scene_properties_unit: 3 tests" or "None — manual only" -->

- [ ] ✅ Approved / ❌ Rejected — _Notes:_

---

#### [Feature Name] (TICKET-NNNN)

**Verification Method:** `manual-playtest` | `unit-test` | `scene-validation` | `integration-test`

**What changed:** Brief description.

**How to test:**
1. Step one
2. Step two

**Expected result:** Description.

**Automated coverage:** <!-- test references or "None — manual only" -->

- [ ] ✅ Approved / ❌ Rejected — _Notes:_

---

### [Feature Group Name — e.g., Fuel System]

---

#### [Feature Name] (TICKET-NNNN)

**Verification Method:** `manual-playtest` | `unit-test` | `scene-validation` | `integration-test`

**What changed:** Brief description.

**How to test:**
1. Step one
2. Step two

**Expected result:** Description.

**Automated coverage:** <!-- test references or "None — manual only" -->

- [ ] ✅ Approved / ❌ Rejected — _Notes:_

---

## Rejection Notes

> List any rejected features here with detail. QA Engineer will triage and open bug tickets.

| Feature | Ticket | Issue Description |
|---------|--------|-------------------|
| — | — | — |

---

## Final Sign-Off

> Complete this section after all checkboxes above are marked.

**Total Features:** N
**Approved:** N
**Rejected:** N

**Gate Condition:** All features must be `✅ Approved` for sign-off to be granted.

---

**Studio Head Sign-Off:**

- [ ] All features approved — milestone is cleared for close

**Signed off by:** Studio Head
**Date:** YYYY-MM-DD
