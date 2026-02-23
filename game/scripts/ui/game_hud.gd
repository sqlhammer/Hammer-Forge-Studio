## Main HUD controller: aggregates all HUD elements on a CanvasLayer.
class_name GameHUD
extends CanvasLayer

# ── Private Variables ─────────────────────────────────────
var _compass_bar: CompassBar = null
var _battery_bar: BatteryBar = null
var _scanner_readout: ScannerReadout = null
var _mining_progress: MiningProgress = null
var _pickup_notifications: PickupNotificationManager = null
var _crosshair: Control = null
var _scanner: Scanner = null

# ── Public Methods ────────────────────────────────────────

## Initializes the HUD with references to gameplay systems.
func setup(camera: Camera3D, player: CharacterBody3D, scanner: Scanner, mining: Mining) -> void:
	_compass_bar.setup(camera, player)
	_scanner_readout.setup(player)
	_scanner = scanner

	# Connect scanner signals
	scanner.ping_completed.connect(_on_ping_completed)
	scanner.analysis_completed.connect(_on_analysis_completed)
	scanner.analysis_started.connect(_on_analysis_started)
	scanner.analysis_cancelled.connect(_on_analysis_cancelled)
	scanner.analysis_progress_changed.connect(_on_analysis_progress)

	# Connect mining signals
	mining.mining_started.connect(_on_mining_started)
	mining.mining_progress_changed.connect(_on_mining_progress)
	mining.mining_completed.connect(_on_mining_completed)
	mining.mining_cancelled.connect(_on_mining_cancelled)
	mining.mining_failed.connect(_on_mining_failed)

## Returns the compass bar for external access.
func get_compass_bar() -> CompassBar:
	return _compass_bar

## Returns the scanner readout for external access.
func get_scanner_readout() -> ScannerReadout:
	return _scanner_readout

# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	layer = 1
	_build_hud()

func _process(_delta: float) -> void:
	# Show readout for already-analyzed deposits when aimed at
	if _scanner:
		var aimed: Deposit = _scanner.get_aimed_deposit()
		if aimed and aimed.is_analyzed() and not aimed.is_depleted():
			if _scanner_readout.get_current_deposit() != aimed:
				_scanner_readout.show_readout(aimed)

# ── Private Methods ───────────────────────────────────────

func _build_hud() -> void:
	# Root control that fills the screen
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# Compass bar — top center
	_compass_bar = CompassBar.new()
	_compass_bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_compass_bar.position = Vector2(-CompassBar.COMPASS_WIDTH / 2.0, 32)
	root.add_child(_compass_bar)

	# Crosshair — center dot
	_crosshair = _create_crosshair()
	_crosshair.set_anchors_preset(Control.PRESET_CENTER)
	_crosshair.position = Vector2(-2, -2)
	root.add_child(_crosshair)

	# Mining progress — center, below crosshair
	_mining_progress = MiningProgress.new()
	_mining_progress.set_anchors_preset(Control.PRESET_CENTER)
	_mining_progress.position = Vector2(-MiningProgress.BAR_WIDTH / 2.0, 60)
	root.add_child(_mining_progress)

	# Scanner readout — center-right
	_scanner_readout = ScannerReadout.new()
	_scanner_readout.anchor_left = 1.0
	_scanner_readout.anchor_right = 1.0
	_scanner_readout.anchor_top = 0.5
	_scanner_readout.anchor_bottom = 0.5
	_scanner_readout.position = Vector2(-ScannerReadout.READOUT_WIDTH - 80, -160)
	root.add_child(_scanner_readout)

	# Battery bar — bottom-left
	_battery_bar = BatteryBar.new()
	_battery_bar.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_battery_bar.position = Vector2(32, -BatteryBar.TOTAL_HEIGHT - 32)
	root.add_child(_battery_bar)

	# Pickup notifications — center-right, stacking
	_pickup_notifications = PickupNotificationManager.new()
	_pickup_notifications.anchor_left = 1.0
	_pickup_notifications.anchor_right = 1.0
	_pickup_notifications.anchor_top = 0.5
	_pickup_notifications.anchor_bottom = 0.5
	_pickup_notifications.position = Vector2(-PickupNotificationManager.TOAST_WIDTH - 32, 0)
	root.add_child(_pickup_notifications)

func _create_crosshair() -> Control:
	var dot := ColorRect.new()
	dot.custom_minimum_size = Vector2(4, 4)
	dot.color = Color("#F1F5F9", 0.6)
	return dot

# ── Signal Handlers ───────────────────────────────────────

func _on_ping_completed(deposits: Array[Deposit]) -> void:
	_compass_bar.add_ping_markers(deposits)

func _on_analysis_started(_deposit: Deposit) -> void:
	_mining_progress.show_progress("SCANNING", Color("#00D4AA"))

func _on_analysis_progress(progress: float) -> void:
	_mining_progress.update_progress(progress)

func _on_analysis_completed(deposit: Deposit) -> void:
	_mining_progress.show_complete()
	_scanner_readout.show_readout(deposit)

func _on_analysis_cancelled() -> void:
	_mining_progress.hide_progress()

func _on_mining_started(_deposit: Deposit) -> void:
	_mining_progress.show_progress()

func _on_mining_progress(progress: float) -> void:
	_mining_progress.update_progress(progress)

func _on_mining_completed(_deposit: Deposit, _resource_type: ResourceDefs.ResourceType, _purity: ResourceDefs.Purity, _quantity: int) -> void:
	_mining_progress.show_complete()

func _on_mining_cancelled() -> void:
	_mining_progress.hide_progress()

func _on_mining_failed(reason: String) -> void:
	_mining_progress.show_failed(reason)
