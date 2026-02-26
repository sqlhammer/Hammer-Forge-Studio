## Centralized physics layer bit-mask constants for the entire project.
## Use these constants everywhere instead of raw integers or local copies.
## See docs/engineering/physics-layers.md for the canonical layer assignments.
class_name PhysicsLayers

const PLAYER: int = 1 << 0       ## Layer 1 — player character body
const ENEMY: int = 1 << 1        ## Layer 2 — enemy character bodies
const ENVIRONMENT: int = 1 << 2  ## Layer 3 — static world geometry
const INTERACTABLE: int = 1 << 3 ## Layer 4 — doors, pickups, triggers
const PROJECTILE: int = 1 << 4   ## Layer 5 — player and enemy projectiles
