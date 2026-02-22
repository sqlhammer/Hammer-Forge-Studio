## Slot-based player inventory: add, remove, query, and stack management.
class_name Inventory
extends Node

# ── Signals ──────────────────────────────────────────────
signal slot_changed(slot_index: int)
signal item_added(resource_type: ResourceDefs.ResourceType, purity: ResourceDefs.Purity, quantity: int)
signal item_removed(resource_type: ResourceDefs.ResourceType, purity: ResourceDefs.Purity, quantity: int)
signal inventory_full

# ── Constants ─────────────────────────────────────────────
const MAX_SLOTS: int = 15
const MAX_STACK_SIZE: int = 100

# ── Private Variables ─────────────────────────────────────

## Each slot is a Dictionary: { "resource_type": ResourceType, "purity": Purity, "quantity": int }
## Empty slots are represented as empty dictionaries.
var _slots: Array[Dictionary] = []

# ── Built-in Virtual Methods ──────────────────────────────
func _ready() -> void:
	_slots.resize(MAX_SLOTS)
	for i: int in range(MAX_SLOTS):
		_slots[i] = {}

# ── Public Methods ────────────────────────────────────────

## Returns the slot data at the given index. Empty dict if empty.
func get_slot(index: int) -> Dictionary:
	if index < 0 or index >= MAX_SLOTS:
		return {}
	return _slots[index].duplicate()

## Returns true if a slot is empty.
func is_slot_empty(index: int) -> bool:
	if index < 0 or index >= MAX_SLOTS:
		return false
	return _slots[index].is_empty()

## Returns the number of occupied slots.
func get_used_slot_count() -> int:
	var count: int = 0
	for slot: Dictionary in _slots:
		if not slot.is_empty():
			count += 1
	return count

## Returns the number of empty slots.
func get_free_slot_count() -> int:
	return MAX_SLOTS - get_used_slot_count()

## Returns true if the inventory has no empty slots and no stackable room for the item.
func is_full() -> bool:
	return get_free_slot_count() == 0

## Adds items to the inventory. Stacks with matching type+purity first, then uses empty slots.
## Returns the quantity that could NOT be added (0 means all added successfully).
func add_item(resource_type: ResourceDefs.ResourceType, purity: ResourceDefs.Purity, quantity: int) -> int:
	if quantity <= 0 or resource_type == ResourceDefs.ResourceType.NONE:
		return quantity
	var remaining: int = quantity

	# First pass: stack into existing matching slots
	for i: int in range(MAX_SLOTS):
		if remaining <= 0:
			break
		if _slots[i].is_empty():
			continue
		if _slots[i].get("resource_type") == resource_type and _slots[i].get("purity") == purity:
			var current_qty: int = _slots[i].get("quantity", 0) as int
			var space: int = MAX_STACK_SIZE - current_qty
			if space > 0:
				var to_add: int = mini(remaining, space)
				_slots[i]["quantity"] = current_qty + to_add
				remaining -= to_add
				slot_changed.emit(i)

	# Second pass: fill empty slots
	for i: int in range(MAX_SLOTS):
		if remaining <= 0:
			break
		if not _slots[i].is_empty():
			continue
		var to_add: int = mini(remaining, MAX_STACK_SIZE)
		_slots[i] = {
			"resource_type": resource_type,
			"purity": purity,
			"quantity": to_add,
		}
		remaining -= to_add
		slot_changed.emit(i)

	var added: int = quantity - remaining
	if added > 0:
		item_added.emit(resource_type, purity, added)
	if remaining > 0:
		inventory_full.emit()
	return remaining

## Removes a quantity of a specific resource+purity from the inventory.
## Returns the quantity actually removed.
func remove_item(resource_type: ResourceDefs.ResourceType, purity: ResourceDefs.Purity, quantity: int) -> int:
	if quantity <= 0 or resource_type == ResourceDefs.ResourceType.NONE:
		return 0
	var remaining: int = quantity

	for i: int in range(MAX_SLOTS):
		if remaining <= 0:
			break
		if _slots[i].is_empty():
			continue
		if _slots[i].get("resource_type") == resource_type and _slots[i].get("purity") == purity:
			var current_qty: int = _slots[i].get("quantity", 0) as int
			var to_remove: int = mini(remaining, current_qty)
			current_qty -= to_remove
			remaining -= to_remove
			if current_qty <= 0:
				_slots[i] = {}
			else:
				_slots[i]["quantity"] = current_qty
			slot_changed.emit(i)

	var removed: int = quantity - remaining
	if removed > 0:
		item_removed.emit(resource_type, purity, removed)
	return removed

## Removes a quantity from a specific slot. Returns the quantity actually removed.
func remove_from_slot(index: int, quantity: int) -> int:
	if index < 0 or index >= MAX_SLOTS or quantity <= 0:
		return 0
	if _slots[index].is_empty():
		return 0
	var current_qty: int = _slots[index].get("quantity", 0) as int
	var to_remove: int = mini(quantity, current_qty)
	var resource_type: ResourceDefs.ResourceType = _slots[index].get("resource_type") as ResourceDefs.ResourceType
	var purity: ResourceDefs.Purity = _slots[index].get("purity") as ResourceDefs.Purity
	current_qty -= to_remove
	if current_qty <= 0:
		_slots[index] = {}
	else:
		_slots[index]["quantity"] = current_qty
	slot_changed.emit(index)
	if to_remove > 0:
		item_removed.emit(resource_type, purity, to_remove)
	return to_remove

## Returns the total count of a resource type across all slots (any purity).
func get_total_count(resource_type: ResourceDefs.ResourceType) -> int:
	var total: int = 0
	for slot: Dictionary in _slots:
		if slot.get("resource_type") == resource_type:
			total += slot.get("quantity", 0) as int
	return total

## Returns the total count of a specific resource+purity combo.
func get_count(resource_type: ResourceDefs.ResourceType, purity: ResourceDefs.Purity) -> int:
	var total: int = 0
	for slot: Dictionary in _slots:
		if slot.get("resource_type") == resource_type and slot.get("purity") == purity:
			total += slot.get("quantity", 0) as int
	return total

## Returns true if the inventory contains at least `quantity` of the resource+purity.
func has_item(resource_type: ResourceDefs.ResourceType, purity: ResourceDefs.Purity, quantity: int = 1) -> bool:
	return get_count(resource_type, purity) >= quantity

## Returns how many more of this resource+purity can be added (considering existing stacks + empty slots).
func get_available_space(resource_type: ResourceDefs.ResourceType, purity: ResourceDefs.Purity) -> int:
	var space: int = 0
	for slot: Dictionary in _slots:
		if slot.is_empty():
			space += MAX_STACK_SIZE
		elif slot.get("resource_type") == resource_type and slot.get("purity") == purity:
			space += MAX_STACK_SIZE - (slot.get("quantity", 0) as int)
	return space

## Clears the entire inventory.
func clear_all() -> void:
	for i: int in range(MAX_SLOTS):
		if not _slots[i].is_empty():
			_slots[i] = {}
			slot_changed.emit(i)

## Returns a snapshot of all non-empty slots for persistence or UI.
func get_contents() -> Array[Dictionary]:
	var contents: Array[Dictionary] = []
	for i: int in range(MAX_SLOTS):
		if not _slots[i].is_empty():
			var entry: Dictionary = _slots[i].duplicate()
			entry["slot_index"] = i
			contents.append(entry)
	return contents
