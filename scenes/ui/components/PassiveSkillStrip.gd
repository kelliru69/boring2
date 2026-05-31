## Fila de íconos para habilidades automáticas / pasivas (sin botón asignado).
extends HBoxContainer

const _SkillDefs = preload("res://data/skill_definitions.gd")
const _Theme = preload("res://scripts/ui/modern_ui_theme.gd")

var _icons: Dictionary = {}


func _ready() -> void:
	add_theme_constant_override("separation", 4)
	if not Global.skill_tree_changed.is_connected(_refresh):
		Global.skill_tree_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for child: Node in get_children():
		child.queue_free()
	_icons.clear()
	var class_id: String = Global.base_class_id
	if class_id.is_empty():
		class_id = Game.selected_class_id
	for skill_id: String in SkillTreeCatalog.get_background_skills_for_class(class_id):
		if Global.get_skill_level(skill_id) <= 0:
			continue
		var chip: PanelContainer = _make_chip(skill_id)
		add_child(chip)
		_icons[skill_id] = chip


func _make_chip(skill_id: String) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(36, 40)
	_Theme.apply_panel(panel)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 2)
	margin.add_theme_constant_override("margin_top", 2)
	margin.add_theme_constant_override("margin_right", 2)
	margin.add_theme_constant_override("margin_bottom", 2)
	panel.add_child(margin)
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	margin.add_child(vbox)
	var icon_frame: Control = Control.new()
	icon_frame.custom_minimum_size = Vector2(24, 24)
	vbox.add_child(icon_frame)
	var icon: TextureRect = TextureRect.new()
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _SkillDefs.get_icon_texture(skill_id)
	icon_frame.add_child(icon)
	var level_label: Label = Label.new()
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 9)
	level_label.text = str(Global.get_skill_level(skill_id))
	vbox.add_child(level_label)
	var def: Dictionary = SkillTreeCatalog.get_skill(skill_id)
	panel.tooltip_text = "%s\nNv.%d — %s" % [
		def.get("display_name", skill_id),
		Global.get_skill_level(skill_id),
		def.get("description", ""),
	]
	return panel
