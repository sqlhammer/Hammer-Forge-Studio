# Animation API Documentation

**Owner:** character-animator
**Status:** Draft
**Last Updated:** —

> This directory contains one `.md` file per character documenting their AnimationTree parameters, states, and transition conditions. Gameplay Programmer uses these docs to integrate animation without reading the AnimationTree graph.

---

## File Naming

`docs/art/animation-api/<character-name>.md`

---

## Required Sections Per Character

1. **AnimationTree Overview** — type of root state machine, blend tree structure
2. **Parameters** — table of all parameters: name, type, range/values, purpose
3. **States** — table of all states: name, clip, loop behavior, entry condition
4. **Transitions** — table of all transitions: from state, to state, condition
5. **Root Motion** — whether root motion is enabled; which axis; how to use it
6. **Integration Notes** — what the Gameplay Programmer needs to set up to use this character

---

_[No characters documented yet — add files here as characters are animated]_
