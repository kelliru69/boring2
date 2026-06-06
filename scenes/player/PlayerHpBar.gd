## Barra de HP flotante: compacta, centrada bajo los pies del jugador.
extends ProgressBar

@export var gap_below_feet: float = 4.0
@export var show_hp_text: bool = false

var _player: Node2D = null
var _hp_label: Label = null
var _shield_bar: ProgressBar = null


func _ready() -> void:
	show_percentage = false
	custom_minimum_size = Vector2(44.0, 7.0)
	_apply_bar_styles()
	_ensure_shield_bar()
	if show_hp_text:
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
	if _player and _player.has_signal("shield_changed"):
		if not _player.shield_changed.is_connected(_on_shield_changed):
			_player.shield_changed.connect(_on_shield_changed)
		if _player.get("_energy_coat_shield") != null and _player.get("_energy_coat_shield_max") != null:
			_on_shield_changed(int(_player.get("_energy_coat_shield")), int(_player.get("_energy_coat_shield_max")))


func _apply_bar_styles() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.12, 0.13, 0.16, 0.92)
	bg.set_corner_radius_all(1)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.32, 0.82, 0.42, 1.0)
	fill.set_corner_radius_all(1)
	add_theme_stylebox_override("background", bg)
	add_theme_stylebox_override("fill", fill)


func _ensure_shield_bar() -> void:
	if _shield_bar != null:
		return
	_shield_bar = ProgressBar.new()
	_shield_bar.show_percentage = false
	_shield_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shield_bar.custom_minimum_size = Vector2(custom_minimum_size.x, 4.0)
	_shield_bar.max_value = 1.0
	_shield_bar.value = 0.0
	_shield_bar.position = Vector2(0.0, -5.0)
	_shield_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.14, 0.22, 0.9)
	bg.set_corner_radius_all(1)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.28, 0.72, 1.0, 1.0)
	fill.set_corner_radius_all(1)
	_shield_bar.add_theme_stylebox_override("background", bg)
	_shield_bar.add_theme_stylebox_override("fill", fill)
	add_child(_shield_bar)


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
	_hp_label.add_theme_font_size_override("font_size", 7)
	add_child(_hp_label)


func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var anchor: Vector2 = Vector2.ZERO
	if _player.has_method("get_hp_bar_anchor_offset"):
		anchor = _player.call("get_hp_bar_anchor_offset") as Vector2
	var bar_size: Vector2 = size
	if bar_size.x < 1.0:
		bar_size = custom_minimum_size
	global_position = _player.global_position + Vector2(-bar_size.x * 0.5, anchor.y + gap_below_feet)


func _on_health_changed(current_hp: int, max_hp: int) -> void:
	var max_f: float = maxf(float(max_hp), 1.0)
	max_value = max_f
	value = clampf(float(current_hp), 0.0, max_f)
	if _hp_label:
		_hp_label.text = "%d / %d" % [current_hp, max_hp]


func _on_shield_changed(current_shield: int, max_shield: int) -> void:
	if _shield_bar == null:
		return
	var max_f: float = maxf(float(max_shield), 1.0)
	_shield_bar.max_value = max_f
	_shield_bar.value = clampf(float(current_shield), 0.0, max_f)
	_shield_bar.visible = max_shield > 0
