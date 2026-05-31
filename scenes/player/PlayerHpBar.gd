## Barra de HP flotante: fondo gris, relleno verde y texto actual/máximo.
extends ProgressBar

@export var vertical_offset: float = 22.0

var _player: Node2D = null
var _hp_label: Label = null


func _ready() -> void:
	show_percentage = false
	custom_minimum_size = Vector2(72.0, 16.0)
	_apply_bar_styles()
	_ensure_hp_label()


func bind_player(player: Node2D) -> void:
	_player = player
	_apply_bar_styles()
	_ensure_hp_label()
	if _player and _player.has_signal("health_changed"):
		if not _player.health_changed.is_connected(_on_health_changed):
			_player.health_changed.connect(_on_health_changed)
		if _player.get("max_hp") != null and _player.get("current_hp") != null:
			_on_health_changed(int(_player.current_hp), int(_player.max_hp))


func _apply_bar_styles() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.16, 0.17, 0.2, 0.95)
	bg.set_corner_radius_all(2)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.28, 0.78, 0.38, 1.0)
	fill.set_corner_radius_all(2)
	add_theme_stylebox_override("background", bg)
	add_theme_stylebox_override("fill", fill)


func _ensure_hp_label() -> void:
	if _hp_label != null:
		return
	_hp_label = Label.new()
	_hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hp_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hp_label.add_theme_color_override("font_color", Color(0.95, 0.98, 0.95))
	_hp_label.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.05))
	_hp_label.add_theme_constant_override("outline_size", 2)
	_hp_label.add_theme_font_size_override("font_size", 10)
	add_child(_hp_label)


func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	global_position = _player.global_position + Vector2(-size.x * 0.5, vertical_offset)


func _on_health_changed(current_hp: int, max_hp: int) -> void:
	var max_f: float = maxf(float(max_hp), 1.0)
	max_value = max_f
	value = clampf(float(current_hp), 0.0, max_f)
	if _hp_label:
		_hp_label.text = "%d / %d" % [current_hp, max_hp]
