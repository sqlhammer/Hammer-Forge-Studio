## Structured logging system that writes JSONL files for consumption by AI agents.
## Each log entry contains trace context, module info, agent-actionable advice, and tags.
## This system is separate from Global.log() — it produces machine-readable output
## while Global.log() produces human-readable console output.
extends Node

# ── Constants ─────────────────────────────────────────────
const LOG_DIRECTORY: String = "user://logs/"
const MAX_BUFFER_SIZE: int = 50
const FLUSH_INTERVAL_SECONDS: float = 10.0
const MAX_SESSION_FILES: int = 10
const LOG_FILE_PREFIX: String = "agent_log_"
const LOG_FILE_EXTENSION: String = ".jsonl"

enum LogLevel { DEBUG, INFO, WARNING, ERROR, FATAL, LOGIC_ERROR }

# ── Signals ──────────────────────────────────────────────
signal log_flushed(entry_count: int)

# ── Private Variables ─────────────────────────────────────
var _session_id: String = ""
var _buffer: Array[Dictionary] = []
var _flush_timer: float = 0.0
var _current_log_path: String = ""
var _minimum_level: LogLevel = LogLevel.DEBUG
var _is_enabled: bool = true
var _entry_counter: int = 0

# ── Built-in Virtual Methods ──────────────────────────────
func _ready() -> void:
	_session_id = _generate_uuid_v4()
	_ensure_log_directory()
	_current_log_path = _create_session_log_path()
	_rotate_old_sessions()
	Global.log("AgentLogger initialized — session: %s" % _session_id)
	var resolved_path: String = ProjectSettings.globalize_path(_current_log_path)
	Global.log("AgentLogger writing to: %s" % resolved_path)


func _process(delta: float) -> void:
	if not _is_enabled:
		return
	_flush_timer += delta
	if _flush_timer >= FLUSH_INTERVAL_SECONDS and _buffer.size() > 0:
		flush()
		_flush_timer = 0.0


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if _buffer.size() > 0:
			flush()


# ── Public Methods ────────────────────────────────────────

## Core logging method. Writes a structured log entry to the buffer.
func log_entry(
	level: LogLevel,
	module: String,
	function_name: String,
	message: String,
	context: Dictionary = {},
	agent_advice: String = "",
	tags: Array[String] = []
) -> void:
	if not _is_enabled:
		return
	if level < _minimum_level:
		return

	var entry: Dictionary = {
		"trace_id": _generate_uuid_v4(),
		"timestamp": _get_iso_timestamp(),
		"session_id": _session_id,
		"level": _level_to_string(level),
		"module": module,
		"function": function_name,
		"message": message,
		"context": _serialize_context(context),
		"agent_advice": agent_advice,
		"tags": tags,
		"stack_trace": _get_caller_location()
	}
	_buffer.append(entry)
	_entry_counter += 1

	if _buffer.size() >= MAX_BUFFER_SIZE:
		flush()


## Convenience method for ERROR level logging.
func log_error(
	module: String,
	function_name: String,
	message: String,
	context: Dictionary = {},
	advice: String = ""
) -> void:
	log_entry(LogLevel.ERROR, module, function_name, message, context, advice, [])


## Convenience method for WARNING level logging.
func log_warning(
	module: String,
	function_name: String,
	message: String,
	context: Dictionary = {},
	advice: String = ""
) -> void:
	log_entry(LogLevel.WARNING, module, function_name, message, context, advice, [])


## Convenience method for LOGIC_ERROR level logging (semantic bugs that do not crash).
func log_logic_error(
	module: String,
	function_name: String,
	message: String,
	context: Dictionary = {},
	advice: String = ""
) -> void:
	log_entry(LogLevel.LOGIC_ERROR, module, function_name, message, context, advice,
		["logic-error"])


## Bridge method for the test framework. Logs a test result as a structured entry.
func log_test_result(
	suite_name: String,
	test_name: String,
	passed: bool,
	details: String = ""
) -> void:
	var level: LogLevel = LogLevel.INFO if passed else LogLevel.ERROR
	var status_text: String = "PASSED" if passed else "FAILED"
	var context: Dictionary = {
		"suite": suite_name,
		"test": test_name,
		"passed": passed
	}
	var advice: String = ""
	if not passed:
		advice = "Test '%s' in suite '%s' failed. Review test logic and the system under test. Details: %s" % [
			test_name, suite_name, details]
	log_entry(level, "TestRunner", "run_test",
		"%s: %s.%s" % [status_text, suite_name, test_name],
		context, advice, ["test", "automated"])


## Returns the current session identifier.
func get_session_id() -> String:
	return _session_id


