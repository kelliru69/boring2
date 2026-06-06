## Icono cuadrado estilo RO: textura + nivel en esquina superior derecha.
class_name RoStatusChip
extends PanelContainer

const _Theme = preload("res://scripts/ui/modern_ui_theme.gd")

@onready var _icon: TextureRect = $Margin/Icon
@onready var _level_badge: Label = $LevelBadge
@onready var _stack_badge: Label = $StackBadge


func _ready() -> void:
	custom_minimum_size = Vector2(40, 40)
	_Theme.apply_panel(self)
	if _level_badge:
		_level_badge.add_theme_font_size_override("font_size", 10)
		_level_badge.add_theme_color_override("font_color", Color(1.0, 0.95, 0.75, 1.0))
	if _stack_badge:
		_stack_badge.add_theme_font_size_override("font_size", 10)
		_stack_badge.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))


func setup(icon: Texture2D, level: int = 0, stack_count: int = 0, tooltip: String = "") -> void:
	if _icon:
		_icon.texture = icon
		_icon.modulate = Color.WHITE if icon else Color(0.4, 0.45, 0.5, 0.6)
	if _level_badge:
		_level_badge.visible = level > 0
		_level_badge.text = str(level) if level > 0 else ""
	if _stack_badge:
		_stack_badge.visible = stack_count > 1
		_stack_badge.text = "x%d" % stack_count if stack_count > 1 else ""
	tooltip_text = tooltip
