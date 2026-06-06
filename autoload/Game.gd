## Flujo de escenas: título, hub de preparación y partida.
extends Node

signal run_started
signal run_ended(victory: bool)

const TITLE_SCENE: String = "res://scenes/menu/TitleScreen.tscn"
const CHARACTER_SELECTION_SCENE: String = "res://scenes/menu/CharacterSelect.tscn"
const CLASS_SELECTION_SCENE: String = "res://scenes/menu/ClassSelect.tscn"
## Legacy (skin picker + clase en una sola pantalla).
const LEGACY_CHARACTER_SELECTION_SCENE: String = "res://scenes/menu/CharacterSelection.tscn"
const PREPARATION_SCENE: String = "res://scenes/menu/PreparationHub.tscn"
const MAP_SELECTION_SCENE: String = "res://scenes/menu/MapSelection.tscn"
const GAME_SCENE: String = "res://scenes/main/Main.tscn"

const CLASS_MAGE: String = "mage"
const CLASS_SWORDMAN: String = "swordman"
const CLASS_THIEF: String = "thief"
const CLASS_ARCHER: String = "archer"

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
var selected_player_skin_id: String = "blue_cat"
var selected_map_id: String = _MapConfig.MAP_PRONTERA
var last_run_victory: bool = false
var last_run_zeny: int = 0

## Si true, Main no reinicia nivel/habilidades/XP al cargar (continuación de mapa).
var preserve_session_on_next_load: bool = false
var continued_from_map_id: String = ""
## Tras vencer el jefe del mapa 1: PreparationHub con álbum antes del mapa 2.
var intermap_preparation_mode: bool = false


func go_to_title() -> void:
	_reset_engine_pace()
	RoCursor.apply_game_cursor()
	get_tree().paused = false
	get_tree().change_scene_to_file(TITLE_SCENE)
	Audio.play_menu_bgm()


func go_to_character_selection() -> void:
	_reset_engine_pace()
	RoCursor.apply_game_cursor()
	get_tree().paused = false
	get_tree().change_scene_to_file(CHARACTER_SELECTION_SCENE)
	Audio.play_menu_bgm()


func go_to_class_selection() -> void:
	_reset_engine_pace()
	RoCursor.apply_game_cursor()
	get_tree().paused = false
	get_tree().change_scene_to_file(CLASS_SELECTION_SCENE)
	Audio.play_menu_bgm()


func go_to_preparation() -> void:
	_reset_engine_pace()
	RoCursor.apply_game_cursor()
	get_tree().paused = false
	get_tree().change_scene_to_file(PREPARATION_SCENE)
	Audio.play_menu_bgm()


## Pantalla de preparación tras Mapa 1: equipar cartas dropeadas antes de Payon.
func go_to_post_boss_preparation() -> void:
	intermap_preparation_mode = true
	go_to_preparation()


func go_to_map_selection() -> void:
	_reset_engine_pace()
	RoCursor.apply_game_cursor()
	get_tree().paused = false
	get_tree().change_scene_to_file(MAP_SELECTION_SCENE)
	Audio.play_menu_bgm()


func go_to_main_menu() -> void:
	go_to_title()


## Abandona la run actual sin pantalla de resultados; vuelve al título.
func abandon_run_to_title() -> void:
	get_tree().paused = false
	_reset_engine_pace()
	Audio.stop_bgm()
	Global.reset_session()
	end_run(false, Global.run_zeny)
	go_to_title()


func start_new_run() -> void:
	last_run_victory = false
	last_run_zeny = 0
	preserve_session_on_next_load = false
	continued_from_map_id = ""
	_apply_run_pace()
	RoCursor.apply_game_cursor()
	get_tree().paused = false
	get_tree().change_scene_to_file(GAME_SCENE)
	run_started.emit()


func continue_to_next_map() -> void:
	var next_id: String = get_next_map_id(selected_map_id)
	if next_id.is_empty():
		return
	continued_from_map_id = selected_map_id
	selected_map_id = next_id
	# Reinicia el tiempo de run para que las oleadas del mapa siguiente partan desde cero.
	Global.session_elapsed_time = 0.0
	preserve_session_on_next_load = true
	last_run_victory = false
	_apply_run_pace()
	RoCursor.apply_game_cursor()
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
	if current_map_id == _MapConfig.MAP_PAYON:
		return _MapConfig.MAP_ORC_VILLAGE
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
