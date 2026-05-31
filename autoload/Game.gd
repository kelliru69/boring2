## Flujo de escenas: título, hub de preparación y partida.
extends Node

signal run_started
signal run_ended(victory: bool)

const TITLE_SCENE: String = "res://scenes/menu/TitleScreen.tscn"
const PREPARATION_SCENE: String = "res://scenes/menu/PreparationHub.tscn"
const GAME_SCENE: String = "res://scenes/main/Main.tscn"

const CLASS_MAGE: String = "mage"
const CLASS_SWORDMAN: String = "swordman"

## Evoluciones de clase (Job Change) — árboles futuros.
const JOB_WIZARD: String = "wizard"
const JOB_SAGE: String = "sage"
const JOB_KNIGHT: String = "knight"
const JOB_CRUSADER: String = "crusader"

const JOB_CHANGE_MIN_LEVEL: int = 30
const JOB_CHANGE_MIN_SKILL_POINTS: int = 10

const _MapConfig = preload("res://data/map_config.gd")
const _RunBalance = preload("res://data/run_balance.gd")

var selected_class_id: String = CLASS_MAGE
var selected_map_id: String = _MapConfig.MAP_PRONTERA
var last_run_victory: bool = false
var last_run_zeny: int = 0

## Si true, Main no reinicia nivel/habilidades/XP al cargar (continuación de mapa).
var preserve_session_on_next_load: bool = false
var continued_from_map_id: String = ""


func go_to_title() -> void:
	_reset_engine_pace()
	get_tree().paused = false
	get_tree().change_scene_to_file(TITLE_SCENE)
	Audio.play_menu_bgm()


func go_to_preparation() -> void:
	_reset_engine_pace()
	get_tree().paused = false
	get_tree().change_scene_to_file(PREPARATION_SCENE)
	Audio.play_menu_bgm()


func go_to_main_menu() -> void:
	go_to_title()


func start_new_run() -> void:
	last_run_victory = false
	last_run_zeny = 0
	preserve_session_on_next_load = false
	continued_from_map_id = ""
	_apply_run_pace()
	get_tree().paused = false
	get_tree().change_scene_to_file(GAME_SCENE)
	run_started.emit()


func continue_to_next_map() -> void:
	var next_id: String = get_next_map_id(selected_map_id)
	if next_id.is_empty():
		return
	continued_from_map_id = selected_map_id
	selected_map_id = next_id
	preserve_session_on_next_load = true
	last_run_victory = false
	_apply_run_pace()
	get_tree().paused = false
	get_tree().change_scene_to_file(GAME_SCENE)
	run_started.emit()


func end_run(victory: bool, run_zeny: int) -> void:
	last_run_victory = victory
	last_run_zeny = run_zeny
	run_ended.emit(victory)


func get_next_map_id(current_map_id: String) -> String:
	if current_map_id == _MapConfig.MAP_PRONTERA:
		return _MapConfig.MAP_PAYON
	return ""


func can_continue_after_victory(current_map_id: String) -> bool:
	return not get_next_map_id(current_map_id).is_empty()


func get_continue_map_display_name(current_map_id: String) -> String:
	var next_id: String = get_next_map_id(current_map_id)
	if next_id.is_empty():
		return ""
	return String(_MapConfig.get_definition(next_id).get("display_name", next_id))


func _apply_run_pace() -> void:
	Engine.time_scale = _RunBalance.RUN_PACE_MULTIPLIER


func _reset_engine_pace() -> void:
	Engine.time_scale = 1.0
