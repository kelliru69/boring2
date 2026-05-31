## Botón de nodo del árbol: consulta estática (sin gastar puntos).
extends Button

signal skill_inspected(skill_id: String)

const _Theme = preload("res://scripts/ui/modern_ui_theme.gd")
const _SkillDefs = preload("res://data/skill_definitions.gd")

var skill_id: String = ""

@onready var _icon: TextureRect = $Margin/Content/IconFrame/Icon
@onready var _level_badge: Label = $Margin/Content/IconFrame/LevelBadge
@onready var _name_label: Label = $Margin/Content/NameLabel


func _ready() -> void:
	custom_minimum_size = Vector2(108, 124)
	toggle_mode = false
	focus_mode = Control.FOCUS_NONE
	pressed.connect(_on_pressed)
	_Theme.apply_button(self, 124.0)


func setup(p_skill_id: String) -> void:
	skill_id = p_skill_id
	var def: Dictionary = SkillTreeCatalog.get_skill(skill_id)
	_name_label.text = String(def.get("display_name", skill_id))
	var tex: Texture2D = _SkillDefs.get_icon_texture(skill_id)
	_icon.texture = tex
	refresh_state()


func refresh_state() -> void:
	var def: Dictionary = SkillTreeCatalog.get_skill(skill_id)
	if def.is_empty():
		return
	var level: int = Global.get_skill_level(skill_id)
	var max_level: int = int(def.get("max_level", SkillTreeCatalog.MAX_SKILL_LEVEL))
	_level_badge.text = "%d/%d" % [level, max_level]
	var tree_unlocked: bool = level > 0 or Global.is_skill_unlocked(Global.base_class_id, skill_id)
	if level > 0:
		modulate = Color(1.0, 1.0, 1.0, 1.0)
		tooltip_text = "%s\n%s\n(Nivel obtenido vía tómbola)" % [def.get("display_name", ""), def.get("description", "")]
	elif tree_unlocked:
		modulate = Color(0.82, 0.9, 1.0, 1.0)
		tooltip_text = "%s\n%s\nDisponible en la tómbola al subir de nivel." % [
			def.get("display_name", ""),
			def.get("description", ""),
		]
	else:
		modulate = Color(0.35, 0.38, 0.42, 0.85)
		tooltip_text = SkillTreeCatalog.get_tombola_lock_hint(skill_id)


func _on_pressed() -> void:
	if skill_id.is_empty():
		return
	skill_inspected.emit(skill_id)
