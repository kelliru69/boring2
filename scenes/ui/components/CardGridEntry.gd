## Celda del álbum: miniatura o silueta bloqueada.
extends PanelContainer

signal card_clicked(card_id: String)

const _Theme = preload("res://scripts/ui/modern_ui_theme.gd")
const _Visuals = preload("res://data/card_visual_catalog.gd")

var _card_id: String = ""
var _discovered: bool = false
var _hovered: bool = false
var _selected: bool = false

@onready var _thumb: TextureRect = $Margin/VBox/ThumbFrame/Thumb
@onready var _lock: Label = $Margin/VBox/ThumbFrame/LockOverlay
@onready var _count_badge: Label = $Margin/VBox/ThumbFrame/CountBadge
@onready var _name_label: Label = $Margin/VBox/NameLabel


func _ready() -> void:
	add_theme_stylebox_override(&"panel", _Theme.make_card_style(false))
	custom_minimum_size = Vector2(108, 148)
	_Theme.style_subtitle(_name_label, 11)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_Theme.pass_clicks_to_root(self)
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_hover_enter)
	mouse_exited.connect(_on_hover_exit)


func setup(card_id: String, display_name: String, discovered: bool, owned_count: int = 0) -> void:
	_card_id = card_id
	_discovered = discovered
	_name_label.text = display_name if discovered else "???"
	if _count_badge:
		_count_badge.visible = discovered and owned_count > 1
		_count_badge.text = "x%d" % owned_count if owned_count > 1 else ""
	if discovered:
		var tex: Texture2D = _Visuals.load_texture(card_id)
		if tex:
			_thumb.texture = tex
			_thumb.modulate = Color.WHITE
		else:
			_thumb.texture = null
			_thumb.modulate = Color(0.35, 0.55, 0.85, 0.35)
		_lock.visible = false
	else:
		_thumb.texture = null
		_thumb.modulate = Color(0.05, 0.06, 0.09, 1.0)
		_lock.visible = true


func set_selected(selected: bool) -> void:
	_selected = selected
	add_theme_stylebox_override(&"panel", _Theme.make_card_style(false, selected))


func get_card_id() -> String:
	return _card_id


func _on_gui_input(event: InputEvent) -> void:
	if not _discovered or _card_id.is_empty():
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		card_clicked.emit(_card_id)


func _on_hover_enter() -> void:
	_hovered = true
	add_theme_stylebox_override(&"panel", _Theme.make_card_style(true, _selected))


func _on_hover_exit() -> void:
	_hovered = false
	add_theme_stylebox_override(&"panel", _Theme.make_card_style(false, _selected))
