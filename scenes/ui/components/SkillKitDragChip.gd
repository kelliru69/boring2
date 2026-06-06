## Chip arrastrable de habilidad activa (pool del kit / árbol).
class_name SkillKitDragChip
extends PanelContainer

const DRAG_TYPE: String = "skill_kit_drag"
const _SkillDefs = preload("res://data/skill_definitions.gd")
const _Theme = preload("res://scripts/ui/modern_ui_theme.gd")

var skill_id: String = ""

@onready var _icon: TextureRect = $Margin/HBox/Icon
@onready var _label: Label = $Margin/HBox/Label


func setup(p_skill_id: String) -> void:
	skill_id = p_skill_id
	var def: Dictionary = SkillTreeCatalog.get_skill(skill_id)
	if _label:
		_label.text = "%s (Nv.%d)" % [def.get("display_name", skill_id), Global.get_skill_level(skill_id)]
	if _icon:
		_icon.texture = _SkillDefs.get_icon_texture(skill_id)
	add_theme_stylebox_override(&"panel", _Theme.make_card_style(false))
	custom_minimum_size = Vector2(180, 44)
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = "Arrastra a una ranura del kit (LMB, RMB, Espacio, Q, E)"


func _get_drag_data(_at_position: Vector2) -> Variant:
	if not _can_drag():
		return null
	var preview := TextureRect.new()
	preview.texture = _SkillDefs.get_icon_texture(skill_id)
	preview.custom_minimum_size = Vector2(36, 36)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_drag_preview(preview)
	return {"type": DRAG_TYPE, "skill_id": skill_id, "from_slot": ""}


func _can_drag() -> bool:
	if skill_id.is_empty():
		return false
	if Global.get_skill_level(skill_id) <= 0:
		return false
	if Global.is_skill_disabled_for_combat(skill_id):
		return false
	return SkillTreeCatalog.is_manual_slot_skill(skill_id)
