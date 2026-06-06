## Overlay estilo fighting game: nombre de clase + barra de HP (esquina superior izquierda).
class_name FighterHealthHud
extends Control

const _Theme = preload("res://scripts/ui/modern_ui_theme.gd")
const _Fusion = preload("res://data/job_fusion_catalog.gd")
const _ClassCatalog = preload("res://data/class_select_catalog.gd")

@onready var _name_label: Label = $Margin/VBox/NameLabel
@onready var _hp_bar: ProgressBar = $Margin/VBox/HpBar
@onready var _hp_text: Label = $Margin/VBox/HpText


func _ready() -> void:
	anchors_preset = Control.PRESET_TOP_LEFT
	offset_left = 14.0
	offset_top = 12.0
	offset_right = 280.0
	offset_bottom = 92.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _name_label:
		_name_label.add_theme_color_override(&"font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
		_name_label.add_theme_constant_override(&"outline_size", 4)
		_Theme.style_title(_name_label, 18)
	if _hp_text:
		_hp_text.add_theme_color_override(&"font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
		_hp_text.add_theme_constant_override(&"outline_size", 3)
	if _hp_bar:
		_hp_bar.show_percentage = false
		_hp_bar.max_value = 100.0


func bind_player(player: Player) -> void:
	if player == null:
		return
	if not player.health_changed.is_connected(_on_health_changed):
		player.health_changed.connect(_on_health_changed)
	_on_health_changed(player.current_hp, player.max_hp)
	_set_fighter_name(Global.current_class if not Global.current_class.is_empty() else Game.selected_class_id)


func set_fighter_name(class_id: String) -> void:
	_set_fighter_name(class_id)


func _set_fighter_name(class_id: String) -> void:
	if _name_label == null:
		return
	var display: String = _Fusion.get_job_display_name(class_id)
	var class_data: ClassData = _ClassCatalog.get_class_by_id(class_id)
	if class_data != null:
		display = class_data.display_name
	_name_label.text = display


func _on_health_changed(current_hp: int, max_hp: int) -> void:
	var maxv: int = maxi(max_hp, 1)
	if _hp_bar:
		_hp_bar.max_value = float(maxv)
		_hp_bar.value = float(clampi(current_hp, 0, maxv))
		var ratio: float = float(current_hp) / float(maxv)
		if ratio > 0.55:
			_hp_bar.modulate = Color(0.35, 0.95, 0.45, 1.0)
		elif ratio > 0.28:
			_hp_bar.modulate = Color(0.95, 0.82, 0.25, 1.0)
		else:
			_hp_bar.modulate = Color(0.95, 0.28, 0.22, 1.0)
	if _hp_text:
		_hp_text.text = "%d / %d" % [current_hp, max_hp]
