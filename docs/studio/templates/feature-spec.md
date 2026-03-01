# Feature Specification — [Feature Name]

**Ticket:** TICKET-NNNN
**Author:** [agent-slug]
**Testability Reviewed By:** [qa-engineer or systems-programmer]
**Status:** Draft / Approved / Implemented

---

## 1. Overview

One paragraph: what does this feature do from the player's perspective?

---

## 2. Acceptance Criteria

Numbered. Each criterion is independently testable.

1. [Criterion — include concrete values, not vague language]
2. ...

---

## 3. Input/Output Contracts

### Public API

| Method / Signal | Input | Output | Side Effects |
|---|---|---|---|
| `SystemName.method(param: Type)` | Description | Return type | State changes, signals emitted |

### Signals

| Signal | Emitter | Payload | When Emitted |
|---|---|---|---|
| `signal_name` | `ClassName` | `(param: Type)` | Condition |

---

## 4. State Machine (if applicable)

| State | Entry Condition | Exit Condition | Invariants |
|---|---|---|---|

---

## 5. UI State Machine (if applicable)

| UI State | Visible Elements | Disabled Elements | Transitions |
|---|---|---|---|

---

## 6. Scene Property Assertions

Properties that must hold in committed `.tscn` files. These become test data for `test_scene_properties_unit.gd`.

| Scene Path | Node Path | Property | Expected Value |
|---|---|---|---|
| `res://scenes/ui/example.tscn` | `Root/ChildNode` | `anchors_preset` | `5` |

---

## 7. Failure States

| Condition | Expected Behavior | Test Strategy |
|---|---|---|
| Null input | Return default / emit error | Unit test |
| Insufficient resource | Block action, show warning | Unit + integration |

---

## 8. Testability Gate

Before implementation begins, ALL must be confirmed:

- [ ] Every acceptance criterion maps to at least one test (unit, scene validation, or integration)
- [ ] Scene property assertions filled for every `.tscn` created or modified
- [ ] At least one integration test scenario defined for multi-system features
- [ ] Failure states enumerated with test strategies

**Reviewed by:** _______________  **Date:** _______________

---

## 9. Traceability Matrix

| AC # | Unit Test | Scene Validation | Integration Test | Playtest Step | Regression Item |
|---|---|---|---|---|---|
| 1 | `test_foo_unit::test_bar` | `test_scene_properties::foo_anchor` | `test_foo_integration::flow` | `navigate.yaml` step 4 | Regression #42 |

---

## 10. Implementation Notes

Technical notes for the implementing agent.
