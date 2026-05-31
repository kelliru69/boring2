## Sub-menú: clase, selector de etapas y lanzar run.
extends Control

const _Theme = preload("res://scripts/ui/modern_ui_theme.gd")
const _StageCardScene: PackedScene = preload("res://scenes/ui/components/StageSelectCard.tscn")

const STAGES: Array[Dictionary] = [
	{
		"id": "prontera_fields",
		"name": "Prontera Fields",
		"difficulty": "Dificultad: Normal",
		"desc": "Praderas abiertas. Ideal para farmear Zeny y desbloquear mejoras.",
		"tint": Color(0.12, 0.28, 0.18, 0.85),
	},
	{
		"id": "payon_dungeon",
		"name": "Payon Dungeon",
		"difficulty": "Dificultad: Alta",
		"desc": "Bosque denso y cuevas. Enemigos más duros, mayor recompensa.",
		"tint": Color(0.08, 0.18, 0.14, 0.9),
	},
]

@onready var summary_panel: PanelContainer = $Margin/VBox/SummaryPanel
@onready var summary_label: Label = $Margin/VBox/SummaryPanel/SummaryMargin/SummaryLabel
@onready var stage_grid: HBoxContainer = $Margin/VBox/StageGrid
@onready var mage_button: Button = $Margin/VBox/ClassRow/MageButton
@onready var sword_button: Button = $Margin/VBox/ClassRow/SwordButton
@onready var launch_button: Button = $Margin/VBox/LaunchButton

var _selected_map_id: String = "prontera_fields"
var _selected_class_id: String = Game.CLASS_MAGE
var _stage_cards: Dictionary = {}


func _ready() -> void:
	visible = false
	_Theme.apply_panel(summary_panel)
	_Theme.style_title($Margin/VBox/TitleLabel, 24)
	_Theme.style_body($Margin/VBox/ClassLabel, 14)
	_Theme.style_body($Margin/VBox/StageLabel, 14)
	_Theme.style_body(summary_label, 13)
	for btn: Button in [mage_button, sword_button, launch_button]:
		_Theme.apply_button(btn, 44.0)
	mage_button.pressed.connect(_select_mage)
	sword_button.pressed.connect(_select_swordman)
	launch_button.pressed.connect(_on_launch_pressed)
	_build_stage_cards()
	_selected_class_id = Game.CLASS_MAGE
	_update_class_buttons()
	_select_map(_selected_map_id)


func show_panel() -> void:
	visible = true
	_update_summary()


func hide_panel() -> void:
	visible = false


func _build_stage_cards() -> void:
	for child: Node in stage_grid.get_children():
		child.queue_free()
	_stage_cards.clear()
	for stage: Dictionary in STAGES:
		var card: PanelContainer = _StageCardScene.instantiate() as PanelContainer
		stage_grid.add_child(card)
		var map_id: String = String(stage.get("id", ""))
		_stage_cards[map_id] = card
		if card.has_method("setup"):
			card.setup(
				map_id,
				String(stage.get("name", map_id)),
				String(stage.get("difficulty", "")),
				String(stage.get("desc", "")),
				stage.get("tint", Color(0.1, 0.15, 0.2, 0.8)) as Color
			)
		if card.has_signal("stage_selected"):
			card.stage_selected.connect(_select_map)


func _select_mage() -> void:
	Audio.play_ui_click()
	_selected_class_id = Game.CLASS_MAGE
	_update_class_buttons()
	_update_summary()


func _select_swordman() -> void:
	Audio.play_ui_click()
	_selected_class_id = Game.CLASS_SWORDMAN
	_update_class_buttons()
	_update_summary()


func _select_map(map_id: String) -> void:
	_selected_map_id = map_id
	for id: String in _stage_cards:
		var card: Node = _stage_cards[id]
		if card.has_method("set_selected"):
			card.set_selected(id == map_id)
	_update_summary()


func _update_class_buttons() -> void:
	mage_button.disabled = _selected_class_id == Game.CLASS_MAGE
	sword_button.disabled = _selected_class_id == Game.CLASS_SWORDMAN


func _update_summary() -> void:
	var map_name: String = _selected_map_id
	for stage: Dictionary in STAGES:
		if String(stage.get("id", "")) == _selected_map_id:
			map_name = String(stage.get("name", _selected_map_id))
			break
	var selected_class: String = "Mage" if _selected_class_id == Game.CLASS_MAGE else "Swordman"
	summary_label.text = "Clase: %s  ·  Mapa: %s\nCartas equipadas: %d  ·  Zeny: %d" % [
		selected_class,
		map_name,
		Global.get_equipped_cards_clean().size(),
		Global.total_zeny,
	]
	Game.selected_class_id = _selected_class_id
	Game.selected_map_id = _selected_map_id


func _on_launch_pressed() -> void:
	Audio.play_ui_click()
	_update_summary()
	Game.start_new_run()
