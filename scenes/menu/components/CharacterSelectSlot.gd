## Cuadro de la cuadrícula arcade para un personaje (desbloqueado o bloqueado).
class_name CharacterSelectSlot
extends Button

const _Theme = preload("res://scripts/ui/modern_ui_theme.gd")

signal slot_focused(character_data: CharacterData)
signal slot_hovered(character_data: CharacterData)

var character_data: CharacterData = null
var is_locked: bool = false
var _selected: bool = false

@onready var _icon_frame: PanelContainer = $Margin/VBox/IconFrame
@onready var _portrait: TextureRect = $Margin/VBox/IconFrame/Portrait
@onready var _name_label: Label = $Margin/VBox/NameLabel
@onready var _locked_overlay: ColorRect = $LockedOverlay


func _ready() -> void:
	toggle_mode = false
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_ignore_child_mouse_filters()
	_apply_frame_style(false)


func _ignore_child_mouse_filters() -> void:
	for child: Node in get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignore_descendant_mouse_filters(child)


func _ignore_descendant_mouse_filters(node: Node) -> void:
	for child: Node in node.get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignore_descendant_mouse_filters(child)


func setup(data: CharacterData) -> void:
	is_locked = false
	character_data = data
	disabled = false
	focus_mode = Control.FOCUS_ALL
	_locked_overlay.visible = false
	_icon_frame.visible = true
	_name_label.visible = true
	if character_data == null:
		return
	_name_label.text = character_data.character_name
	_portrait.texture = character_data.icon_thumbnail
	tooltip_text = character_data.character_name
	modulate = Color.WHITE


func setup_locked() -> void:
	is_locked = true
	character_data = null
	disabled = true
	focus_mode = Control.FOCUS_NONE
	tooltip_text = ""
	_locked_overlay.visible = true
	_icon_frame.visible = false
	_name_label.visible = false
	modulate = Color.WHITE
	_apply_frame_style(false)


func _on_mouse_entered() -> void:
	if character_data != null and not is_locked:
		slot_hovered.emit(character_data)
		if not _selected:
			_apply_frame_style(true)


func _on_mouse_exited() -> void:
	if not _selected:
		_apply_frame_style(false)


func _on_pressed() -> void:
	if character_data != null and not is_locked:
		slot_focused.emit(character_data)


func set_highlighted(active: bool) -> void:
	if is_locked:
		return
	_selected = active
	scale = Vector2.ONE * (1.06 if active else 1.0)
	_apply_frame_style(active)


func set_hover_preview(active: bool) -> void:
	if is_locked or _selected:
		return
	scale = Vector2.ONE * (1.03 if active else 1.0)
	_apply_frame_style(active)


func _apply_frame_style(selected: bool) -> void:
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color(0.06, 0.08, 0.12, 0.85)
	frame.set_corner_radius_all(48)
	frame.set_border_width_all(3 if selected else 1)
	frame.border_color = _Theme.ACCENT if selected else Color(0.25, 0.28, 0.35, 0.9)
	if selected:
		frame.shadow_size = 10
		frame.shadow_color = Color(_Theme.ACCENT.r, _Theme.ACCENT.g, _Theme.ACCENT.b, 0.35)
	_icon_frame.add_theme_stylebox_override(&"panel", frame)
