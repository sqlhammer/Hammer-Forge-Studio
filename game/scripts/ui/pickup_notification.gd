## Pickup notification toast manager: shows item collection popups that stack and aggregate.
class_name PickupNotificationManager
extends VBoxContainer

# ── Constants ─────────────────────────────────────────────
const TOAST_WIDTH: float = 260.0
const TOAST_HEIGHT: float = 48.0
const MAX_VISIBLE: int = 3
const TOAST_DURATION: float = 3.0
const AGGREGATION_WINDOW: float = 1.0
const SLIDE_OFFSET: float = 24.0
const APPEAR_DURATION: float = 0.15
const DISMISS_DURATION: float = 0.3
const STACK_GAP: int = 8

## Style colors matching UI style guide
const COLOR_BG := Color("#0F1923", 0.85)
const COLOR_GREEN := Color("#4ADE80")
const COLOR_CORAL := Color("#FF6B5A")
const COLOR_AMBER := Color("#FFB830")
const COLOR_TEXT_PRIMARY := Color("#F1F5F9")

# ── Private Variables ─────────────────────────────────────
## Active toasts keyed by resource_type+purity for aggregation
var _active_toasts: Dictionary = {}
var _font: Font = null

# ── Built-in Virtual Methods ──────────────────────────────

func _ready() -> void:
	_font = ThemeDB.fallback_font
	add_theme_constant_override("separation", STACK_GAP)
	PlayerInventory.item_added.connect(_on_item_added)
	PlayerInventory.inventory_full.connect(_on_inventory_full)

# ── Public Methods ────────────────────────────────────────

## Shows a pickup notification for a collected item.
func show_pickup(resource_type: ResourceDefs.ResourceType, purity: ResourceDefs.Purity, quantity: int) -> void:
	var key: String = "%d_%d" % [resource_type, purity]

	# Check for existing toast to aggregate
	if _active_toasts.has(key):
		var toast_data: Dictionary = _active_toasts[key]
		var toast_node: PanelContainer = toast_data.get("node") as PanelContainer
		if is_instance_valid(toast_node):
			var qty_label: Label = toast_data.get("qty_label") as Label
			var total: int = (toast_data.get("total", 0) as int) + quantity
			toast_data["total"] = total
			qty_label.text = "x%d" % total
			# Pulse animation on quantity
			var tween: Tween = create_tween()
			tween.tween_property(qty_label, "scale", Vector2(1.1, 1.1), 0.05)
			tween.tween_property(qty_label, "scale", Vector2.ONE, 0.05)
			# Reset dismiss timer
			toast_data["timer"] = TOAST_DURATION
			return

	# Evict oldest if at max
	if get_child_count() >= MAX_VISIBLE:
		_dismiss_oldest()

	# Create new toast
	_create_toast(key, resource_type, purity, quantity, COLOR_GREEN)

## Shows a generic text notification with a given accent color.
func show_message(text: String, accent_color: Color = COLOR_GREEN) -> void:
	if get_child_count() >= MAX_VISIBLE:
		_dismiss_oldest()
	var toast := _create_raw_toast(text, "", accent_color)
	add_child(toast)
	_animate_appear(toast)
	var tween: Tween = create_tween()
	tween.tween_interval(TOAST_DURATION)
	tween.tween_callback(func() -> void: _dismiss_toast(toast))

## Shows an "inventory full" notification.
func show_inventory_full() -> void:
	var toast := _create_raw_toast("Inventory Full", "", COLOR_CORAL)
	add_child(toast)
	_animate_appear(toast)
	# Auto-dismiss
	var tween: Tween = create_tween()
	tween.tween_interval(TOAST_DURATION)
	tween.tween_callback(func() -> void: _dismiss_toast(toast))

# ── Private Methods ───────────────────────────────────────

