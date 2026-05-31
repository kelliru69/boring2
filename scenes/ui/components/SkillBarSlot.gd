## Slot de la barra de acción (Clic IZQ / DER / Espacio): icono, nivel y cooldown.
extends PanelContainer

const _Theme = preload("res://scripts/ui/modern_ui_theme.gd")
const _SkillDefs = preload("res://data/skill_definitions.gd")

var slot_id: String = ""

@onready var _key_label: Label = $Margin/VBox/KeyLabel
@onready var _icon: TextureRect = $Margin/VBox/IconFrame/Icon
@onready var _level_label: Label = $Margin/VBox/IconFrame/LevelLabel
@onready var _cooldown: ProgressBar = $Margin/VBox/IconFrame/CooldownOverlay


func _ready() -> void:
	_Theme.apply_panel(self)
	custom_minimum_size = Vector2(56, 68)


func setup(p_slot_id: String) -> void:
	slot_id = p_slot_id
	_key_label.text = String(_SkillDefs.SLOT_LABELS.get(slot_id, slot_id))
	_cooldown.max_value = 1.0
	_cooldown.value = 0.0
	_cooldown.show_percentage = false
	refresh_display(0.0)


func refresh_display(cooldown_ratio: float) -> void:
	var skill_id: String = Global.get_slot_skill(slot_id)
	var level: int = Global.get_skill_level(skill_id) if not skill_id.is_empty() else 0
	if skill_id.is_empty() or level <= 0:
		_icon.texture = null
		_icon.modulate = Color(0.25, 0.28, 0.32, 0.6)
		_level_label.text = ""
	else:
		_icon.texture = _SkillDefs.get_icon_texture(skill_id)
		_icon.modulate = Color.WHITE
		_level_label.text = str(level)
	_cooldown.value = clampf(cooldown_ratio, 0.0, 1.0)
	_cooldown.visible = cooldown_ratio > 0.01
