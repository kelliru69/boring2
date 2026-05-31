## GameHUD.gd — UI reactiva conectada a señales de Global y del jugador.
extends CanvasLayer

@onready var level_label: Label = $MarginContainer/VBox/LevelLabel
@onready var xp_label: Label = $MarginContainer/VBox/XpLabel
@onready var zeny_label: Label = $MarginContainer/VBox/ZenyLabel
@onready var time_label: Label = $MarginContainer/VBox/TimeLabel
@onready var cards_label: Label = $MarginContainer/VBox/CardsLabel
@onready var hp_label: Label = $MarginContainer/VBox/HpLabel
@onready var wave_label: Label = $MarginContainer/VBox/WaveLabel
@onready var xp_progress_bar: ProgressBar = $XpBarDock/XpBarMargin/HBox/XpProgressBar
@onready var xp_bar_level_badge: Label = $XpBarDock/XpBarMargin/HBox/LevelBadge
@onready var xp_fraction_label: Label = $XpBarDock/XpBarMargin/HBox/XpFractionLabel
@onready var skill_action_bar: HBoxContainer = $SkillBarDock/SkillActionBar
@onready var passive_skill_strip: HBoxContainer = $PassiveSkillDock/PassiveSkillStrip


var _wave_banner_text: String = ""
var _wave_banner_timer: float = 0.0


func _ready() -> void:
	Global.level_up.connect(_on_level_up)
	Global.zeny_gained.connect(_on_zeny_gained)
	Global.card_collected.connect(_on_card_collected)
	if not Arena.wave_announced.is_connected(_on_wave_announced):
		Arena.wave_announced.connect(_on_wave_announced)
	_refresh_global_ui()
	_find_player_health()


func _on_wave_announced(message: String) -> void:
	_wave_banner_text = message
	_wave_banner_timer = 4.5


func _process(delta: float) -> void:
	_update_time()
	_refresh_xp()
	if _wave_banner_timer > 0.0:
		_wave_banner_timer = maxf(_wave_banner_timer - delta, 0.0)
	_update_wave_info()


func _find_player_health() -> void:
	var players: Array[Node] = get_tree().get_nodes_in_group("Jugador")
	if players.is_empty():
		return
	var player: Player = players[0] as Player
	if player == null:
		return
	player.health_changed.connect(_on_health_changed)
	_on_health_changed(player.current_hp, player.max_hp)
	if player.active_skills and skill_action_bar and skill_action_bar.has_method("bind_controller"):
		skill_action_bar.bind_controller(player.active_skills)
	if passive_skill_strip and passive_skill_strip.has_method("_refresh"):
		passive_skill_strip._refresh()


func _on_health_changed(current_hp: int, max_hp: int) -> void:
	hp_label.text = "HP: %d / %d" % [current_hp, max_hp]


func _on_level_up(new_level: int) -> void:
	level_label.text = "Nivel: %d" % new_level
	if xp_bar_level_badge:
		xp_bar_level_badge.text = "Nv.%d" % new_level
	_refresh_xp()


func _on_zeny_gained(_amount: int, total: int) -> void:
	zeny_label.text = "Zeny: %d" % total


func _on_card_collected(card_id: String, _data: Dictionary) -> void:
	cards_label.text = "Cartas: %d (%s)" % [Global.unlocked_cards.size(), card_id]


func _refresh_global_ui() -> void:
	level_label.text = "Nivel: %d" % Global.session_level
	if xp_bar_level_badge:
		xp_bar_level_badge.text = "Nv.%d" % Global.session_level
	zeny_label.text = "Zeny: %d" % Global.total_zeny
	cards_label.text = "Cartas: %d" % Global.unlocked_cards.size()
	_refresh_xp()


func _refresh_xp() -> void:
	var current: int = Global.session_xp
	var required: int = maxi(Global.session_xp_required, 1)
	xp_label.text = "XP: %d / %d" % [current, required]
	if xp_progress_bar:
		xp_progress_bar.max_value = float(required)
		xp_progress_bar.value = float(current)
	if xp_fraction_label:
		xp_fraction_label.text = "%d / %d" % [current, required]


func _update_time() -> void:
	var t: float = Global.session_elapsed_time
	var seconds_total: int = int(t)
	var minutes: int = int(seconds_total / 60.0)
	var seconds: int = seconds_total % 60
	time_label.text = "Tiempo: %02d:%02d" % [minutes, seconds]


func _update_wave_info() -> void:
	if wave_label == null:
		return
	if _wave_banner_timer > 0.0 and not _wave_banner_text.is_empty():
		wave_label.text = _wave_banner_text
		return
	var step: int = int(Global.session_elapsed_time / 30.0)
	var enemies_alive: int = get_tree().get_nodes_in_group("Enemigos").size()
	wave_label.text = "Oleada %d | Enemigos: %d" % [step + 1, enemies_alive]
