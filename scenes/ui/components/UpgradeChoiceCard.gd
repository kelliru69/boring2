## Tarjeta de mejora al subir de nivel — requiere clic en «Elegir».
extends PanelContainer

signal chosen(upgrade_id: String)

const _Theme = preload("res://scripts/ui/modern_ui_theme.gd")
const _SkillDefs = preload("res://data/skill_definitions.gd")

var _upgrade_id: String = ""

@onready var _icon_frame: PanelContainer = $Margin/VBox/TopRow/IconFrame
@onready var _icon: TextureRect = $Margin/VBox/TopRow/IconFrame/Icon
@onready var _title: Label = $Margin/VBox/TitleLabel
@onready var _desc: Label = $Margin/VBox/DescLabel
@onready var _badge: Label = $Margin/VBox/BadgeLabel
@onready var _choose_btn: Button = $Margin/VBox/ChooseButton


func _ready() -> void:
	add_theme_stylebox_override(&"panel", _Theme.make_card_style(false))
	mouse_filter = Control.MOUSE_FILTER_STOP
	_Theme.apply_button(_choose_btn, 34.0)
	_choose_btn.text = "Elegir"
	_choose_btn.pressed.connect(_on_choose_pressed)
	mouse_entered.connect(_on_hover_enter)
	mouse_exited.connect(_on_hover_exit)
	custom_minimum_size = Vector2(200, 168)


func setup(upgrade_id: String, title: String, description: String, level_hint: String = "") -> void:
	_upgrade_id = upgrade_id
	_title.text = title
	_desc.text = description
	_badge.text = level_hint
	_badge.visible = not level_hint.is_empty()
	_choose_btn.disabled = upgrade_id.is_empty()
	_set_icon(null)
	_Theme.style_accent(_title, 16)
	_Theme.style_body(_desc, 12)


func set_skill_icon(skill_id: String) -> void:
	if skill_id.is_empty():
		_set_icon(null)
		return
	_set_icon(_SkillDefs.get_icon_texture(skill_id))


func _set_icon(tex: Texture2D) -> void:
	_icon.texture = tex
	var has_icon: bool = tex != null
	_icon_frame.visible = has_icon


func _on_choose_pressed() -> void:
	if _upgrade_id != "":
		chosen.emit(_upgrade_id)


func _on_hover_enter() -> void:
	add_theme_stylebox_override(&"panel", _Theme.make_card_style(true))
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.03, 1.03), 0.1)


func _on_hover_exit() -> void:
	add_theme_stylebox_override(&"panel", _Theme.make_card_style(false))
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)
