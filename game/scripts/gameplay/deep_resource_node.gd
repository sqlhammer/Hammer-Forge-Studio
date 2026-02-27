## Deep resource node — partially submerged deposit that yields indefinitely.
## Mines slowly for manual extraction; drones can mine these forever without depletion.
## Owner: gameplay-programmer
class_name DeepResourceNode
extends Deposit


# ── Constants ─────────────────────────────────────────────

## Default yield rate for deep nodes (10% of surface speed).
const DEEP_YIELD_RATE: float = 0.1

## Y offset to submerge the visual mesh below ground level.
const SUBMERGE_OFFSET: float = -0.5
