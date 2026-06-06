## Ranura del kit de combate (drop target) enlazada a LMB/RMB/Space/Q/E.
class_name CombatKitSlot
extends PanelContainer

signal skill_dropped(slot_id: String, skill_id: String)

const _SkillDefs = preload("res://data/skill_definitions.gd")
const _Theme = preload("res://scripts/ui/modern_ui_theme.gd")

const DRAG_TYPE: String = "skill_kit_drag"

var slot_id: String = ""

@onready var _binding_label: Label = $Margin/VBox/BindingLabel
@onready var _icon: TextureRect = $Margin/VBox/IconFrame/Icon
@onready var _name_label: Label = $Margin/VBox/NameLabel


func _ready() -> void:
	add_theme_stylebox_override(&"panel", _Theme.make_panel_style(_Theme.CARD_FILL, _Theme.PANEL_BORDER, 8, false))
	custom_minimum_size = Vector2(96, 108)
	mouse_filter = Control.MOUSE_FILTER_STOP


func setup(p_slot_id: String) -> void:
	slot_id = p_slot_id
	if _binding_label:
		_binding_label.text = String(SkillDefinitions.SLOT_LABELS.get(slot_id, slot_id.to_upper()))


func refresh(skill_id: String) -> void:
	var def: Dictionary = SkillTreeCatalog.get_skill(skill_id)
	if skill_id.is_empty() or def.is_empty():
		if _icon:
			_icon.texture = null
		if _name_label:
			_name_label.text = "Vacío"
		modulate = Color(0.72, 0.76, 0.82, 0.85)
		return
	modulate = Color.WHITE
	if _icon:
		_icon.texture = _SkillDefs.get_icon_texture(skill_id)
	if _name_label:
		var lvl: int = Global.get_skill_level(skill_id)
		_name_label.text = "%s\nNv.%d" % [def.get("display_name", skill_id), lvl]


func _get_drag_data(_at_position: Vector2) -> Variant:
	var skill_id: String = Global.get_kit_slot_assignment(slot_id)
	if skill_id.is_empty():
		return null
	var preview := TextureRect.new()
	preview.texture = _SkillDefs.get_icon_texture(skill_id)
	preview.custom_minimum_size = Vector2(32, 32)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_drag_preview(preview)
	return {"type": DRAG_TYPE, "skill_id": skill_id, "from_slot": slot_id}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return _is_valid_drag(data)


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not _is_valid_drag(data):
		return
	var skill_id: String = String(data.get("skill_id", ""))
	var from_slot: String = String(data.get("from_slot", ""))
	if skill_id.is_empty():
		return
	if not from_slot.is_empty() and from_slot != slot_id:
		Global.clear_kit_slot(from_slot)
	if not Global.assign_kit_slot(slot_id, skill_id):
		return
	skill_dropped.emit(slot_id, skill_id)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if Global.clear_kit_slot(slot_id):
			skill_dropped.emit(slot_id, "")


static func _is_valid_drag(data: Variant) -> bool:
	if not (data is Dictionary):
		return false
	if String(data.get("type", "")) != DRAG_TYPE:
		return false
	var skill_id: String = String(data.get("skill_id", ""))
	if skill_id.is_empty():
		return false
	if Global.get_skill_level(skill_id) <= 0:
		return false
	if Global.is_skill_disabled_for_combat(skill_id):
		return false
	return SkillTreeCatalog.is_manual_slot_skill(skill_id)