func _create_toast(key: String, resource_type: ResourceDefs.ResourceType, purity: ResourceDefs.Purity, quantity: int, accent_color: Color) -> void:
	var toast := PanelContainer.new()
	toast.custom_minimum_size = Vector2(TOAST_WIDTH, TOAST_HEIGHT)

	# Panel style
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_BG
	style.border_color = accent_color
	style.border_width_left = 3
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	toast.add_theme_stylebox_override("panel", style)

	# Content layout
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	toast.add_child(hbox)

	# Item icon
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(28, 28)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var item_icon_path: String = ResourceDefs.get_icon_path(resource_type)
	if not item_icon_path.is_empty():
		icon.texture = load(item_icon_path) as Texture2D
	hbox.add_child(icon)

	# Item name
	var name_label := Label.new()
	name_label.text = ResourceDefs.get_resource_name(resource_type)
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_label)

	# Quantity label
	var qty_label := Label.new()
	qty_label.text = "x%d" % quantity
	qty_label.add_theme_font_size_override("font_size", 18)
	qty_label.add_theme_color_override("font_color", accent_color)
	qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(qty_label)

	add_child(toast)
	_animate_appear(toast)

	# Store in active toasts for aggregation
	_active_toasts[key] = {
		"node": toast,
		"qty_label": qty_label,
		"total": quantity,
		"timer": TOAST_DURATION,
	}

	# Start dismiss timer
	_start_dismiss_timer(key, toast)

func _create_raw_toast(text: String, quantity_text: String, accent_color: Color) -> PanelContainer:
	var toast := PanelContainer.new()
	toast.custom_minimum_size = Vector2(TOAST_WIDTH, TOAST_HEIGHT)

	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_BG
	style.border_color = accent_color
	style.border_width_left = 3
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	toast.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	toast.add_child(hbox)

	# Severity badge icon — differentiates notification type for color-blind safety
	var badge_icon := TextureRect.new()
	badge_icon.custom_minimum_size = Vector2(20, 20)
	badge_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	badge_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var badge_path: String = _get_severity_icon_path(accent_color)
	if not badge_path.is_empty():
		badge_icon.texture = load(badge_path) as Texture2D
	badge_icon.modulate = accent_color
	hbox.add_child(badge_icon)

	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", accent_color)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(label)

	return toast

func _get_severity_icon_path(accent_color: Color) -> String:
	if accent_color == COLOR_CORAL:
		return "res://assets/icons/hud/icon_hud_notification_critical.svg"
	elif accent_color == COLOR_AMBER:
		return "res://assets/icons/hud/icon_hud_notification_warning.svg"
	return "res://assets/icons/hud/icon_hud_notification_info.svg"

func _start_dismiss_timer(key: String, toast: PanelContainer) -> void:
	var tween: Tween = create_tween()
	tween.tween_interval(TOAST_DURATION)
	tween.tween_callback(func() -> void:
		_active_toasts.erase(key)
		_dismiss_toast(toast)
	)

func _dismiss_oldest() -> void:
	if get_child_count() > 0:
		var oldest: Control = get_child(0) as Control
		# Remove from active toasts
		for key: String in _active_toasts:
			if _active_toasts[key].get("node") == oldest:
				_active_toasts.erase(key)
				break
		_dismiss_toast(oldest)

func _dismiss_toast(toast: Control) -> void:
	if not is_instance_valid(toast):
		return
	var tween: Tween = create_tween()
	tween.tween_property(toast, "modulate:a", 0.0, DISMISS_DURATION * 0.5)
	tween.tween_callback(func() -> void:
		if is_instance_valid(toast):
			toast.queue_free()
	)

func _animate_appear(toast: Control) -> void:
	toast.modulate.a = 0.0
	toast.position.x += SLIDE_OFFSET
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(toast, "modulate:a", 1.0, APPEAR_DURATION)
	tween.tween_property(toast, "position:x", toast.position.x - SLIDE_OFFSET, APPEAR_DURATION)

func _on_item_added(resource_type: ResourceDefs.ResourceType, purity: ResourceDefs.Purity, quantity: int) -> void:
	show_pickup(resource_type, purity, quantity)

func _on_inventory_full() -> void:
	show_inventory_full()
