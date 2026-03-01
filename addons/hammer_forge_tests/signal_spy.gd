## Records signal emissions for assertion in unit tests. Connect a signal to
## the spy via watch(), then assert that it was emitted with the expected arguments.
class_name SignalSpy
extends RefCounted

# ── Private Variables ─────────────────────────────────────
var _emissions: Dictionary = {}


# ── Public Methods ────────────────────────────────────────

## Watches a signal on the given object. Connects the signal to the spy's recorder.
func watch(source: Object, signal_name: String) -> void:
	if not _emissions.has(signal_name):
		_emissions[signal_name] = []
	var recorder: Callable = _make_recorder(signal_name)
	source.connect(signal_name, recorder)


## Returns true if the named signal was emitted at least once.
func was_emitted(signal_name: String) -> bool:
	if not _emissions.has(signal_name):
		return false
	return _emissions[signal_name].size() > 0


## Returns the number of times the named signal was emitted.
func get_emission_count(signal_name: String) -> int:
	if not _emissions.has(signal_name):
		return 0
	return _emissions[signal_name].size()


## Returns the arguments from the Nth emission of the named signal (0-indexed).
func get_emission_args(signal_name: String, index: int = 0) -> Array:
	if not _emissions.has(signal_name):
		return []
	var emissions_list: Array = _emissions[signal_name]
	if index < 0 or index >= emissions_list.size():
		return []
	return emissions_list[index]


## Clears all recorded emissions.
func clear() -> void:
	_emissions.clear()


# ── Private Methods ───────────────────────────────────────

func _make_recorder(signal_name: String) -> Callable:
	# Supports up to 4 signal parameters — covers all signals in the current codebase
	return func(arg1: Variant = null, arg2: Variant = null,
				arg3: Variant = null, arg4: Variant = null) -> void:
		var args: Array = []
		for arg: Variant in [arg1, arg2, arg3, arg4]:
			if arg != null:
				args.append(arg)
		if not _emissions.has(signal_name):
			_emissions[signal_name] = []
		_emissions[signal_name].append(args)
