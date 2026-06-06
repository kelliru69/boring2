## Panel derecho del HUD: habilidades/pasivas de la run + cartas dropeadas (sin duplicar iconos).
extends VBoxContainer

const _SkillDefs = preload("res://data/skill_definitions.gd")
const _RunStats = preload("res://data/run_stat_catalog.gd")
const _CardVisuals = preload("res://data/card_visual_catalog.gd")
const _ChipScene: PackedScene = preload("res://scenes/ui/components/RoStatusChip.tscn")
const _Theme = preload("res://scripts/ui/modern_ui_theme.gd")

@onready var skills_title: Label = $SkillsTitle
@onready var skills_grid: GridContainer = $SkillsGrid
@onready var cards_title: Label = $CardsTitle
@onready var cards_grid: GridContainer = $CardsGrid


func _ready() -> void:
	add_theme_constant_override("separation", 6)
	if skills_title:
		_Theme.style_subtitle(skills_title, 11)
		skills_title.text = "Habilidades"
	if cards_title:
		_Theme.style_subtitle(cards_title, 11)
		cards_title.text = "Cartas (run)"
	if skills_grid:
		skills_grid.columns = 4
		skills_grid.add_theme_constant_override("h_separation", 4)
		skills_grid.add_theme_constant_override("v_separation", 4)
	if cards_grid:
		cards_grid.columns = 4
		cards_grid.add_theme_constant_override("h_separation", 4)
		cards_grid.add_theme_constant_override("v_separation", 4)
	if not Global.skill_tree_changed.is_connected(refresh):
		Global.skill_tree_changed.connect(refresh)
	if not Global.level_up.is_connected(refresh):
		Global.level_up.connect(refresh)
	if not Global.run_cards_changed.is_connected(refresh):
		Global.run_cards_changed.connect(refresh)
	refresh()


func refresh(_new_level: int = -1) -> void:
	_rebuild_skills()
	_rebuild_run_cards()


func _rebuild_skills() -> void:
	if skills_grid == null:
		return
	for child: Node in skills_grid.get_children():
		child.queue_free()
	var class_id: String = Global.current_class if not Global.current_class.is_empty() else Global.base_class_id
	if class_id.is_empty():
		class_id = Game.selected_class_id
	var added: Dictionary = {}
	for skill_id: String in SkillTreeCatalog.get_skills_for_class(class_id):
		var lv: int = Global.get_skill_level(skill_id)
		if lv <= 0:
			continue
		if added.has(skill_id):
			continue
		added[skill_id] = true
		var def: Dictionary = SkillTreeCatalog.get_skill(skill_id)
		var chip: RoStatusChip = _ChipScene.instantiate() as RoStatusChip
		skills_grid.add_child(chip)
		chip.setup(
			_SkillDefs.get_icon_texture(skill_id),
			lv,
			0,
			"%s\nNv.%d — %s" % [def.get("display_name", skill_id), lv, def.get("description", "")]
		)
	for stat_id: String in _RunStats.ALL_STAT_IDS:
		var stat_lv: int = Global.get_run_stat_level(stat_id)
		if stat_lv <= 0:
			continue
		var stat_def: Dictionary = _RunStats.get_definition(stat_id)
		var chip_stat: RoStatusChip = _ChipScene.instantiate() as RoStatusChip
		skills_grid.add_child(chip_stat)
		chip_stat.setup(null, stat_lv, 0, String(stat_def.get("title", stat_id)))


func _rebuild_run_cards() -> void:
	if cards_grid == null:
		return
	for child: Node in cards_grid.get_children():
		child.queue_free()
	var drops: Dictionary = Global.get_run_card_drops()
	if drops.is_empty():
		if cards_title:
			cards_title.visible = false
		return
	if cards_title:
		cards_title.visible = true
	var ids: Array = drops.keys()
	ids.sort()
	for raw_id: Variant in ids:
		var card_id: String = String(raw_id)
		var count: int = int(drops[card_id])
		if count <= 0:
			continue
		var chip: RoStatusChip = _ChipScene.instantiate() as RoStatusChip
		cards_grid.add_child(chip)
		chip.setup(_CardVisuals.load_texture(card_id), 0, count, "Carta obtenida esta run: %s x%d" % [card_id, count])
