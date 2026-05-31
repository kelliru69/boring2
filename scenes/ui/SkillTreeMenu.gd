## Panel del árbol de habilidades (solo consulta; progreso vía tómbola).
extends Control

const _Theme = preload("res://scripts/ui/modern_ui_theme.gd")
const _NodeScene: PackedScene = preload("res://scenes/ui/components/SkillTreeNodeButton.tscn")

@onready var points_label: Label = $VBox/Header/PointsLabel
@onready var class_label: Label = $VBox/Header/ClassLabel
@onready var job_hint: Label = $VBox/JobHint
@onready var tree_grid: GridContainer = $VBox/TreeScroll/TreeGrid
@onready var detail_label: Label = $VBox/DetailLabel


func _ready() -> void:
	visible = true
	_Theme.style_title(class_label, 16)
	_Theme.style_accent(points_label, 13)
	_Theme.style_subtitle(job_hint, 11)
	_Theme.style_body(detail_label, 12)
	if not Global.skill_tree_changed.is_connected(_refresh):
		Global.skill_tree_changed.connect(_refresh)
	if not Global.job_change_ready.is_connected(_on_job_change_ready):
		Global.job_change_ready.connect(_on_job_change_ready)
	_refresh()


func _refresh() -> void:
	var tree_class: String = Global.base_class_id
	if tree_class.is_empty():
		tree_class = Game.selected_class_id
	class_label.text = "Clase: %s" % Global.current_class.capitalize()
	points_label.text = "Mejoras de habilidad: %d" % Global.tombola_skill_upgrades_this_run
	_rebuild_grid(tree_class)
	_update_job_hint()
	detail_label.text = "Sube de nivel para elegir mejoras en la tómbola. Toca un nodo para ver requisitos."


func _rebuild_grid(class_id: String) -> void:
	for child: Node in tree_grid.get_children():
		child.queue_free()
	var grid_size: Vector2i = SkillTreeCatalog.get_grid_size(class_id)
	tree_grid.columns = maxi(grid_size.x, 1)
	var skill_ids: Array[String] = SkillTreeCatalog.get_skills_for_class(class_id)
	var cell_map: Dictionary = {}
	for skill_id: String in skill_ids:
		var def: Dictionary = SkillTreeCatalog.get_skill(skill_id)
		var key: Vector2i = Vector2i(int(def.get("grid_col", 0)), int(def.get("grid_row", 0)))
		cell_map[key] = skill_id
	for row: int in grid_size.y:
		for col: int in grid_size.x:
			var key: Vector2i = Vector2i(col, row)
			if cell_map.has(key):
				var node: Button = _NodeScene.instantiate() as Button
				tree_grid.add_child(node)
				if node.has_method("setup"):
					node.setup(String(cell_map[key]))
				if node.has_signal("skill_inspected"):
					node.skill_inspected.connect(_on_skill_inspected)
			else:
				var spacer: Control = Control.new()
				spacer.custom_minimum_size = Vector2(108, 124)
				tree_grid.add_child(spacer)


func _on_skill_inspected(skill_id: String) -> void:
	var def: Dictionary = SkillTreeCatalog.get_skill(skill_id)
	if def.is_empty():
		return
	var level: int = Global.get_skill_level(skill_id)
	if level > 0:
		detail_label.text = "%s — Nv.%d/%d\n%s" % [
			def.get("display_name", skill_id),
			level,
			int(def.get("max_level", SkillTreeCatalog.MAX_SKILL_LEVEL)),
			def.get("description", ""),
		]
	elif Global.is_skill_unlocked(Global.base_class_id, skill_id):
		detail_label.text = "%s\n%s\nPuede aparecer en tu próxima tómbola." % [
			def.get("display_name", skill_id),
			def.get("description", ""),
		]
	else:
		detail_label.text = SkillTreeCatalog.get_tombola_lock_hint(skill_id)


func _on_job_change_ready(_job_id: String) -> void:
	_update_job_hint()


func _update_job_hint() -> void:
	if Global.can_trigger_job_change():
		var jobs: Array[String] = Global.get_available_job_evolutions()
		job_hint.text = "Job Change disponible: %s" % ", ".join(jobs)
		job_hint.visible = true
	else:
		job_hint.text = "Job Change: nv.%d + %d mejoras de habilidad en la run" % [
			Game.JOB_CHANGE_MIN_LEVEL,
			Game.JOB_CHANGE_MIN_SKILL_POINTS,
		]
		job_hint.visible = true
