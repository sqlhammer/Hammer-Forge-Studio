## Defines a drone mining program: filters, tool assignment, and priority configuration.
## A DroneProgram is assigned to a DroneAgent to govern its targeting behavior.
class_name DroneProgram
extends Resource

# ── Exported Variables ────────────────────────────────────

## Filter: only target deposits of this resource type. NONE means accept any type.
@export var target_resource_type: ResourceDefs.ResourceType = ResourceDefs.ResourceType.NONE

## Filter: only target deposits at or above this purity. ONE_STAR accepts all purities.
@export var minimum_purity: ResourceDefs.Purity = ResourceDefs.Purity.ONE_STAR

## Filter: only target deposits requiring this tool tier or lower.
@export var tool_tier_assignment: ResourceDefs.DepositTier = ResourceDefs.DepositTier.TIER_1

## Maximum distance (in world units) the drone will travel to reach a target deposit.
@export var extraction_radius: float = 100.0

## Priority order for target selection when multiple deposits qualify.
## Lower values = higher priority (0 = highest priority).
@export var priority_order: int = 0

# ── Public Methods ────────────────────────────────────────

## Returns true if this program would accept the given deposit as a valid target.
## Deposit must have completed Phase 2 Analysis (scan_state == ANALYZED).
func accepts_deposit(deposit: Deposit) -> bool:
	# Enforce scanner-first constraint: only analyzed deposits may be targeted.
	if deposit.get_scan_state() != Deposit.ScanState.ANALYZED:
		return false

	if deposit.is_depleted():
		return false

	# Resource type filter — NONE means any type is acceptable.
	if target_resource_type != ResourceDefs.ResourceType.NONE:
		if deposit.resource_type != target_resource_type:
			return false

	# Purity filter.
	if deposit.purity < minimum_purity:
		return false

	# Tool tier filter — deposit tier must not exceed assignment.
	if deposit.deposit_tier > tool_tier_assignment:
		return false

	return true
