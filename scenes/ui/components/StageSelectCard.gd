## Tarjeta de selección de mapa / etapa.
extends PanelContainer

signal stage_selected(map_id: String)

const _Theme = preload("res://scripts/ui/modern_ui_theme.gd")

var _map_id: String = ""
var _selected: bool = false

@onready var _preview: PanelContainer = $Margin/VBox/Preview
@onready var _bg: ColorRect = $Margin/VBox/Preview/BgTint
@onready var _name: Label = $Margin/VBox/NameLabel
@onready var _difficulty: Label = $Margin/VBox/DifficultyLabel
@onready var _desc: Label = $Margin/VBox/DescLabel


func _ready() -> void:
	add_theme_stylebox_override(&"panel", _Theme.make_card_style())
	if _preview:
		_preview.add_theme_stylebox_override(&"panel", _Theme.make_panel_style(_Theme.CARD_FILL, _Theme.PANEL_BORDER, 8, false))
	_Theme.style_title(_name, 17)
	_Theme.style_accent(_difficulty, 12)
	_Theme.style_subtitle(_desc, 11)
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_hover_enter)
	mouse_exited.connect(_on_hover_exit)


func setup(map_id: String, display_name: String, difficulty_text: String, desc: String, tint: Color) -> void:
	_map_id = map_id
	_name.text = display_name
	_difficulty.text = difficulty_text
	_desc.text = desc
	if _bg:
		_bg.color = tint


func set_selected(selected: bool) -> void:
	_selected = selected
	add_theme_stylebox_override(&"panel", _Theme.make_card_style(false, selected))


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Audio.play_ui_click()
		stage_selected.emit(_map_id)


func _on_hover_enter() -> void:
	if not _selected:
		add_theme_stylebox_override(&"panel", _Theme.make_card_style(true, false))


func _on_hover_exit() -> void:
	add_theme_stylebox_override(&"panel", _Theme.make_card_style(false, _selected))
