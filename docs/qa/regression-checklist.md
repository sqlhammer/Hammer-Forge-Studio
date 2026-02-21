# Regression Test Checklist

**Owner:** qa-engineer
**Status:** Draft
**Last Updated:** —

> Execute this checklist at the end of every milestone before QA sign-off. Add new items as systems are implemented. Mark each item Pass / Fail / N/A.

---

## How to Use

1. Copy this checklist into a new file: `docs/qa/reports/YYYY-MM-DD-regression.md`
2. Execute each test in a fresh game run
3. Mark results: ✅ Pass / ❌ Fail (file BUG ticket) / ➖ N/A
4. Attach the completed checklist to the milestone sign-off report

---

## Core Systems

| # | Test | Expected Result | Result |
|---|------|-----------------|--------|
| 1 | Game launches without errors | No errors in Godot output log | |
| 2 | Save and load completes successfully | Game state restored after load | |
| 3 | Input actions respond correctly | All mapped inputs trigger expected behavior | |

---

## Gameplay

_[Add test cases here as gameplay systems are implemented]_

---

## UI

_[Add test cases here as UI screens are implemented]_

---

## Audio

_[Add test cases here as audio systems are implemented]_

---

## Performance

_[Add frame rate and memory targets here once established]_
