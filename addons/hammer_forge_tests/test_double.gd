## Provides mock and stub capabilities for unit testing. Create a TestDouble,
## stub method return values, then call call_stub() to simulate invocations
## and verify behavior.
class_name TestDouble
extends RefCounted

# ── Private Variables ─────────────────────────────────────
var _stubs: Dictionary = {}
var _call_log: Dictionary = {}


# ── Public Methods ────────────────────────────────────────

## Stubs a method to return the specified value when called via call_stub().
func stub_method(method_name: String, return_value: Variant) -> void:
	_stubs[method_name] = return_value


## Calls a stubbed method and records the invocation. Returns the stubbed value
## or null if the method was not stubbed.
func call_stub(method_name: String, args: Array = []) -> Variant:
	if not _call_log.has(method_name):
		_call_log[method_name] = []
	_call_log[method_name].append(args)
	if _stubs.has(method_name):
		return _stubs[method_name]
	return null


## Returns true if the named method was called at least once via call_stub().
func was_called(method_name: String) -> bool:
	if not _call_log.has(method_name):
		return false
	return _call_log[method_name].size() > 0


## Returns the number of times the named method was called via call_stub().
func get_call_count(method_name: String) -> int:
	if not _call_log.has(method_name):
		return 0
	return _call_log[method_name].size()


## Returns the arguments from the Nth call of the named method (0-indexed).
func get_call_args(method_name: String, index: int = 0) -> Array:
	if not _call_log.has(method_name):
		return []
	var calls: Array = _call_log[method_name]
	if index < 0 or index >= calls.size():
		return []
	return calls[index]


## Clears all stubs and call records.
func reset() -> void:
	_stubs.clear()
	_call_log.clear()