## Forces an immediate write of all buffered entries to disk.
func flush() -> void:
	if _buffer.size() == 0:
		return
	var file: FileAccess = FileAccess.open(_current_log_path, FileAccess.READ_WRITE)
	if file == null:
		# File may not exist yet — create it
		file = FileAccess.open(_current_log_path, FileAccess.WRITE)
	if file == null:
		push_error("AgentLogger: Failed to open log file '%s'" % _current_log_path)
		return
	# Seek to end for appending
	file.seek_end()
	var entries_written: int = _buffer.size()
	for entry: Dictionary in _buffer:
		var json_line: String = JSON.stringify(entry)
		file.store_line(json_line)
	file.close()
	_buffer.clear()
	_flush_timer = 0.0
	log_flushed.emit(entries_written)


## Sets the minimum log level. Entries below this level are silently discarded.
func set_minimum_level(level: LogLevel) -> void:
	_minimum_level = level


## Enables or disables the logger entirely. When disabled, all log_entry calls are no-ops.
func set_enabled(enabled: bool) -> void:
	_is_enabled = enabled


## Returns the total number of entries logged this session (including those already flushed).
func get_entry_count() -> int:
	return _entry_counter


# ── Private Methods ───────────────────────────────────────

func _ensure_log_directory() -> void:
	var global_path: String = ProjectSettings.globalize_path(LOG_DIRECTORY)
	DirAccess.make_dir_recursive_absolute(global_path)


func _create_session_log_path() -> String:
	var date_string: String = Time.get_date_string_from_system(true)
	var time_string: String = Time.get_time_string_from_system(true).replace(":", "-")
	var file_name: String = "%s%s_%s%s" % [
		LOG_FILE_PREFIX, date_string, time_string, LOG_FILE_EXTENSION]
	return LOG_DIRECTORY + file_name


func _rotate_old_sessions() -> void:
	var global_path: String = ProjectSettings.globalize_path(LOG_DIRECTORY)
	var directory: DirAccess = DirAccess.open(global_path)
	if directory == null:
		return
	var log_files: Array[String] = []
	directory.list_dir_begin()
	var file_name: String = directory.get_next()
	while file_name != "":
		if file_name.begins_with(LOG_FILE_PREFIX) and file_name.ends_with(LOG_FILE_EXTENSION):
			log_files.append(file_name)
		file_name = directory.get_next()
	directory.list_dir_end()
	# Sort oldest first (date prefix ensures lexicographic = chronological)
	log_files.sort()
	# Remove oldest files if we exceed the maximum
	while log_files.size() >= MAX_SESSION_FILES:
		var oldest_file: String = log_files[0]
		directory.remove(oldest_file)
		Global.log("AgentLogger: Rotated old log '%s'" % oldest_file)
		log_files.remove_at(0)


func _generate_uuid_v4() -> String:
	var hex_chars: String = "0123456789abcdef"
	var uuid: String = ""
	for i: int in range(32):
		var byte_value: int = randi() % 16
		# Set version (4) at position 12
		if i == 12:
			byte_value = 4
		# Set variant bits (8, 9, a, or b) at position 16
		elif i == 16:
			byte_value = (randi() % 4) + 8
		uuid += hex_chars[byte_value]
		# Insert dashes at positions 8, 12, 16, 20
		if i == 7 or i == 11 or i == 15 or i == 19:
			uuid += "-"
	return uuid


func _get_iso_timestamp() -> String:
	var datetime: Dictionary = Time.get_datetime_dict_from_system(true)
	return "%04d-%02d-%02dT%02d:%02d:%02dZ" % [
		datetime["year"], datetime["month"], datetime["day"],
		datetime["hour"], datetime["minute"], datetime["second"]]


func _level_to_string(level: LogLevel) -> String:
	match level:
		LogLevel.DEBUG:
			return "DEBUG"
		LogLevel.INFO:
			return "INFO"
		LogLevel.WARNING:
			return "WARNING"
		LogLevel.ERROR:
			return "ERROR"
		LogLevel.FATAL:
			return "FATAL"
		LogLevel.LOGIC_ERROR:
			return "LOGIC_ERROR"
	return "UNKNOWN"


func _serialize_context(context: Dictionary) -> Dictionary:
	var serialized: Dictionary = {}
	for key: String in context.keys():
		var value: Variant = context[key]
		if value is bool:
			serialized[key] = value
		elif value is int or value is float:
			serialized[key] = value
		elif value is String:
			serialized[key] = value
		elif value is Dictionary:
			serialized[key] = _serialize_context(value)
		else:
			# Vector2, Vector3, Transform3D, etc. — convert to string
			serialized[key] = str(value)
	return serialized


func _get_caller_location() -> String:
	var stack: Array[Dictionary] = get_stack()
	# Walk past AgentLogger's own methods to find the actual caller
	# [0]=_get_caller_location, [1]=log_entry, [2]=convenience method or caller, [3]=caller
	if stack.size() >= 4:
		var caller: Dictionary = stack[3]
		return "%s:%s" % [caller.get("source", ""), caller.get("line", "")]
	elif stack.size() >= 3:
		var caller: Dictionary = stack[2]
		return "%s:%s" % [caller.get("source", ""), caller.get("line", "")]
	return ""
